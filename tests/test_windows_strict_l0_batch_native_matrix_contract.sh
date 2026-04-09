#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
NATIVE_MATRIX_BAT="${REPO_ROOT}/tests/test_windows_strict_l0_batch_native_matrix.bat"
PREFLIGHT_SCRIPT="${REPO_ROOT}/tests/test_windows_lazbuild_smoke_preflight.sh"
WIN_REPO_ROOT="Z:\\$(printf '%s' "${REPO_ROOT}" | sed 's#^/##; s#/#\\\\#g')"

fail() {
  echo "[FAIL] $1" >&2
  exit 1
}

info() {
  echo "[INFO] $1"
}

require_literal() {
  local aPattern="$1"
  local aMessage="$2"
  if ! rg -n -F "${aPattern}" "${NATIVE_MATRIX_BAT}" >/dev/null; then
    fail "${aMessage}"
  fi
}

if [[ ! -f "${NATIVE_MATRIX_BAT}" ]]; then
  fail "missing native Windows batch matrix driver: ${NATIVE_MATRIX_BAT}"
fi

require_literal 'call "tools\lazbuild.bat" --help' \
  "native matrix driver does not preflight tools\\lazbuild.bat"
require_literal 'call :RUN_CASE "base" "tests\fafafa.core.base" "BuildOrTest.bat" "test"' \
  "native matrix driver does not include base module"
require_literal 'call :RUN_CASE "contracts" "tests\fafafa.core.contracts" "BuildOrTest.bat" "test"' \
  "native matrix driver does not include contracts module"
require_literal 'call :RUN_CASE "bits" "tests\fafafa.core.bits" "BuildOrTest.bat" "test"' \
  "native matrix driver does not include bits module"
require_literal 'call :RUN_CASE "layout" "tests\fafafa.core.layout" "BuildOrTest.bat" "test"' \
  "native matrix driver does not include layout module"
require_literal 'call :RUN_CASE "endian" "tests\fafafa.core.endian" "BuildOrTest.bat" "test"' \
  "native matrix driver does not include endian module"
require_literal 'call :RUN_CASE "span" "tests\fafafa.core.span" "BuildOrTest.bat" "test"' \
  "native matrix driver does not include span module"
require_literal 'call :RUN_CASE "option" "tests\fafafa.core.option" "BuildOrTest.bat" "test"' \
  "native matrix driver does not include option module"
require_literal 'call :RUN_CASE "result" "tests\fafafa.core.result" "BuildOrTest.bat" "test"' \
  "native matrix driver does not include result module"
require_literal 'call :RUN_CASE "platform" "tests\fafafa.core.platform" "BuildOrTest.bat" "test"' \
  "native matrix driver does not include platform module"
require_literal 'call :RUN_CASE "atomic" "tests\fafafa.core.atomic" "BuildOrTest.bat" "test"' \
  "native matrix driver does not include atomic module"
require_literal 'call :RUN_CASE "mem_allocator_foundation" "tests\fafafa.core.mem.allocator.foundation" "BuildOrTest.bat" "test"' \
  "native matrix driver does not include mem.allocator.foundation module"
require_literal 'call :RUN_CASE "mem_allocator_only" "tests\fafafa.core.mem" "BuildOrTest.bat" "test"' \
  "native matrix driver does not include mem allocator-only module"
require_literal '[PASS] strict L0 Windows native batch matrix verified' \
  "native matrix driver is missing the final pass marker"

if rg -n 'set FAFAFA_SKIP_BUILD=1|\[BUILD\] SKIPPED' "${NATIVE_MATRIX_BAT}" >/dev/null; then
  fail "native matrix driver must not force the runtime-only skip-build path"
fi

if command -v wine >/dev/null 2>&1; then
  set +e
  PREFLIGHT_OUTPUT="$("${PREFLIGHT_SCRIPT}" 2>&1)"
  PREFLIGHT_RC=$?
  set -e

  if [[ ${PREFLIGHT_RC} -eq 31 || ${PREFLIGHT_RC} -eq 32 ]]; then
    set +e
    OUTPUT="$(wine cmd /c "cd /d ${WIN_REPO_ROOT} && call tests\\test_windows_strict_l0_batch_native_matrix.bat" 2>&1)"
    RC=$?
    set -e

    if [[ ${RC} -eq 0 ]]; then
      fail "native matrix unexpectedly passed without a real Windows lazbuild.exe"
    fi

    if ! printf '%s' "${OUTPUT}" | rg -n 'lazbuild\.exe|LAZBUILD_EXE|Provide a real Windows lazbuild\.exe|test_windows_strict_l0_batch_native_matrix\.bat' >/dev/null; then
      printf '%s\n' "${OUTPUT}" >&2
      fail "native matrix fail-close output did not explain how to provide Windows lazbuild.exe"
    fi

    if printf '%s' "${OUTPUT}" | rg -n '\[BUILD\] SKIPPED' >/dev/null; then
      printf '%s\n' "${OUTPUT}" >&2
      fail "native matrix fail-close probe leaked runtime-only skip-build markers"
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

echo "[PASS] strict L0 Windows native batch matrix contract verified"
