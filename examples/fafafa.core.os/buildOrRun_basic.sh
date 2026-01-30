#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

# Build with lazbuild or fallback to fpc
if command -v lazbuild >/dev/null 2>&1; then
  lazbuild example_basic.lpi
else
  fpc -MObjFPC -Scghi -O1 -g -gl -vewnhibq -Fi. -Fi../../src -Fu../../src -o./bin/example_basic example_basic.pas
fi

./bin/example_basic

