#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${SCRIPT_DIR}/../.."
SRC_DIR="${ROOT_DIR}/src"
LIB_DIR="${SCRIPT_DIR}/lib"
BIN_DIR="${SCRIPT_DIR}/bin"
EXE="${BIN_DIR}/perf_fs_bench"

mkdir -p "${LIB_DIR}" "${BIN_DIR}"

# Compiler options (similar to .bat)
FPC_OPTS=(-MObjFPC -Scghi -O2 -XX -CX -Si -vewnhibq)
FPC_PATHS=("-Fu${SRC_DIR}" "-FU${LIB_DIR}" "-FE${BIN_DIR}")

echo "[1/2] Compiling: perf_fs_bench.lpr ..."
( cd "${SCRIPT_DIR}" && fpc "${FPC_OPTS[@]}" "${FPC_PATHS[@]}" perf_fs_bench.lpr )

echo
echo "[OK] Build successful."

echo
echo "[2/2] Running benchmark..."
if [[ -x "${EXE}" ]]; then
  "${EXE}" "$@"
  RET=$?
  echo
  echo "Benchmark exited with code ${RET}"
  exit ${RET}
else
  echo "ERROR: Executable not found: ${EXE}"
  exit 2
fi

