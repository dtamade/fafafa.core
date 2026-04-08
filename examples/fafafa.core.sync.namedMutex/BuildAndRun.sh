#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAZBUILD_BIN="${LAZBUILD:-lazbuild}"
FPC_BIN="${FPC:-fpc}"

cd "${SCRIPT_DIR}"

shopt -s nullglob
PROJECTS=( *.lpi )
SOURCES=( *.lpr *.pas )

if (( ${#PROJECTS[@]} > 0 )); then
  if ! command -v "${LAZBUILD_BIN}" >/dev/null 2>&1; then
    echo "[BuildAndRun] lazbuild not found: ${LAZBUILD_BIN}" >&2
    exit 1
  fi

  for LProject in "${PROJECTS[@]}"; do
    echo "[BUILD] ${LAZBUILD_BIN} ${LProject} (project default mode)"
    "${LAZBUILD_BIN}" "${LProject}"
  done
elif (( ${#SOURCES[@]} > 0 )); then
  if ! command -v "${FPC_BIN}" >/dev/null 2>&1; then
    echo "[BuildAndRun] fpc not found: ${FPC_BIN}" >&2
    exit 1
  fi

  mkdir -p bin lib/fpc
  for LSource in "${SOURCES[@]}"; do
    LBase="${LSource%.*}"
    echo "[BUILD] ${FPC_BIN} ${LSource} -> bin/${LBase}"
    "${FPC_BIN}" -MObjFPC -Scghi -O1 -g -gl -l -vewnhibq \
      -Fu../../src -Fu. \
      -FUlib/fpc \
      -FEbin \
      -o"bin/${LBase}" \
      "${LSource}"
  done
else
  echo "[BuildAndRun] no .lpi project found" >&2
  exit 1
fi

echo "[RUN] Running example..."
for exe in bin/*; do
  if [ -x "$exe" ] && [ ! -d "$exe" ]; then
    echo "[RUN] $exe"
    "$exe"
  fi
done
