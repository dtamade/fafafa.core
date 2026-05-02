#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
BATCH_RUNNER="${REPO_ROOT}/tests/fafafa.core.simd.cpuinfo.x86/buildOrTest.bat"

fail() {
  echo "[FAIL] $*" >&2
  exit 1
}

if [[ ! -f "${BATCH_RUNNER}" ]]; then
  fail "missing Windows cpuinfo.x86 batch runner: ${BATCH_RUNNER}"
fi

if ! command -v wine >/dev/null 2>&1; then
  echo "[SKIP] wine not found; skip Windows cpuinfo.x86 batch success-criteria smoke"
  exit 0
fi

win_path() {
  printf 'Z:\\%s' "$(printf '%s' "$1" | sed 's#^/##; s#/#\\\\#g')"
}

TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/simd-cpuinfo-x86-batch-XXXXXX")"
trap 'rm -rf "${TMP_DIR}"' EXIT

REPO_LINK_WITH_SPACES="${TMP_DIR}/repo with spaces"
ln -s "${REPO_ROOT}" "${REPO_LINK_WITH_SPACES}"

WIN_REPO_ROOT="$(win_path "${REPO_LINK_WITH_SPACES}")"
WIN_TMP_DIR="$(win_path "${TMP_DIR}")"

EXPECTED_BIN_WIN="${WIN_TMP_DIR}\\success-out\\bin\\fafafa.core.simd.cpuinfo.x86.test.exe"
RESOLVED_BIN_WIN="${WIN_TMP_DIR}\\linked out\\fafafa.core.simd.cpuinfo.x86.test.exe"

mkdir -p \
  "${TMP_DIR}/success-out/bin" \
  "${TMP_DIR}/resolved-out/bin" \
  "${TMP_DIR}/linked out"
: > "${TMP_DIR}/success-out/bin/fafafa.core.simd.cpuinfo.x86.test.exe"
: > "${TMP_DIR}/linked out/fafafa.core.simd.cpuinfo.x86.test.exe"

cat > "${TMP_DIR}/success.log" <<EOF
Hint: (lazbuild) Primary config path: "C:\\Users\\runneradmin\\AppData\\Local\\lazarus"
InitializeFppkg failed: Could not find a fpc executable in the PATH
Info: (lazarus) Execute Title="Compile Project, Mode: Default, Target: ${EXPECTED_BIN_WIN}"
(9015) Linking ${EXPECTED_BIN_WIN}
(1008) 4798 lines compiled, 0.3 sec, 316304 bytes code, 12340 bytes data
(1022) 2 hint(s) issued
EOF

cat > "${TMP_DIR}/resolved.log" <<EOF
Hint: (lazbuild) Primary config path: "C:\\Users\\runneradmin\\AppData\\Local\\lazarus"
InitializeFppkg failed: Could not find a fpc executable in the PATH
Info: (lazarus) Execute Title="Compile Project, Mode: Default, Target: ${RESOLVED_BIN_WIN}"
(9015) Linking ${RESOLVED_BIN_WIN}
(1008) 4798 lines compiled, 0.3 sec, 316304 bytes code, 12340 bytes data
(1022) 2 hint(s) issued
EOF

cat > "${TMP_DIR}/failure.log" <<'EOF'
Fatal: synthetic lazbuild failure
returned an error exitcode
EOF

cat > "${TMP_DIR}/fake_success_lazbuild.bat" <<EOF
@echo off
type ${WIN_TMP_DIR}\\success.log
exit /b 1
EOF

cat > "${TMP_DIR}/fake_resolved_lazbuild.bat" <<EOF
@echo off
type ${WIN_TMP_DIR}\\resolved.log
exit /b 1
EOF

cat > "${TMP_DIR}/fake_failure_lazbuild.bat" <<EOF
@echo off
type ${WIN_TMP_DIR}\\failure.log
exit /b 1
EOF

cat > "${TMP_DIR}/run_success.bat" <<EOF
@echo off
cd /d "${WIN_REPO_ROOT}"
set "LAZBUILD=${WIN_TMP_DIR}\\fake_success_lazbuild.bat"
set "SIMD_OUTPUT_ROOT=${WIN_TMP_DIR}\\success-out"
call tests\\fafafa.core.simd.cpuinfo.x86\\buildOrTest.bat build
exit /b %ERRORLEVEL%
EOF

