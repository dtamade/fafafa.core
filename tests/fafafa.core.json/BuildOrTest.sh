#!/usr/bin/env bash
set -euo pipefail

ACTION="${1:-build}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT="${SCRIPT_DIR}/tests_json.lpi"
TEST_EXECUTABLE="${SCRIPT_DIR}/bin/tests_json"
TOOLS_LAZBUILD="${SCRIPT_DIR}/../../tools/lazbuild.sh"

cd "${SCRIPT_DIR}"

LAZBUILD_BIN="${LAZBUILD:-}"
if [[ -z "${LAZBUILD_BIN}" ]]; then
  if [[ -x "${TOOLS_LAZBUILD}" ]]; then
    LAZBUILD_BIN="${TOOLS_LAZBUILD}"
  else
    echo "[WARN] tools/lazbuild.sh not found or not executable, falling back to lazbuild in PATH"
    LAZBUILD_BIN="lazbuild"
  fi
fi

build_project() {
  echo "[BUILD] Project: ${PROJECT}"
  if "${LAZBUILD_BIN}" "${PROJECT}"; then
    echo "[BUILD] OK"
  else
    local LExitCode=$?
    echo "[BUILD] FAILED code=${LExitCode}"
    return "${LExitCode}"
  fi
}

run_tests() {
  local LRunBin=""

  if [[ -x "${TEST_EXECUTABLE}" ]]; then
    LRunBin="${TEST_EXECUTABLE}"
  elif [[ -x "${TEST_EXECUTABLE}.exe" ]]; then
    LRunBin="${TEST_EXECUTABLE}.exe"
  else
    echo "[ERROR] Test executable not found: ${TEST_EXECUTABLE}[.exe]"
    return 2
  fi

  echo "[TEST] Running: ${LRunBin}"
  "${LRunBin}" --all --format=plain
}

case "${ACTION}" in
  build)
    build_project
    ;;
  test)
    build_project
    run_tests
    ;;
  *)
    echo "Usage: $0 [build|test]"
    exit 2
    ;;
esac
