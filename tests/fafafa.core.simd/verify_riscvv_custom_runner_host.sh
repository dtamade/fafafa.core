#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${ROOT}/../.." && pwd)"
WORKFLOW_FILE="${REPO_ROOT}/.github/workflows/simd-riscvv-native-evidence.yml"
DEFAULT_SNAPSHOT_URL="https://downloads.freepascal.org/fpc/snapshot/trunk/riscv64-linux/fpc-3.3.1.riscv64-linux.tar.gz"
GITHUB_URL="${SIMD_RISCVV_RUNNER_GITHUB_URL:-https://github.com}"
GITHUB_API_URL="${SIMD_RISCVV_RUNNER_GITHUB_API_URL:-https://api.github.com}"

print_usage() {
  cat <<EOF
Usage: $0

Fail-close host preflight for the RISCVV native-evidence workflow.

Checks:
  - host is Linux and uname -m resolves to riscv64
  - required commands exist: bash, sudo, curl, tar, git
  - sudo works non-interactively
  - network reachability to GitHub and the FPC RISCV64 snapshot URL

Environment:
  SIMD_RISCVV_RUNNER_FPC_SNAPSHOT_URL   Override snapshot URL
  SIMD_RISCVV_RUNNER_GITHUB_URL         Override GitHub web endpoint
  SIMD_RISCVV_RUNNER_GITHUB_API_URL     Override GitHub API endpoint
EOF
}

fail_with() {
  local aExitCode
  local aMessage

  aExitCode="${1:-1}"
  aMessage="${2:-unknown error}"
  echo "[RISCVV-HOST] STATUS=FAIL CODE=${aExitCode} MESSAGE=${aMessage}" >&2
  exit "${aExitCode}"
}

require_cmd() {
  local aCmd

  aCmd="${1:-}"
  if ! command -v "${aCmd}" >/dev/null 2>&1; then
    fail_with 20 "missing command: ${aCmd}"
  fi
}

normalize_arch() {
  local LArch

  LArch="$(uname -m 2>/dev/null || echo unknown)"
  case "${LArch}" in
    aarch64|arm64)
      echo "arm64"
      ;;
    riscv64)
      echo "riscv64"
      ;;
    *)
      echo "${LArch}"
      ;;
  esac
}

resolve_snapshot_url() {
  local LUrl

  if [[ -n "${SIMD_RISCVV_RUNNER_FPC_SNAPSHOT_URL:-}" ]]; then
    printf '%s\n' "${SIMD_RISCVV_RUNNER_FPC_SNAPSHOT_URL}"
    return 0
  fi

  if [[ -f "${WORKFLOW_FILE}" ]]; then
    LUrl="$(sed -n 's/^  FPC_RISCV64_SNAPSHOT_URL:[[:space:]]*//p' "${WORKFLOW_FILE}" | head -n 1)"
    if [[ -n "${LUrl}" ]]; then
      printf '%s\n' "${LUrl}"
      return 0
    fi
  fi

  printf '%s\n' "${DEFAULT_SNAPSHOT_URL}"
}

check_url() {
  local aUrl
  local aLabel

  aUrl="${1:-}"
  aLabel="${2:-url}"
  if [[ -z "${aUrl}" ]]; then
    fail_with 24 "empty URL for ${aLabel}"
  fi

  if curl -fsSIL --retry 2 --retry-delay 2 --connect-timeout 10 --max-time 30 "${aUrl}" >/dev/null; then
    echo "[RISCVV-HOST] PASS ${aLabel}: ${aUrl}"
    return 0
  fi

  fail_with 23 "network probe failed for ${aLabel}: ${aUrl}"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      print_usage
      exit 0
      ;;
    *)
      fail_with 24 "unsupported argument: $1"
      ;;
  esac
done

LOs="$(uname -s 2>/dev/null || echo unknown)"
LRawArch="$(uname -m 2>/dev/null || echo unknown)"
LArch="$(normalize_arch)"
LSnapshotUrl="$(resolve_snapshot_url)"

echo "[RISCVV-HOST] workflow=${WORKFLOW_FILE}"
echo "[RISCVV-HOST] os=${LOs}"
echo "[RISCVV-HOST] raw_arch=${LRawArch}"
echo "[RISCVV-HOST] normalized_arch=${LArch}"
echo "[RISCVV-HOST] snapshot_url=${LSnapshotUrl}"

if [[ "${LOs}" != "Linux" ]]; then
  fail_with 21 "expected Linux host; got ${LOs}"
fi

if [[ "${LArch}" != "riscv64" ]]; then
  fail_with 21 "real riscv64 host required; got ${LRawArch} (normalized=${LArch})"
fi

for LCmd in bash sudo curl tar git; do
  require_cmd "${LCmd}"
  echo "[RISCVV-HOST] PASS command: ${LCmd} -> $(command -v "${LCmd}")"
done

if ! sudo -n true >/dev/null 2>&1; then
  fail_with 22 "sudo -n true failed; the runner user needs non-interactive sudo for workflow install steps"
fi
echo "[RISCVV-HOST] PASS sudo-noninteractive"

check_url "${GITHUB_URL}" "github-web"
check_url "${GITHUB_API_URL}" "github-api"
check_url "${LSnapshotUrl}" "fpc-riscv64-snapshot"

echo "[RISCVV-HOST] STATUS=PASS CODE=OK EXIT=0"
echo "[RISCVV-HOST] next_step=register/start a repo-visible self-hosted,Linux,riscv64 runner on this host"
