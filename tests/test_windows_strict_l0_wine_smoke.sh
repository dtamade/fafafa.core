#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
LOG_DIR="${REPO_ROOT}/tests/_windows_wine_l0_smoke"

info() {
  echo "[INFO] $1"
}

fail() {
  echo "[FAIL] $1" >&2
  exit 1
}

require_tool() {
  if ! command -v "$1" >/dev/null 2>&1; then
    fail "required tool not found: $1"
  fi
}

resolve_executable() {
  local LCandidate
  for LCandidate in "$@"; do
    if [[ -f "${LCandidate}" ]]; then
      printf '%s\n' "${LCandidate}"
      return 0
    fi
  done
  return 1
}

check_log_clean() {
  local aLogFile="$1"
  if rg -n "Number of errors:[[:space:]]+[1-9]|Number of failures:[[:space:]]+[1-9]|^[1-9][0-9]* unfreed memory blocks" "${aLogFile}" >/dev/null; then
    return 1
  fi
  return 0
}

run_case() {
  local aName="$1"
  local aProject="$2"
  local aBuildMode="$3"
  shift 3
  local LCandidates=("$@")
  local LExe
  local LLogFile="${LOG_DIR}/${aName}.log"
  local LBuildArgs=(--os=win64 --cpu=x86_64 --build-all)
  local LFileInfo
  local LRunRc

  mkdir -p "${LOG_DIR}"
  : >"${LLogFile}"

  if [[ -n "${aBuildMode}" ]]; then
    LBuildArgs+=(--bm="${aBuildMode}")
  fi

  info "Building ${aName} for win64"
  lazbuild "${LBuildArgs[@]}" "${aProject}"

  if ! LExe="$(resolve_executable "${LCandidates[@]}")"; then
    fail "${aName}: expected Windows executable not found"
  fi

  LFileInfo="$(file "${LExe}")"
  if [[ "${LFileInfo}" != *"PE32+"* ]] && [[ "${LFileInfo}" != *"MS Windows"* ]]; then
    fail "${aName}: executable is not a Windows PE image: ${LFileInfo}"
  fi

  info "Running ${aName} under wine"
  set +e
  wine "${LExe}" --all --format=plain >"${LLogFile}" 2>&1
  LRunRc=$?
  set -e

  if [[ ${LRunRc} -ne 0 ]]; then
    tail -n 80 "${LLogFile}" >&2 || true
    fail "${aName}: wine test run failed with rc=${LRunRc}"
  fi

  if ! check_log_clean "${LLogFile}"; then
    tail -n 80 "${LLogFile}" >&2 || true
    fail "${aName}: test output contains failures, errors, or leaks"
  fi

  info "${aName}: PASS"
}

require_tool lazbuild
require_tool wine
require_tool file
require_tool rg

run_case \
  "platform" \
  "${REPO_ROOT}/tests/fafafa.core.platform/fafafa.core.platform.test.lpi" \
  "" \
  "${REPO_ROOT}/tests/fafafa.core.platform/bin/fafafa.core.platform.test.exe"

run_case \
  "atomic" \
  "${REPO_ROOT}/tests/fafafa.core.atomic/tests_atomic.lpi" \
  "" \
  "${REPO_ROOT}/tests/fafafa.core.atomic/bin/tests_atomic.exe"

run_case \
  "mem_allocator_foundation" \
  "${REPO_ROOT}/tests/fafafa.core.mem.allocator.foundation/fafafa.core.mem.allocator.foundation.test.lpi" \
  "" \
  "${REPO_ROOT}/tests/fafafa.core.mem.allocator.foundation/bin/fafafa.core.mem.allocator.foundation.test.exe"

run_case \
  "mem_allocator_only" \
  "${REPO_ROOT}/tests/fafafa.core.mem/tests_mem_allocator_only.lpi" \
  "Debug" \
  "${REPO_ROOT}/tests/fafafa.core.mem/bin/tests_mem_allocator_only_debug.exe" \
  "${REPO_ROOT}/tests/fafafa.core.mem/bin/tests_mem_allocator_only.exe"

echo "[PASS] strict L0 Windows wine smoke verified"
