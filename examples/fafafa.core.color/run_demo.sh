#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
LAZBUILD_BIN="${LAZBUILD:-lazbuild}"
PROJECT="examples/fafafa.core.color/palette_demo.lpi"
LOG="examples/fafafa.core.color/palette_demo.log"

cd "${ROOT_DIR}"

if ! command -v "${LAZBUILD_BIN}" >/dev/null 2>&1; then
  echo "[run_demo] lazbuild not found: ${LAZBUILD_BIN}" >&2
  exit 1
fi

echo "[BUILD] lazbuild ${PROJECT} (project default mode)"
"${LAZBUILD_BIN}" "${PROJECT}"

BIN="bin/palette_demo"
if [[ -x "${BIN}.exe" ]]; then
  BIN="${BIN}.exe"
fi

if [[ ! -x "${BIN}" ]]; then
  echo "[run_demo] Binary not found after build: ${BIN}(.exe)" >&2
  exit 1
fi

echo "[RUN] ${BIN}"
"${BIN}" | tee "${LOG}"
echo "[run_demo] Log written to ${LOG}"
