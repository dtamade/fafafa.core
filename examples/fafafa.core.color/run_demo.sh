#!/usr/bin/env bash
set -euo pipefail

# Build and run palette_demo, tee output to a log file (Unix)
# Usage: ./examples/fafafa.core.color/run_demo.sh

# Resolve repo root (this script lives in examples/fafafa.core.color)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
cd "${ROOT_DIR}"

# Find lazbuild
if command -v lazbuild >/dev/null 2>&1; then
  LAZBUILD="lazbuild"
else
  echo "[run_demo] lazbuild not found in PATH. Please install Lazarus FPC tools." >&2
  exit 1
fi

# Build
"${LAZBUILD}" --build-mode=Debug examples/fafafa.core.color/palette_demo.lpi

LOG="examples/fafafa.core.color/palette_demo.log"

# Locate binary (handle .exe or no extension)
BIN="bin/palette_demo"
if [[ -x "${BIN}.exe" ]]; then
  BIN="${BIN}.exe"
fi

if [[ ! -x "${BIN}" ]]; then
  echo "[run_demo] Binary not found after build: ${BIN}(.exe)" >&2
  exit 1
fi

# Run and tee
"${BIN}" | tee "${LOG}"
echo "[run_demo] Log written to ${LOG}"

