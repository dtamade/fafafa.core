#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
WIN_REPO_ROOT="Z:\\$(printf '%s' "${REPO_ROOT}" | sed 's#^/##; s#/#\\\\#g')"
LOG_DIR="${REPO_ROOT}/tests/_windows_batch_runtime_matrix"

fail() {
  echo "[FAIL] $1" >&2
  exit 1
}

info() {
  echo "[INFO] $1"
}

require_tool() {
  if ! command -v "$1" >/dev/null 2>&1; then
    fail "required tool not found: $1"
  fi
}

build_case() {
  local aProject="$1"
  local aBuildMode="$2"
  if [[ -n "${aBuildMode}" ]]; then
    lazbuild --os=win64 --cpu=x86_64 --bm="${aBuildMode}" --build-all "${aProject}"
  else
    lazbuild --os=win64 --cpu=x86_64 --build-all "${aProject}"
  fi
}

run_batch_case() {
  local aName="$1"
  local aWinModuleDir="$2"
  local aBatchFile="$3"
  local aAction="$4"
  local LLogFile="${LOG_DIR}/${aName}.log"
  local LOutput
  local LRc

  mkdir -p "${LOG_DIR}"
  set +e
  LOutput="$(wine cmd /c "cd /d ${WIN_REPO_ROOT}\\${aWinModuleDir} && set FAFAFA_SKIP_BUILD=1 && call ${aBatchFile} ${aAction}" 2>&1)"
  LRc=$?
  set -e

  printf '%s\n' "${LOutput}" >"${LLogFile}"

  if [[ ${LRc} -ne 0 ]]; then
    printf '%s\n' "${LOutput}" >&2
    fail "${aName}: batch runner exited with rc=${LRc}"
  fi

  if ! printf '%s' "${LOutput}" | rg -n "\[BUILD\] SKIPPED|\[TEST\] OK|\[LEAK\] OK" >/dev/null; then
    printf '%s\n' "${LOutput}" >&2
    fail "${aName}: batch runner output did not show skip-build runtime path"
  fi

  if printf '%s' "${LOutput}" | rg -n "lazbuild not found|FAILED code=|Test executable not found|heaptrc reports unfreed blocks" >/dev/null; then
    printf '%s\n' "${LOutput}" >&2
    fail "${aName}: batch runner output contains build/runtime failure markers"
  fi

  info "${aName}: PASS"
}

require_tool lazbuild
require_tool wine
require_tool rg

build_case "${REPO_ROOT}/tests/fafafa.core.base/fafafa.core.base.test.lpi" ""
build_case "${REPO_ROOT}/tests/fafafa.core.contracts/fafafa.core.contracts.test.lpi" "Debug"
build_case "${REPO_ROOT}/tests/fafafa.core.bits/fafafa.core.bits.test.lpi" ""
build_case "${REPO_ROOT}/tests/fafafa.core.layout/fafafa.core.layout.test.lpi" ""
build_case "${REPO_ROOT}/tests/fafafa.core.endian/fafafa.core.endian.test.lpi" ""
build_case "${REPO_ROOT}/tests/fafafa.core.span/fafafa.core.span.test.lpi" ""
build_case "${REPO_ROOT}/tests/fafafa.core.option/fafafa.core.option.test.lpi" ""
build_case "${REPO_ROOT}/tests/fafafa.core.result/fafafa.core.result.test.lpi" ""
build_case "${REPO_ROOT}/tests/fafafa.core.platform/fafafa.core.platform.test.lpi" ""
build_case "${REPO_ROOT}/tests/fafafa.core.atomic/tests_atomic.lpi" ""
build_case "${REPO_ROOT}/tests/fafafa.core.mem.allocator.foundation/fafafa.core.mem.allocator.foundation.test.lpi" ""
build_case "${REPO_ROOT}/tests/fafafa.core.mem/tests_mem_allocator_only.lpi" "Debug"

run_batch_case "base" "tests\\fafafa.core.base" "BuildOrTest.bat" "test"
run_batch_case "contracts" "tests\\fafafa.core.contracts" "BuildOrTest.bat" "test"
run_batch_case "bits" "tests\\fafafa.core.bits" "BuildOrTest.bat" "test"
run_batch_case "layout" "tests\\fafafa.core.layout" "BuildOrTest.bat" "test"
run_batch_case "endian" "tests\\fafafa.core.endian" "BuildOrTest.bat" "test"
run_batch_case "span" "tests\\fafafa.core.span" "BuildOrTest.bat" "test"
run_batch_case "option" "tests\\fafafa.core.option" "BuildOrTest.bat" "test"
run_batch_case "result" "tests\\fafafa.core.result" "BuildOrTest.bat" "test"
run_batch_case "platform" "tests\\fafafa.core.platform" "BuildOrTest.bat" "test"
run_batch_case "atomic" "tests\\fafafa.core.atomic" "BuildOrTest.bat" "test"
run_batch_case "mem_allocator_foundation" "tests\\fafafa.core.mem.allocator.foundation" "BuildOrTest.bat" "test"
run_batch_case "mem_allocator_only" "tests\\fafafa.core.mem" "BuildOrTest.bat" "test"

echo "[PASS] strict L0 Windows batch runtime matrix verified"
