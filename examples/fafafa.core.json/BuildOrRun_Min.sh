#!/usr/bin/env bash
# JSON Pointer 注意：空指针 "" 返回根；单独 "/" 与双斜杠空 token（如 "/a//x"）非法返回 nil；~0→~，~1→/
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$SCRIPT_DIR/bin"
LIB_DIR="$SCRIPT_DIR/lib"
LAZBUILD="${LAZBUILD:-lazbuild}"

mkdir -p "$BIN_DIR" "$LIB_DIR"

echo "Building minimal examples with lazbuild..."
for p in example_reader_flags.lpi example_stop_when_done.lpi; do
  echo "  $p"
  echo "[BUILD] $p"; "$LAZBUILD" "$SCRIPT_DIR/$p" --bm=Debug --ws=nogui || { echo "[BUILD] FAILED $p"; exit 1; }
done

echo "Running minimal examples..."
"$BIN_DIR/example_reader_flags" || { echo "[RUN] FAILED example_reader_flags"; exit 1; }
"$BIN_DIR/example_stop_when_done" || { echo "[RUN] FAILED example_stop_when_done"; exit 1; }

echo "Done."

