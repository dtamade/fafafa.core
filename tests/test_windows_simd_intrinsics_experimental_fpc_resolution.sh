#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
EXPERIMENTAL_RUNNER="${REPO_ROOT}/tests/fafafa.core.simd.intrinsics.experimental/BuildOrTest.sh"

fail() {
  echo "[FAIL] $*" >&2
  exit 1
}

if [[ ! -f "${EXPERIMENTAL_RUNNER}" ]]; then
  fail "missing experimental intrinsics runner: ${EXPERIMENTAL_RUNNER}"
fi

REAL_PYTHON3="$(command -v python3 || true)"
if [[ -z "${REAL_PYTHON3}" ]]; then
  echo "[SKIP] python3 not found; skip Windows experimental intrinsics FPC resolution smoke"
  exit 0
fi

TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/simd-intrinsics-experimental-fpc-XXXXXX")"
trap 'rm -rf "${TMP_DIR}"' EXIT

REPO_LINK_WITH_SPACES="${TMP_DIR}/repo with spaces"
ln -s "${REPO_ROOT}" "${REPO_LINK_WITH_SPACES}"

TRACE_LOG="${TMP_DIR}/fake_fpc.trace"
FAKE_BIN_DIR="${TMP_DIR}/fake-bin"
TOOL_BIN_DIR="${TMP_DIR}/tool-bin"
mkdir -p "${FAKE_BIN_DIR}" "${TOOL_BIN_DIR}"

link_tool() {
  local aTool
  local LSource

  aTool="$1"
  LSource="$(command -v "${aTool}" || true)"
  if [[ -z "${LSource}" ]]; then
    fail "required tool not found: ${aTool}"
  fi
  ln -s "${LSource}" "${TOOL_BIN_DIR}/${aTool}"
}

for LTool in bash cat chmod dirname getconf grep mkdir pwd readlink rm tail tee tr wc; do
  link_tool "${LTool}"
done

ln -s "${REAL_PYTHON3}" "${TOOL_BIN_DIR}/python3"

cat > "${TOOL_BIN_DIR}/uname" <<'EOF'
#!/usr/bin/env bash
echo "MSYS_NT-10.0"
EOF
chmod +x "${TOOL_BIN_DIR}/uname"

cat > "${FAKE_BIN_DIR}/fpc.exe" <<EOF
#!/usr/bin/env bash
set -euo pipefail

TRACE_LOG="${TRACE_LOG}"
printf '%s\n' "\$0 \$*" >> "\${TRACE_LOG}"

if [[ "\${1:-}" == "-iTP" ]]; then
  echo "x86_64"
  exit 0
fi

if [[ "\${1:-}" == "-iTO" ]]; then
  echo "win64"
  exit 0
fi

if [[ "\${1:-}" == "-iV" ]]; then
  echo "3.2.2"
  exit 0
fi

LOutFile=""
for LArg in "\$@"; do
  if [[ "\${LArg}" == -o* ]]; then
    LOutFile="\${LArg:2}"
  fi
done

if [[ -z "\${LOutFile}" ]]; then
  echo "missing -o output path" >&2
  exit 2
fi

mkdir -p "$(dirname "\${LOutFile}")"
cat > "\${LOutFile}" <<'INNER_EOF'
#!/usr/bin/env bash
set -euo pipefail

cat <<'REPORT'
Time:00.000 N:1 E:0 F:0 I:0
Number of run tests: 1
Number of errors: 0
Number of failures: 0
REPORT
INNER_EOF
chmod +x "\${LOutFile}"
exit 0
EOF
chmod +x "${FAKE_BIN_DIR}/fpc.exe"

PATH_PREFIX="${FAKE_BIN_DIR}:${TOOL_BIN_DIR}"
SUCCESS_OUT="${TMP_DIR}/success-out"

set +e
SUCCESS_OUTPUT="$(
  PATH="${PATH_PREFIX}" \
  SIMD_OUTPUT_ROOT="${SUCCESS_OUT}" \
  bash "${REPO_LINK_WITH_SPACES}/tests/fafafa.core.simd.intrinsics.experimental/BuildOrTest.sh" test-all 2>&1
)"
SUCCESS_RC=$?
set -e

if [[ ${SUCCESS_RC} -ne 0 ]]; then
  printf '%s\n' "${SUCCESS_OUTPUT}" >&2
  fail "experimental intrinsics runner should succeed when only fpc.exe is available in an MSYS-like shell"
fi

if ! printf '%s' "${SUCCESS_OUTPUT}" | rg -n "\[TEST-ALL\] Running default mode" >/dev/null; then
  printf '%s\n' "${SUCCESS_OUTPUT}" >&2
  fail "experimental intrinsics runner did not enter test-all default mode"
fi

if ! printf '%s' "${SUCCESS_OUTPUT}" | rg -n "\[TEST\] OK" >/dev/null; then
  printf '%s\n' "${SUCCESS_OUTPUT}" >&2
  fail "experimental intrinsics runner did not report TEST OK"
fi

if [[ ! -s "${TRACE_LOG}" ]]; then
  printf '%s\n' "${SUCCESS_OUTPUT}" >&2
  fail "fake fpc.exe was not invoked"
fi

SUCCESS_TRACE_LINES="$(wc -l < "${TRACE_LOG}")"
if [[ ! -x "${SUCCESS_OUT}/bin/fafafa.core.simd.intrinsics.experimental.test.exe" ]]; then
  printf '%s\n' "${SUCCESS_OUTPUT}" >&2
  fail "experimental intrinsics runner did not materialize the expected test binary"
fi

BAD_OUT="${TMP_DIR}/bad-out"
set +e
BAD_OUTPUT="$(
  PATH="${PATH_PREFIX}" \
  FPC_BIN="${TMP_DIR}/missing-fpc.exe" \
  SIMD_OUTPUT_ROOT="${BAD_OUT}" \
  bash "${REPO_LINK_WITH_SPACES}/tests/fafafa.core.simd.intrinsics.experimental/BuildOrTest.sh" build 2>&1
)"
BAD_RC=$?
set -e

if [[ ${BAD_RC} -eq 0 ]]; then
  printf '%s\n' "${BAD_OUTPUT}" >&2
  fail "experimental intrinsics runner must fail closed when explicit FPC_BIN is invalid"
fi

if ! printf '%s' "${BAD_OUTPUT}" | rg -n "requested FPC compiler not found" >/dev/null; then
  printf '%s\n' "${BAD_OUTPUT}" >&2
  fail "experimental intrinsics runner did not explain the invalid explicit FPC_BIN failure"
fi

BAD_TRACE_LINES="$(wc -l < "${TRACE_LOG}")"
if [[ "${BAD_TRACE_LINES}" != "${SUCCESS_TRACE_LINES}" ]]; then
  printf '%s\n' "${BAD_OUTPUT}" >&2
  fail "experimental intrinsics runner fell back to fake fpc.exe after an invalid explicit FPC_BIN"
fi

echo "[PASS] windows SIMD experimental intrinsics FPC resolution verified"
