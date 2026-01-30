#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

EXE=./quick_example

if [[ ! -x "$EXE" ]]; then
  echo "Building quick_example with fpc..."
  fpc -MObjFPC -Scaghi -O1 -vewnhibq -Fu"../../../src" quick_example.lpr
fi

echo "Running quick_example..."
"$EXE"

