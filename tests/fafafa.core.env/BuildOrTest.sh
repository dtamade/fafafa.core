#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT="${SCRIPT_DIR}/fafafa.core.env.test.lpi"
BIN="${SCRIPT_DIR}/bin"
LIB="${SCRIPT_DIR}/lib"
TEST_EXE="${BIN}/fafafa.core.env.test"
ACTION="${1:-test}"

# Resolve lazbuild: prefer LAZBUILD_EXE, else lazbuild from PATH
LAZBUILD_EXE_PATH="${LAZBUILD_EXE:-}"
if [[ -z "${LAZBUILD_EXE_PATH}" ]]; then
  if command -v lazbuild >/dev/null 2>&1; then
    LAZBUILD_EXE_PATH="$(command -v lazbuild)"
  else
    echo "[ERROR] lazbuild not found. Please install Lazarus/FPC and ensure 'lazbuild' is in PATH, or set LAZBUILD_EXE=/path/to/lazbuild" >&2
    exit 2
  fi
fi

# Clean outputs (keep runs deterministic)
rm -rf "${BIN}" "${LIB}"
mkdir -p "${BIN}" "${LIB}"

echo "[BUILD] ${PROJECT} (Debug)"
"${LAZBUILD_EXE_PATH}" --build-mode=Debug "${PROJECT}"

echo

if [[ "${ACTION}" == "build" ]]; then
  echo "[BUILD] OK (build-only)"
  exit 0
fi

# Default: test
if [[ ! -x "${TEST_EXE}" ]]; then
  echo "[ERROR] Test executable not found: ${TEST_EXE}" >&2
  exit 100
fi

echo "[TEST] ${TEST_EXE} --all --format=plainnotiming"
"${TEST_EXE}" --all --format=plainnotiming
