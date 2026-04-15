#!/usr/bin/env bash
# JSON Pointer 注意：空指针 "" 返回根；单独 "/" 与双斜杠空 token（如 "/a//x"）非法返回 nil；~0→~，~1→/
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$SCRIPT_DIR/bin"
LIB_DIR="$SCRIPT_DIR/lib"
LAZBUILD="${LAZBUILD:-lazbuild}"
ACTION="${1:-run}"

cleanup_outputs() {
  rm -rf "$BIN_DIR" "$LIB_DIR"
  find "$SCRIPT_DIR" -maxdepth 1 -type d -name 'lib\\*' -exec rm -rf {} +
  mkdir -p "$BIN_DIR" "$LIB_DIR"
}

build_examples() {
  local LProject

  cleanup_outputs
  cd "$SCRIPT_DIR"
  echo "Building minimal examples with lazbuild..."
  for LProject in example_reader_flags.lpi example_stop_when_done.lpi; do
    echo "  $LProject"
    echo "[BUILD] $LProject"
    "$LAZBUILD" "$SCRIPT_DIR/$LProject" --bm=Debug --ws=nogui || {
      echo "[BUILD] FAILED $LProject"
      exit 1
    }
  done
}

run_examples() {
  echo "Running minimal examples..."
  "$BIN_DIR/example_reader_flags" || {
    echo "[RUN] FAILED example_reader_flags"
    exit 1
  }
  "$BIN_DIR/example_stop_when_done" || {
    echo "[RUN] FAILED example_stop_when_done"
    exit 1
  }
  echo "Done."
}

case "${ACTION}" in
  build)
    build_examples
    ;;
  run)
    build_examples
    run_examples
    ;;
  *)
    echo "Usage: $0 [build|run]" >&2
    exit 2
    ;;
esac
