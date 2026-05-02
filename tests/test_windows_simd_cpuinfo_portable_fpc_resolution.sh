#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
CPUINFO_RUNNER="${REPO_ROOT}/tests/fafafa.core.simd.cpuinfo/buildOrTest.bat"
SIMD_MAIN_RUNNER="${REPO_ROOT}/tests/fafafa.core.simd/buildOrTest.bat"

fail() {
  echo "[FAIL] $*" >&2
  exit 1
}

if [[ ! -f "${CPUINFO_RUNNER}" ]]; then
  fail "missing cpuinfo runner: ${CPUINFO_RUNNER}"
fi
if [[ ! -f "${SIMD_MAIN_RUNNER}" ]]; then
  fail "missing simd main runner: ${SIMD_MAIN_RUNNER}"
fi

if ! command -v wine >/dev/null 2>&1; then
  echo "[SKIP] wine not found; skip Windows cpuinfo portable FPC resolution smoke"
  exit 0
fi

if ! command -v x86_64-w64-mingw32-gcc >/dev/null 2>&1; then
  echo "[SKIP] x86_64-w64-mingw32-gcc not found; skip Windows cpuinfo portable FPC resolution smoke"
  exit 0
fi

win_path() {
  printf 'Z:\\%s' "$(printf '%s' "$1" | sed 's#^/##; s#/#\\\\#g')"
}

TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/simd-cpuinfo-fpc-XXXXXX")"
trap 'rm -rf "${TMP_DIR}"' EXIT

REPO_LINK_WITH_SPACES="${TMP_DIR}/repo with spaces"
ln -s "${REPO_ROOT}" "${REPO_LINK_WITH_SPACES}"

WIN_REPO_ROOT="$(win_path "${REPO_LINK_WITH_SPACES}")"
WIN_TMP_DIR="$(win_path "${TMP_DIR}")"

cat > "${TMP_DIR}/fake_cpuinfo_test.c" <<'EOF'
#include <stdio.h>
#include <string.h>

static void print_pass(void) {
  puts("Time:00.000 N:1 E:0 F:0 I:0");
  puts("Number of run tests: 1");
  puts("Number of errors: 0");
  puts("Number of failures: 0");
}

int main(int argc, char **argv) {
  if (argc > 1 && strcmp(argv[1], "--list") == 0) {
    puts("Available suites:");
    puts("  TTestCase_PlatformSpecific");
    puts("  TTestCase_LazyCPUInfo");
    return 0;
  }

  if (argc > 1 && strcmp(argv[1], "--suite=TTestCase_PlatformSpecific") == 0) {
    print_pass();
    return 0;
  }

  if (argc > 2 && strcmp(argv[1], "--suite") == 0 && strcmp(argv[2], "TTestCase_PlatformSpecific") == 0) {
    print_pass();
    return 0;
  }

  if (argc > 1 && strcmp(argv[1], "--suite=TTestCase_LazyCPUInfo") == 0) {
    print_pass();
    return 0;
  }

  if (argc > 2 && strcmp(argv[1], "--suite") == 0 && strcmp(argv[2], "TTestCase_LazyCPUInfo") == 0) {
    print_pass();
    return 0;
  }

  puts("Invalid option");
  return 2;
}
EOF

x86_64-w64-mingw32-gcc -O2 -s -o "${TMP_DIR}/fafafa.core.simd.cpuinfo.test.exe" "${TMP_DIR}/fake_cpuinfo_test.c"

cat > "${TMP_DIR}/fake_fpc.bat" <<EOF
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
set "OUTFILE="
:scan_args
if "%~1"=="" goto after_scan
set "ARG=%~1"
if /I "!ARG:~0,2!"=="-o" set "OUTFILE=!ARG:~2!"
shift
goto scan_args
:after_scan
if not defined OUTFILE exit /b 2
for %%D in ("!OUTFILE!\..") do if not exist "%%~fD" mkdir "%%~fD" >nul 2>nul
copy /y "${WIN_TMP_DIR}\\fafafa.core.simd.cpuinfo.test.exe" "!OUTFILE!" >nul
exit /b 0
EOF

cat > "${TMP_DIR}/run_cpuinfo_list_suites.bat" <<EOF
@echo off
cd /d "${WIN_REPO_ROOT}"
set "PATH=${WIN_TMP_DIR};%PATH%"
set "FPC_BIN=${WIN_TMP_DIR}\\fake_fpc.bat"
set "SIMD_OUTPUT_ROOT=${WIN_TMP_DIR}\\cpuinfo-out"
call tests\\fafafa.core.simd.cpuinfo\\buildOrTest.bat test --list-suites
exit /b %ERRORLEVEL%
EOF

set +e
LIST_OUTPUT="$(wine cmd /c "${WIN_TMP_DIR}\\run_cpuinfo_list_suites.bat" 2>&1)"
LIST_RC=$?
set -e

if [[ ${LIST_RC} -ne 0 ]]; then
  printf '%s\n' "${LIST_OUTPUT}" >&2
  fail "Windows cpuinfo portable runner should succeed when FPC_BIN points to an explicit compiler path"
fi

