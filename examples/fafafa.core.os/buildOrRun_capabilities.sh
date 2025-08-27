#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

if command -v lazbuild >/dev/null 2>&1; then
  lazbuild example_capabilities.lpi
else
  fpc -MObjFPC -Scghi -O1 -g -gl -vewnhibq -Fi. -Fi../../src -Fu../../src -o./bin/example_capabilities example_capabilities.pas
fi

./bin/example_capabilities