cat > "${TMP_DIR}/run_resolved_success.bat" <<EOF
@echo off
cd /d "${WIN_REPO_ROOT}"
set "LAZBUILD=${WIN_TMP_DIR}\\fake_resolved_lazbuild.bat"
set "SIMD_OUTPUT_ROOT=${WIN_TMP_DIR}\\resolved-out"
call tests\\fafafa.core.simd.cpuinfo.x86\\buildOrTest.bat build
exit /b %ERRORLEVEL%
EOF

cat > "${TMP_DIR}/run_failure.bat" <<EOF
@echo off
cd /d "${WIN_REPO_ROOT}"
set "LAZBUILD=${WIN_TMP_DIR}\\fake_failure_lazbuild.bat"
set "SIMD_OUTPUT_ROOT=${WIN_TMP_DIR}\\failure-out"
call tests\\fafafa.core.simd.cpuinfo.x86\\buildOrTest.bat build
exit /b %ERRORLEVEL%
EOF

set +e
SUCCESS_OUTPUT="$(wine cmd /c "${WIN_TMP_DIR}\\run_success.bat" 2>&1)"
SUCCESS_RC=$?
set -e

if [[ ${SUCCESS_RC} -ne 0 ]]; then
  printf '%s\n' "${SUCCESS_OUTPUT}" >&2
  fail "synthetic cpuinfo.x86 linked-artifact batch case should succeed"
fi

if ! printf '%s' "${SUCCESS_OUTPUT}" | rg -n "\[BUILD\] WARN .*artifact/build log are usable" >/dev/null; then
  printf '%s\n' "${SUCCESS_OUTPUT}" >&2
  fail "synthetic cpuinfo.x86 linked-artifact batch case did not emit the expected usable-artifact warn marker"
fi

if ! printf '%s' "${SUCCESS_OUTPUT}" | rg -n "\[BUILD\] OK" >/dev/null; then
  printf '%s\n' "${SUCCESS_OUTPUT}" >&2
  fail "synthetic cpuinfo.x86 linked-artifact batch case did not finish with BUILD OK"
fi

set +e
RESOLVED_OUTPUT="$(wine cmd /c "${WIN_TMP_DIR}\\run_resolved_success.bat" 2>&1)"
RESOLVED_RC=$?
set -e

if [[ ${RESOLVED_RC} -ne 0 ]]; then
  printf '%s\n' "${RESOLVED_OUTPUT}" >&2
  fail "synthetic cpuinfo.x86 resolved-linked-path batch case should succeed"
fi

if ! printf '%s' "${RESOLVED_OUTPUT}" | rg -n "\[BUILD\] WARN .*artifact/build log are usable" >/dev/null; then
  printf '%s\n' "${RESOLVED_OUTPUT}" >&2
  fail "synthetic cpuinfo.x86 resolved-linked-path batch case did not emit the expected usable-artifact warn marker"
fi

if ! printf '%s' "${RESOLVED_OUTPUT}" | rg -n "\[BUILD\] Binary normalized: .*linked out.*fafafa\.core\.simd\.cpuinfo\.x86\.test\.exe .*resolved-out.*fafafa\.core\.simd\.cpuinfo\.x86\.test\.exe" >/dev/null; then
  printf '%s\n' "${RESOLVED_OUTPUT}" >&2
  fail "synthetic cpuinfo.x86 resolved-linked-path batch case did not emit the expected binary-normalization marker"
fi

if ! printf '%s' "${RESOLVED_OUTPUT}" | rg -n "\[BUILD\] OK" >/dev/null; then
  printf '%s\n' "${RESOLVED_OUTPUT}" >&2
  fail "synthetic cpuinfo.x86 resolved-linked-path batch case did not finish with BUILD OK"
fi

set +e
FAILURE_OUTPUT="$(wine cmd /c "${WIN_TMP_DIR}\\run_failure.bat" 2>&1)"
FAILURE_RC=$?
set -e

if [[ ${FAILURE_RC} -eq 0 ]]; then
  printf '%s\n' "${FAILURE_OUTPUT}" >&2
  fail "synthetic cpuinfo.x86 fatal batch case should fail"
fi

if ! printf '%s' "${FAILURE_OUTPUT}" | rg -n "\[BUILD\] FAILED" >/dev/null; then
  printf '%s\n' "${FAILURE_OUTPUT}" >&2
  fail "synthetic cpuinfo.x86 fatal batch case did not emit BUILD FAILED"
fi

echo "[PASS] windows cpuinfo.x86 batch success criteria verified"
