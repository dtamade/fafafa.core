#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
RUN_ALL_BAT="${REPO_ROOT}/tests/run_all_tests.bat"

fail() {
  echo "[FAIL] $*" >&2
  exit 1
}

if [[ ! -f "${RUN_ALL_BAT}" ]]; then
  fail "missing Windows run_all batch runner: ${RUN_ALL_BAT}"
fi

if ! command -v wine >/dev/null 2>&1; then
  echo "[SKIP] wine not found; skip Windows run_all batch exact-filter smoke"
  exit 0
fi

win_path() {
  printf 'Z:\\%s' "$(printf '%s' "$1" | sed 's#^/##; s#/#\\\\#g')"
}

TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/runall-batch-exact-filter-XXXXXX")"
trap 'rm -rf "${TMP_DIR}"' EXIT

mkdir -p \
  "${TMP_DIR}/tests/fafafa.core.simd" \
  "${TMP_DIR}/tests/fafafa.core.simd.publicabi"
cp "${RUN_ALL_BAT}" "${TMP_DIR}/tests/run_all_tests.bat"

cat > "${TMP_DIR}/tests/check_repo_hygiene.bat" <<'EOF'
@echo off
echo [CHECK] synthetic hygiene ok
exit /b 0
EOF

cat > "${TMP_DIR}/tests/fafafa.core.simd/buildOrTest.bat" <<'EOF'
@echo off
echo [TARGET] exact simd should run
exit /b 0
EOF

cat > "${TMP_DIR}/tests/fafafa.core.simd.publicabi/buildOrTest.bat" <<'EOF'
@echo off
echo [UNEXPECTED] publicabi prefix module should not run for exact filter
exit /b 23
EOF

WIN_RUN_BAT="$(win_path "${TMP_DIR}/run.bat")"
WIN_REPO_ROOT="$(win_path "${TMP_DIR}")"

cat > "${TMP_DIR}/run.bat" <<EOF
@echo off
cd /d "${WIN_REPO_ROOT}"
set "RUN_ACTION=check"
call tests\\run_all_tests.bat =fafafa.core.simd
exit /b %ERRORLEVEL%
EOF

set +e
RUN_OUTPUT="$(wine cmd /c "${WIN_RUN_BAT}" 2>&1)"
RUN_RC=$?
set -e

if [[ ${RUN_RC} -ne 0 ]]; then
  printf '%s\n' "${RUN_OUTPUT}" >&2
  fail "Windows run_all batch exact-filter smoke should succeed"
fi

if printf '%s' "${RUN_OUTPUT}" | rg -n "\\[UNEXPECTED\\]" >/dev/null; then
  printf '%s\n' "${RUN_OUTPUT}" >&2
  fail "Windows run_all batch exact filter incorrectly ran prefix-matched module"
fi

if ! printf '%s' "${RUN_OUTPUT}" | rg -n "\\[PASS\\] fafafa\\.core\\.simd \\(rc=0\\)" >/dev/null; then
  printf '%s\n' "${RUN_OUTPUT}" >&2
  fail "Windows run_all batch exact-filter smoke did not pass the target module"
fi

SUMMARY_FILE="${TMP_DIR}/tests/run_all_tests_summary.txt"
if [[ ! -f "${SUMMARY_FILE}" ]]; then
  fail "run_all batch exact-filter smoke did not materialize summary"
fi

SUMMARY_TEXT="$(tr -d '\r' < "${SUMMARY_FILE}")"

if ! printf '%s\n' "${SUMMARY_TEXT}" | rg -n "^Total:[[:space:]]+1$" >/dev/null; then
  printf '%s\n' "${SUMMARY_TEXT}" >&2
  fail "run_all batch exact-filter smoke should select exactly one module"
fi

if ! printf '%s\n' "${SUMMARY_TEXT}" | rg -n "^Passed:[[:space:]]+1$" >/dev/null; then
  printf '%s\n' "${SUMMARY_TEXT}" >&2
  fail "run_all batch exact-filter smoke should pass exactly one module"
fi

if ! printf '%s\n' "${SUMMARY_TEXT}" | rg -n "^Failed:[[:space:]]+0$" >/dev/null; then
  printf '%s\n' "${SUMMARY_TEXT}" >&2
  fail "run_all batch exact-filter smoke should have zero failed modules"
fi

echo "[PASS] windows run_all batch exact filter semantics verified"
