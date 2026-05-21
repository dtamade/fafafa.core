#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${ROOT}/../.." && pwd)"
FIXED_LABELS="self-hosted,Linux,riscv64"
REPO_SLUG="${SIMD_RISCVV_RUNNER_REPO:-}"
TOKEN_FILE="${SIMD_RISCVV_RUNNER_TOKEN_FILE:-}"

print_usage() {
  cat <<EOF
Usage: $0 [--repo <owner/name>] [--token-file <external-path>]

Fetch a GitHub Actions self-hosted runner registration token for the current
repo, locked to the RISCVV closeout label set:
  ${FIXED_LABELS}

Environment:
  SIMD_RISCVV_RUNNER_REPO        Override repo slug (default: current checkout)
  SIMD_RISCVV_RUNNER_TOKEN_FILE  Optional external path used to persist the token

Notes:
  - Token files must live outside the repo worktree.
  - This helper does not install or start a runner.
  - Repo-ops must still provide a working runner solution on a real riscv64
    host before fresh RISCVV native evidence can run.
EOF
}

fail_with() {
  local aExitCode
  local aMessage

  aExitCode="${1:-1}"
  aMessage="${2:-unknown error}"
  echo "[RUNNER-REG] FAILED: ${aMessage}" >&2
  exit "${aExitCode}"
}

require_cmd() {
  local aCmd

  aCmd="${1:-}"
  if ! command -v "${aCmd}" >/dev/null 2>&1; then
    fail_with 20 "missing command: ${aCmd}"
  fi
}

extract_repo_slug_from_url() {
  local aUrl

  aUrl="${1:-}"
  python3 - "${aUrl}" <<'PY'
import sys
from urllib.parse import urlparse

url = sys.argv[1].strip()
if not url:
    sys.exit(0)

if url.startswith("git@github.com:"):
    url = "https://github.com/" + url.split(":", 1)[1]

parts = [segment for segment in urlparse(url).path.split("/") if segment]
if len(parts) >= 2:
    owner = parts[0]
    repo = parts[1]
    if repo.endswith(".git"):
        repo = repo[:-4]
    print(f"{owner}/{repo}")
PY
}

resolve_repo_slug() {
  local LRepoJson
  local LRemoteUrl
  local LRepo

  if [[ -n "${REPO_SLUG}" ]]; then
    printf '%s\n' "${REPO_SLUG}"
    return 0
  fi

  LRepoJson="$(gh repo view --json nameWithOwner 2>/dev/null || true)"
  if [[ -n "${LRepoJson}" ]]; then
    LRepo="$(python3 - "${LRepoJson}" <<'PY'
import json
import sys

raw = sys.argv[1].strip()
if not raw:
    sys.exit(0)

obj = json.loads(raw)
name = str(obj.get("nameWithOwner", "") or "").strip()
if name:
    print(name)
PY
)"
    if [[ -n "${LRepo}" ]]; then
      printf '%s\n' "${LRepo}"
      return 0
    fi
  fi

  LRemoteUrl="$(git -C "${REPO_ROOT}" remote get-url origin 2>/dev/null || true)"
  if [[ -n "${LRemoteUrl}" ]]; then
    LRepo="$(extract_repo_slug_from_url "${LRemoteUrl}")"
    if [[ -n "${LRepo}" ]]; then
      printf '%s\n' "${LRepo}"
      return 0
    fi
  fi

  return 1
}

resolve_external_token_path() {
  local aPath

  aPath="${1:-}"
  python3 - "${aPath}" "${REPO_ROOT}" <<'PY'
from pathlib import Path
import sys

raw = sys.argv[1].strip()
repo_root = Path(sys.argv[2]).resolve()
if not raw:
    sys.exit(2)

candidate = Path(raw).expanduser()
if not candidate.is_absolute():
    candidate = Path.cwd() / candidate
resolved = candidate.resolve(strict=False)

try:
    resolved.relative_to(repo_root)
except ValueError:
    print(str(resolved))
    sys.exit(0)

sys.exit(1)
PY
}

mask_token() {
  local aToken
  local LLen

  aToken="${1:-}"
  LLen="${#aToken}"
  if (( LLen <= 8 )); then
    printf '<redacted>\n'
    return 0
  fi

  printf '%s...%s\n' "${aToken:0:4}" "${aToken: -4}"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      print_usage
      exit 0
      ;;
    --repo)
      if [[ $# -lt 2 ]]; then
        fail_with 24 "missing value for --repo"
      fi
      REPO_SLUG="$2"
      shift 2
      ;;
    --token-file)
      if [[ $# -lt 2 ]]; then
        fail_with 24 "missing value for --token-file"
      fi
      TOKEN_FILE="$2"
      shift 2
      ;;
    *)
      fail_with 24 "unsupported argument: $1"
      ;;
  esac
done

for LCmd in gh python3 git; do
  require_cmd "${LCmd}"
done

if ! gh auth status >/dev/null 2>&1; then
  fail_with 21 "gh auth required"
fi

LRepo="$(resolve_repo_slug || true)"
if [[ -z "${LRepo}" ]]; then
  fail_with 22 "failed to resolve repo slug"
fi

set +e
LResponse="$(gh api "repos/${LRepo}/actions/runners/registration-token" -X POST 2>&1)"
LRC=$?
set -e
if [[ "${LRC}" != "0" ]]; then
  printf '%s\n' "${LResponse}" >&2
  fail_with 23 "failed to fetch registration token for ${LRepo}"
fi

read -r LToken LExpiresAt < <(
  python3 - "${LResponse}" <<'PY'
import json
import sys

obj = json.loads(sys.argv[1])
token = str(obj.get("token", "") or "").strip()
expires_at = str(obj.get("expires_at", "") or "").strip()
print(f"{token} {expires_at}")
PY
)

if [[ -z "${LToken}" ]]; then
  fail_with 23 "registration-token response did not include a token"
fi

if [[ -n "${TOKEN_FILE}" ]]; then
  LTokenPath="$(resolve_external_token_path "${TOKEN_FILE}" || true)"
  if [[ -z "${LTokenPath}" ]]; then
    fail_with 24 "token file must resolve outside the repo worktree: ${TOKEN_FILE}"
  fi
  mkdir -p "$(dirname "${LTokenPath}")"
  umask 077
  printf '%s' "${LToken}" > "${LTokenPath}"
  TOKEN_FILE="${LTokenPath}"
fi

echo "[RUNNER-REG] repo=${LRepo}"
echo "[RUNNER-REG] registration_url=https://github.com/${LRepo}"
echo "[RUNNER-REG] labels=${FIXED_LABELS}"
echo "[RUNNER-REG] token=$(mask_token "${LToken}")"
echo "[RUNNER-REG] expires_at=${LExpiresAt:-unknown}"
if [[ -n "${TOKEN_FILE}" ]]; then
  echo "[RUNNER-REG] token_file=${TOKEN_FILE}"
else
  echo "[RUNNER-REG] token_file=<not persisted; set SIMD_RISCVV_RUNNER_TOKEN_FILE or --token-file to store it outside the repo>"
fi
echo "[RUNNER-REG] next_step=run a real riscv64 host preflight via BuildOrTest.sh riscvv-runner-host-preflight"
echo "[RUNNER-REG] note=repo-ops still needs a working runner solution on a real riscv64 host before fresh RISCVV native evidence can run"
