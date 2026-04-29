#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
PUBLICABI_RUNNER="${REPO_ROOT}/tests/fafafa.core.simd.publicabi/BuildOrTest.bat"
SIMD_MAIN_RUNNER="${REPO_ROOT}/tests/fafafa.core.simd/buildOrTest.bat"

fail() {
  echo "[FAIL] $*" >&2
  exit 1
}

if [[ ! -f "${PUBLICABI_RUNNER}" ]]; then
  fail "missing public ABI runner: ${PUBLICABI_RUNNER}"
fi
if [[ ! -f "${SIMD_MAIN_RUNNER}" ]]; then
  fail "missing simd main runner: ${SIMD_MAIN_RUNNER}"
fi

if ! command -v wine >/dev/null 2>&1; then
  echo "[SKIP] wine not found; skip Windows public ABI FPC resolution smoke"
  exit 0
fi

win_path() {
  printf 'Z:\\%s' "$(printf '%s' "$1" | sed 's#^/##; s#/#\\\\#g')"
}

TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/simd-publicabi-fpc-XXXXXX")"
trap 'rm -rf "${TMP_DIR}"' EXIT

REPO_LINK_WITH_SPACES="${TMP_DIR}/repo with spaces"
ln -s "${REPO_ROOT}" "${REPO_LINK_WITH_SPACES}"

WIN_REPO_ROOT="$(win_path "${REPO_LINK_WITH_SPACES}")"
WIN_TMP_DIR="$(win_path "${TMP_DIR}")"

cat > "${TMP_DIR}/fake_fpc.bat" <<'EOF'
@echo off
setlocal EnableExtensions EnableDelayedExpansion
if /I "%~1"=="-iTP" (
  echo x86_64
  exit /b 0
)
if /I "%~1"=="-iTO" (
  echo win64
  exit /b 0
)
set "OUTDIR="
:scan_args
if "%~1"=="" goto after_scan
set "ARG=%~1"
if /I "!ARG:~0,3!"=="-FE" set "OUTDIR=!ARG:~3!"
shift
goto scan_args
:after_scan
if not defined OUTDIR exit /b 2
if not exist "!OUTDIR!" mkdir "!OUTDIR!" >nul 2>nul
type nul > "!OUTDIR!\libfafafa.core.simd.publicabi.dll"
exit /b 0
EOF

cat > "${TMP_DIR}/pwsh.bat" <<'EOF'
@echo off
exit /b 0
EOF

cat > "${TMP_DIR}/run_publicabi_test.bat" <<EOF
@echo off
cd /d "${WIN_REPO_ROOT}"
set "PATH=${WIN_TMP_DIR};%PATH%"
set "FPC_BIN=${WIN_TMP_DIR}\\fake_fpc.bat"
set "SIMD_OUTPUT_ROOT=${WIN_TMP_DIR}\\publicabi-out"
call tests\\fafafa.core.simd.publicabi\\BuildOrTest.bat test
exit /b %ERRORLEVEL%
EOF

set +e
OUTPUT="$(wine cmd /c "${WIN_TMP_DIR}\\run_publicabi_test.bat" 2>&1)"
RC=$?
set -e

if [[ ${RC} -ne 0 ]]; then
  printf '%s\n' "${OUTPUT}" >&2
  fail "Windows public ABI runner should succeed when FPC_BIN points to an explicit compiler path"
fi

if ! printf '%s' "${OUTPUT}" | rg -n "\[BUILD\] Project:" >/dev/null; then
  printf '%s\n' "${OUTPUT}" >&2
  fail "Windows public ABI runner did not start the build step"
fi

if ! printf '%s' "${OUTPUT}" | rg -n "\[TEST\] OK" >/dev/null; then
  printf '%s\n' "${OUTPUT}" >&2
  fail "Windows public ABI runner did not report TEST OK"
fi

if [[ ! -f "${TMP_DIR}/publicabi-out/bin/libfafafa.core.simd.publicabi.dll" ]]; then
  printf '%s\n' "${OUTPUT}" >&2
  fail "Windows public ABI runner did not materialize the expected DLL artifact"
fi

cat > "${TMP_DIR}/run_simd_main_publicabi_smoke.bat" <<EOF
@echo off
cd /d "${WIN_REPO_ROOT}"
set "PATH=${WIN_TMP_DIR};%PATH%"
set "FPC_BIN=${WIN_TMP_DIR}\\fake_fpc.bat"
set "SIMD_OUTPUT_ROOT=${WIN_TMP_DIR}\\simd-main-out"
call tests\\fafafa.core.simd\\buildOrTest.bat publicabi-smoke
exit /b %ERRORLEVEL%
EOF

set +e
MAIN_OUTPUT="$(wine cmd /c "${WIN_TMP_DIR}\\run_simd_main_publicabi_smoke.bat" 2>&1)"
MAIN_RC=$?
set -e

if [[ ${MAIN_RC} -ne 0 ]]; then
  printf '%s\n' "${MAIN_OUTPUT}" >&2
  fail "Windows main SIMD runner should succeed when publicabi-smoke is invoked through the top-level batch gate"
fi

if ! printf '%s' "${MAIN_OUTPUT}" | rg -n "\[TEST\] OK" >/dev/null; then
  printf '%s\n' "${MAIN_OUTPUT}" >&2
  fail "Windows main SIMD runner did not report TEST OK for publicabi-smoke"
fi

if ! printf '%s' "${MAIN_OUTPUT}" | rg -n "tests\\\\fafafa\\.core\\.simd\\.publicabi\\\\fafafa\\.core\\.simd\\.publicabi\\.lpr" >/dev/null; then
  printf '%s\n' "${MAIN_OUTPUT}" >&2
  fail "Windows main SIMD runner did not build the publicabi project from the expected tests/fafafa.core.simd.publicabi path"
fi

if [[ ! -f "${TMP_DIR}/simd-main-out/publicabi/bin/libfafafa.core.simd.publicabi.dll" ]]; then
  printf '%s\n' "${MAIN_OUTPUT}" >&2
  fail "Windows main SIMD runner did not materialize the expected DLL artifact under publicabi output isolation"
fi

cat > "${TMP_DIR}/run_publicabi_bad_fpc.bat" <<EOF
@echo off
cd /d "${WIN_REPO_ROOT}"
set "PATH=${WIN_TMP_DIR};%PATH%"
set "FPC_BIN=${WIN_TMP_DIR}\\missing_fpc.bat"
set "SIMD_OUTPUT_ROOT=${WIN_TMP_DIR}\\publicabi-bad-fpc-out"
call tests\\fafafa.core.simd.publicabi\\BuildOrTest.bat test
exit /b %ERRORLEVEL%
EOF

set +e
BAD_OUTPUT="$(wine cmd /c "${WIN_TMP_DIR}\\run_publicabi_bad_fpc.bat" 2>&1)"
BAD_RC=$?
set -e

if [[ ${BAD_RC} -eq 0 ]]; then
  printf '%s\n' "${BAD_OUTPUT}" >&2
  fail "Windows public ABI runner must fail closed when explicit FPC_BIN is invalid"
fi

if ! printf '%s' "${BAD_OUTPUT}" | rg -n "requested FPC compiler not found" >/dev/null; then
  printf '%s\n' "${BAD_OUTPUT}" >&2
  fail "Windows public ABI runner did not explain the invalid explicit FPC_BIN failure"
fi

echo "[PASS] windows SIMD public ABI FPC resolution verified"
