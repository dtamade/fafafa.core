#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${ROOT}/../.." && pwd)"
BACKEND="${1:-}"
RUN_ID_INPUT="${2:-}"

print_usage() {
  cat <<EOF
Usage: $0 <backend> [run-id]

Backends:
  neon    Dispatch/download ARM64 NEON native evidence workflow
  riscvv  Dispatch/download RISCVV native evidence workflow

Default run-id: create a temporary clean worktree pinned to the pushed ref, then
delegate to native-evidence-via-gh.

Explicit run-id: forward directly to native-evidence-via-gh (no temporary
worktree needed).

Notes:
  - This helper is a dirty-worktree escape hatch for local closeout state.
  - It still fail-closes if the selected ref is not pushed or does not match
    local HEAD.
  - Downloaded artifacts are written back to the current worktree's logs root.
EOF
}

if [[ -z "${BACKEND}" || "${BACKEND}" == "-h" || "${BACKEND}" == "--help" ]]; then
  print_usage
  exit 0
fi

require_cmd() {
  local aCmd

  aCmd="${1:-}"
  if ! command -v "${aCmd}" >/dev/null 2>&1; then
    echo "[NATIVE-EVIDENCE-GH-CLEAN] Missing command: ${aCmd}"
    exit 2
  fi
}

looks_like_full_sha() {
  local aValue

  aValue="${1:-}"
  [[ "${aValue}" =~ ^[0-9a-fA-F]{40}$ ]]
}

cleanup_temp_worktree() {
  local aWorktree
  local aRoot

  aWorktree="${1:-}"
  aRoot="${2:-}"

  if [[ -n "${aWorktree}" && -d "${aWorktree}" ]]; then
    git -C "${REPO_ROOT}" worktree remove --force "${aWorktree}" >/dev/null 2>&1 || true
  fi
  if [[ -n "${aRoot}" && -d "${aRoot}" ]]; then
    rm -rf "${aRoot}"
  fi
}

require_cmd git

LGhHelperScript="${NONX86_NATIVE_EVIDENCE_GH_HELPER:-${ROOT}/run_nonx86_native_evidence_via_github_actions.sh}"
if [[ ! -f "${LGhHelperScript}" ]]; then
  echo "[NATIVE-EVIDENCE-GH-CLEAN] Missing helper: ${LGhHelperScript}"
  exit 2
fi

if [[ -n "${RUN_ID_INPUT}" ]]; then
  bash "${LGhHelperScript}" "${BACKEND}" "${RUN_ID_INPUT}"
  exit $?
fi

LRef="${SIMD_NATIVE_EVIDENCE_REF:-$(git -C "${REPO_ROOT}" branch --show-current || true)}"
if [[ -z "${LRef}" ]]; then
  LRef="$(git -C "${REPO_ROOT}" rev-parse HEAD)"
fi

LHeadShaLocal="$(git -C "${REPO_ROOT}" rev-parse "${LRef}" 2>/dev/null || true)"
LHeadShaRemote=""
if ! looks_like_full_sha "${LRef}"; then
  LHeadShaRemote="$(git -C "${REPO_ROOT}" ls-remote --heads origin "${LRef}" 2>/dev/null | awk '{print $1}' | head -n 1 || true)"
fi

if [[ -z "${LHeadShaRemote}" ]]; then
  echo "[NATIVE-EVIDENCE-GH-CLEAN] Refuse clean-worktree dispatch: remote ref is missing or not a branch."
  echo "[NATIVE-EVIDENCE-GH-CLEAN] ref=${LRef}"
  echo "[NATIVE-EVIDENCE-GH-CLEAN] Push the branch first, or reuse an explicit run-id."
  exit 2
fi

if [[ -n "${LHeadShaLocal}" && "${LHeadShaLocal}" != "${LHeadShaRemote}" ]]; then
  echo "[NATIVE-EVIDENCE-GH-CLEAN] Refuse clean-worktree dispatch: remote ref does not match local HEAD."
  echo "[NATIVE-EVIDENCE-GH-CLEAN] ref=${LRef} local=${LHeadShaLocal} remote=${LHeadShaRemote}"
  echo "[NATIVE-EVIDENCE-GH-CLEAN] Push the local SIMD fixes first, then rerun native-evidence-via-gh-clean."
  exit 2
fi

LDownloadRoot="${SIMD_NATIVE_EVIDENCE_DOWNLOAD_ROOT:-${ROOT}/logs/native-evidence-gh}"
LTempRoot="$(mktemp -d)"
LTempWorktree="${LTempRoot}/dispatch-worktree"
cleanup() {
  cleanup_temp_worktree "${LTempWorktree}" "${LTempRoot}"
}
trap cleanup EXIT

echo "[NATIVE-EVIDENCE-GH-CLEAN] Create clean dispatch worktree: ${LTempWorktree}"
git -C "${REPO_ROOT}" worktree add --detach "${LTempWorktree}" "${LHeadShaRemote}" >/dev/null

echo "[NATIVE-EVIDENCE-GH-CLEAN] Dispatch ref=${LRef} commit=${LHeadShaRemote}"
SIMD_NATIVE_EVIDENCE_REF="${LRef}" \
SIMD_NATIVE_EVIDENCE_DOWNLOAD_ROOT="${LDownloadRoot}" \
  bash "${LTempWorktree}/tests/fafafa.core.simd/run_nonx86_native_evidence_via_github_actions.sh" "${BACKEND}"
