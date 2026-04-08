#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

ACTION="${1:-run}"
LAZBUILD_BIN="${LAZBUILD:-lazbuild}"
PROJECT="example_cond_vs_event"

if [[ "${ACTION}" != "build" && "${ACTION}" != "run" ]]; then
  echo "[ERROR] Unsupported action: ${ACTION}" >&2
  echo "Usage: $(basename "$0") [build|run]" >&2
  exit 2
fi

if ! command -v "${LAZBUILD_BIN}" >/dev/null 2>&1; then
  echo "[ERROR] lazbuild not found in PATH" >&2
  exit 1
fi

echo "[BUILD] ${LAZBUILD_BIN} ${PROJECT}.lpi (project default mode)"
"${LAZBUILD_BIN}" "${PROJECT}.lpi"

if [[ "${ACTION}" == "build" ]]; then
  echo "[INFO] Build-only mode."
  exit 0
fi

if [[ -x "../bin/${PROJECT}" ]]; then
  echo "[RUN] ../bin/${PROJECT}"
  "../bin/${PROJECT}"
elif [[ -x "../bin/${PROJECT}.exe" ]]; then
  echo "[RUN] ../bin/${PROJECT}.exe"
  "../bin/${PROJECT}.exe"
else
  echo "[ERROR] Executable not found: ../bin/${PROJECT}[.exe]" >&2
  exit 100
fi
