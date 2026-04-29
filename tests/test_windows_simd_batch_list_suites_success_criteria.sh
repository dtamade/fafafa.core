#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
BATCH_RUNNER="${REPO_ROOT}/tests/fafafa.core.simd/buildOrTest.bat"

fail() {
  echo "[FAIL] $*" >&2
  exit 1
}

if [[ ! -f "${BATCH_RUNNER}" ]]; then
  fail "missing SIMD batch runner: ${BATCH_RUNNER}"
fi

if ! command -v wine >/dev/null 2>&1; then
  echo "[SKIP] wine not found; skip Windows SIMD batch list-suites success smoke"
  exit 0
fi

if ! command -v x86_64-w64-mingw32-gcc >/dev/null 2>&1; then
  echo "[SKIP] x86_64-w64-mingw32-gcc not found; skip Windows SIMD batch list-suites success smoke"
  exit 0
fi

win_path() {
  printf 'Z:\\%s' "$(printf '%s' "$1" | sed 's#^/##; s#/#\\\\#g')"
}

TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/simd-list-suites-XXXXXX")"
trap 'rm -rf "${TMP_DIR}"' EXIT

WIN_REPO_ROOT="$(win_path "${REPO_ROOT}")"
WIN_TMP_DIR="$(win_path "${TMP_DIR}")"

cat > "${TMP_DIR}/success.log" <<'EOF'
Info: (lazarus) Execute Title="Compile Project, Mode: Release, Target: C:\repo\tests\fafafa.core.simd\bin2\fafafa.core.simd.test.exe"
(9015) Linking C:\repo\tests\fafafa.core.simd\bin2\fafafa.core.simd.test.exe
(1008) 42 lines compiled, 0.1 sec, 4096 bytes code, 128 bytes data
EOF

cat > "${TMP_DIR}/fake_zero_rc_lazbuild.bat" <<EOF
@echo off
type ${WIN_TMP_DIR}\\success.log
exit /b 0
EOF

cat > "${TMP_DIR}/fake_list_suites.c" <<'EOF'
#include <stdio.h>
#include <string.h>

int main(int argc, char **argv) {
  if (argc > 1 && strcmp(argv[1], "--list-suites") == 0) {
    puts("Available suites:");
    puts("  TTestCase_Global");
    puts("  TTestCase_BackendSmoke");
    return 1;
  }
  puts("unexpected args");
  return 2;
}
EOF

x86_64-w64-mingw32-gcc -O2 -s -o "${TMP_DIR}/fafafa.core.simd.test.exe" "${TMP_DIR}/fake_list_suites.c"
mkdir -p "${TMP_DIR}/suite-out/bin2"
cp "${TMP_DIR}/fafafa.core.simd.test.exe" "${TMP_DIR}/suite-out/bin2/fafafa.core.simd.test.exe"

cat > "${TMP_DIR}/run_suite_list.bat" <<EOF
@echo off
cd /d ${WIN_REPO_ROOT}
set "LAZBUILD=${WIN_TMP_DIR}\\fake_zero_rc_lazbuild.bat"
set "SIMD_OUTPUT_ROOT=${WIN_TMP_DIR}\\suite-out"
call tests\\fafafa.core.simd\\buildOrTest.bat test --list-suites
exit /b %ERRORLEVEL%
EOF

set +e
OUTPUT="$(wine cmd /c "${WIN_TMP_DIR}\\run_suite_list.bat" 2>&1)"
RC=$?
set -e

if [[ ${RC} -ne 0 ]]; then
  printf '%s\n' "${OUTPUT}" >&2
  fail "synthetic list-suites batch case should succeed despite rc=1 suite lister"
fi

if ! printf '%s' "${OUTPUT}" | rg -n "\[TEST\] WARN \(suite list output present despite rc=1\)" >/dev/null; then
  printf '%s\n' "${OUTPUT}" >&2
  fail "synthetic list-suites batch case did not emit the expected warn marker"
fi

if ! printf '%s' "${OUTPUT}" | rg -n "\[TEST\] OK" >/dev/null; then
  printf '%s\n' "${OUTPUT}" >&2
  fail "synthetic list-suites batch case did not finish with TEST OK"
fi

echo "[PASS] windows SIMD batch list-suites success criteria verified"
