#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$SCRIPT_DIR/../.."
BIN_DIR="$SCRIPT_DIR/bin"
LIB_DIR="$SCRIPT_DIR/lib"

EX1="$SCRIPT_DIR/example_growth_object_based_min.lpr"
EX2="$SCRIPT_DIR/example_growth_interface_based_min.lpr"
EX3="$SCRIPT_DIR/example_growth_page_aligned_min.lpr"
EX4="$SCRIPT_DIR/example_growth_hugepage_aligned_min.lpr"
EX5="$SCRIPT_DIR/example_growth_page_aligned_portable_min.lpr"

FPC_OPTS=(-MObjFPC -Scghi -O1 -gl -gh -Xg -vewnhibq)
INCLUDE_OPTS=(-I"$ROOT_DIR/src" -Fu"$ROOT_DIR/src" -FU"$LIB_DIR" -FE"$BIN_DIR")

mkdir -p "$BIN_DIR" "$LIB_DIR"

build_example() {
  local src="$1"
  echo "[BUILD] $src"
  fpc "${FPC_OPTS[@]}" "${INCLUDE_OPTS[@]}" "$src"
}

run_example() {
  local exe="$1"
  echo "[RUN] $exe"
  set +e
  "$exe"
  local rc=$?
  set -e
  if [ $rc -ne 0 ]; then
    echo "[FAIL] $exe (exit $rc)"
    exit $rc
  fi
}

# Build
build_example "$EX1"
build_example "$EX2"
build_example "$EX3"
build_example "$EX4"
build_example "$EX5"

# Run
run_example "$BIN_DIR/example_growth_object_based_min"
run_example "$BIN_DIR/example_growth_interface_based_min"
run_example "$BIN_DIR/example_growth_page_aligned_min"
run_example "$BIN_DIR/example_growth_hugepage_aligned_min"
run_example "$BIN_DIR/example_growth_page_aligned_portable_min"

echo "[PASS] All examples OK"

