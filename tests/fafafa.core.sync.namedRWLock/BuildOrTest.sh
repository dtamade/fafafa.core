#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

ACTION="${1:-test}"
PROJECT_LPI="${PROJECT_LPI:-fafafa.core.sync.namedRWLock.test.lpi}"
TEST_BIN="${TEST_BIN:-bin/fafafa.core.sync.namedRWLock.test}"

LAZBUILD_BIN="${LAZBUILD:-lazbuild}"

if ! command -v "${LAZBUILD_BIN}" >/dev/null 2>&1; then
  echo "[ERROR] lazbuild not found in PATH" >&2
  exit 1
fi

rm -rf ./bin ./lib/*-*/
mkdir -p ./bin ./lib

echo "[BUILD] ${LAZBUILD_BIN} ${PROJECT_LPI}"
"${LAZBUILD_BIN}" "${PROJECT_LPI}"

if [[ "${ACTION}" == "test" || "${ACTION}" == "run" ]]; then
  echo "[RUN] ${TEST_BIN}"
  if [[ -x "${TEST_BIN}" ]]; then
    "${TEST_BIN}" --all --format=plain
  elif [[ -x "${TEST_BIN}.exe" ]]; then
    "${TEST_BIN}.exe" --all --format=plain
  else
    echo "[ERROR] test executable not found: ${TEST_BIN}[.exe]" >&2
    exit 100
  fi
else
  echo "[INFO] build-only mode (${ACTION})"
fi