if ! printf '%s' "${LIST_OUTPUT}" | rg -n "Available suites:" >/dev/null; then
  printf '%s\n' "${LIST_OUTPUT}" >&2
  fail "Windows cpuinfo portable runner did not emit suite list output"
fi

if ! printf '%s' "${LIST_OUTPUT}" | rg -n "\[TEST\] OK" >/dev/null; then
  printf '%s\n' "${LIST_OUTPUT}" >&2
  fail "Windows cpuinfo portable runner did not report TEST OK for list-suites"
fi

if [[ ! -f "${TMP_DIR}/cpuinfo-out/bin/fafafa.core.simd.cpuinfo.test.exe" ]]; then
  printf '%s\n' "${LIST_OUTPUT}" >&2
  fail "Windows cpuinfo portable runner did not materialize the expected test binary"
fi

cat > "${TMP_DIR}/run_cpuinfo_platform_suite.bat" <<EOF
@echo off
cd /d "${WIN_REPO_ROOT}"
set "PATH=${WIN_TMP_DIR};%PATH%"
set "FPC_BIN=${WIN_TMP_DIR}\\fake_fpc.bat"
set "SIMD_OUTPUT_ROOT=${WIN_TMP_DIR}\\cpuinfo-suite-out"
call tests\\fafafa.core.simd.cpuinfo\\buildOrTest.bat test --suite=TTestCase_PlatformSpecific
exit /b %ERRORLEVEL%
EOF

set +e
SUITE_OUTPUT="$(wine cmd /c "${WIN_TMP_DIR}\\run_cpuinfo_platform_suite.bat" 2>&1)"
SUITE_RC=$?
set -e

if [[ ${SUITE_RC} -ne 0 ]]; then
  printf '%s\n' "${SUITE_OUTPUT}" >&2
  fail "Windows cpuinfo portable runner should succeed for a synthetic platform suite run"
fi

if ! printf '%s' "${SUITE_OUTPUT}" | rg -n "\[LEAK\] OK" >/dev/null; then
  printf '%s\n' "${SUITE_OUTPUT}" >&2
  fail "Windows cpuinfo portable runner did not complete leak check"
fi

cat > "${TMP_DIR}/run_simd_cpuinfo_lazy_repeat.bat" <<EOF
@echo off
cd /d "${WIN_REPO_ROOT}"
set "PATH=${WIN_TMP_DIR};%PATH%"
set "FPC_BIN=${WIN_TMP_DIR}\\fake_fpc.bat"
set "SIMD_OUTPUT_ROOT=${WIN_TMP_DIR}\\simd-main-out"
call tests\\fafafa.core.simd\\buildOrTest.bat cpuinfo-lazy-repeat 1
exit /b %ERRORLEVEL%
EOF

set +e
MAIN_OUTPUT="$(wine cmd /c "${WIN_TMP_DIR}\\run_simd_cpuinfo_lazy_repeat.bat" 2>&1)"
MAIN_RC=$?
set -e

if [[ ${MAIN_RC} -ne 0 ]]; then
  printf '%s\n' "${MAIN_OUTPUT}" >&2
  fail "Windows main SIMD runner should succeed when cpuinfo-lazy-repeat is invoked through the top-level batch runner"
fi

if ! printf '%s' "${MAIN_OUTPUT}" | rg -n "\[CPUINFO-LAZY\] OK suite=TTestCase_LazyCPUInfo rounds=1" >/dev/null; then
  printf '%s\n' "${MAIN_OUTPUT}" >&2
  fail "Windows main SIMD runner did not report CPUINFO-LAZY OK"
fi

if [[ ! -f "${TMP_DIR}/simd-main-out/cpuinfo/logs/repeat.TTestCase_LazyCPUInfo.1.txt" ]]; then
  printf '%s\n' "${MAIN_OUTPUT}" >&2
  fail "Windows main SIMD runner did not persist the lazy-repeat per-run log"
fi

cat > "${TMP_DIR}/run_cpuinfo_bad_fpc.bat" <<EOF
@echo off
cd /d "${WIN_REPO_ROOT}"
set "PATH=${WIN_TMP_DIR};%PATH%"
set "FPC_BIN=${WIN_TMP_DIR}\\missing_fpc.bat"
set "SIMD_OUTPUT_ROOT=${WIN_TMP_DIR}\\cpuinfo-bad-fpc-out"
call tests\\fafafa.core.simd.cpuinfo\\buildOrTest.bat test --list-suites
exit /b %ERRORLEVEL%
EOF

set +e
BAD_OUTPUT="$(wine cmd /c "${WIN_TMP_DIR}\\run_cpuinfo_bad_fpc.bat" 2>&1)"
BAD_RC=$?
set -e

if [[ ${BAD_RC} -eq 0 ]]; then
  printf '%s\n' "${BAD_OUTPUT}" >&2
  fail "Windows cpuinfo portable runner must fail closed when explicit FPC_BIN is invalid"
fi

if ! printf '%s' "${BAD_OUTPUT}" | rg -n "requested FPC compiler not found" >/dev/null; then
  printf '%s\n' "${BAD_OUTPUT}" >&2
  fail "Windows cpuinfo portable runner did not explain the invalid explicit FPC_BIN failure"
fi

echo "[PASS] windows SIMD cpuinfo portable FPC resolution verified"
