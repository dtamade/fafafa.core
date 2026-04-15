#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
COLLECTOR_BAT="${REPO_ROOT}/tests/collect_windows_strict_l0_native_evidence.bat"
VERIFIER_BAT="${REPO_ROOT}/tests/verify_windows_strict_l0_native_evidence.bat"
WORKFLOW_YML="${REPO_ROOT}/.github/workflows/l0-windows-native-evidence.yml"
PREFLIGHT_SCRIPT="${REPO_ROOT}/tests/test_windows_lazbuild_smoke_preflight.sh"
WIN_REPO_ROOT="Z:\\$(printf '%s' "${REPO_ROOT}" | sed 's#^/##; s#/#\\\\#g')"

fail() {
  echo "[FAIL] $1" >&2
  exit 1
}

info() {
  echo "[INFO] $1"
}

require_literal_in_file() {
  local aFile="$1"
  local aPattern="$2"
  local aMessage="$3"
  if ! rg -n -F "${aPattern}" "${aFile}" >/dev/null; then
    fail "${aMessage}"
  fi
}

if [[ ! -f "${COLLECTOR_BAT}" ]]; then
  fail "missing strict L0 native evidence collector: ${COLLECTOR_BAT}"
fi

if [[ ! -f "${VERIFIER_BAT}" ]]; then
  fail "missing strict L0 native evidence verifier: ${VERIFIER_BAT}"
fi

if [[ ! -f "${WORKFLOW_YML}" ]]; then
  fail "missing strict L0 native evidence workflow: ${WORKFLOW_YML}"
fi

require_literal_in_file "${COLLECTOR_BAT}" '[L0-NATIVE] strict L0 Windows native evidence capture' \
  "collector does not declare the strict L0 native evidence source marker"
require_literal_in_file "${COLLECTOR_BAT}" 'call "tests\test_windows_strict_l0_batch_native_matrix.bat"' \
  "collector does not call the native batch matrix driver"
require_literal_in_file "${COLLECTOR_BAT}" 'summary.md' \
  "collector does not write summary.md"
require_literal_in_file "${COLLECTOR_BAT}" 'environment.txt' \
  "collector does not write environment.txt"
require_literal_in_file "${COLLECTOR_BAT}" 'source_revision.txt' \
  "collector does not write source_revision.txt"
require_literal_in_file "${COLLECTOR_BAT}" '[L0-NATIVE] MATRIX_EXIT_CODE=' \
  "collector does not record matrix exit code"
require_literal_in_file "${COLLECTOR_BAT}" '[L0-NATIVE] EvidenceDir:' \
  "collector does not print evidence directory"

require_literal_in_file "${VERIFIER_BAT}" '[L0-NATIVE] strict L0 Windows native evidence capture' \
  "verifier does not require the collector source marker"
require_literal_in_file "${VERIFIER_BAT}" '[L0-NATIVE] MATRIX_EXIT_CODE=0' \
  "verifier does not require a successful native matrix exit code"
require_literal_in_file "${VERIFIER_BAT}" 'source_revision.txt' \
  "verifier does not require source_revision.txt"
require_literal_in_file "${VERIFIER_BAT}" 'environment.txt' \
  "verifier does not require environment.txt"
require_literal_in_file "${VERIFIER_BAT}" 'summary.md' \
  "verifier does not require summary.md"
require_literal_in_file "${VERIFIER_BAT}" 'base.log' \
  "verifier does not check module logs"

require_literal_in_file "${WORKFLOW_YML}" 'name: L0 Windows Native Evidence' \
  "workflow name is missing"
require_literal_in_file "${WORKFLOW_YML}" 'workflow_dispatch:' \
  "workflow is not manually dispatchable"
require_literal_in_file "${WORKFLOW_YML}" 'runs-on: windows-latest' \
  "workflow does not run on windows-latest"
require_literal_in_file "${WORKFLOW_YML}" "Install-ChocoPackage 'freepascal'" \
  "workflow does not install freepascal"
require_literal_in_file "${WORKFLOW_YML}" "Install-ChocoPackage 'lazarus'" \
  "workflow does not install lazarus"
require_literal_in_file "${WORKFLOW_YML}" 'collect_windows_strict_l0_native_evidence.bat' \
  "workflow does not run the native evidence collector"
require_literal_in_file "${WORKFLOW_YML}" 'verify_windows_strict_l0_native_evidence.bat' \
  "workflow does not run the native evidence verifier"
require_literal_in_file "${WORKFLOW_YML}" 'actions/upload-artifact@v4' \
  "workflow does not upload native evidence artifacts"

if command -v wine >/dev/null 2>&1; then
  set +e
  PREFLIGHT_OUTPUT="$("${PREFLIGHT_SCRIPT}" 2>&1)"
  PREFLIGHT_RC=$?
  set -e

  if [[ ${PREFLIGHT_RC} -eq 31 || ${PREFLIGHT_RC} -eq 32 ]]; then
    set +e
    OUTPUT="$(wine cmd /c "cd /d ${WIN_REPO_ROOT} && call tests\\collect_windows_strict_l0_native_evidence.bat" 2>&1)"
    RC=$?
    set -e

    if [[ ${RC} -eq 0 ]]; then
      fail "collector unexpectedly passed without a real Windows lazbuild.exe"
    fi

    if ! printf '%s' "${OUTPUT}" | rg -n 'lazbuild\.exe|LAZBUILD_EXE|Provide a real Windows lazbuild\.exe|test_windows_strict_l0_batch_native_matrix\.bat' >/dev/null; then
      printf '%s\n' "${OUTPUT}" >&2
      fail "collector fail-close output did not explain how to provide Windows lazbuild.exe"
    fi

    info "dynamic fail-close probe verified under wine"
  elif [[ ${PREFLIGHT_RC} -eq 0 ]]; then
    info "native lazbuild appears available under wine; dynamic fail-close probe skipped"
  else
    printf '%s\n' "${PREFLIGHT_OUTPUT}" >&2
    fail "preflight returned unexpected rc=${PREFLIGHT_RC}"
  fi
else
  info "wine not found; dynamic fail-close probe skipped"
fi

echo "[PASS] strict L0 native evidence contract verified"
