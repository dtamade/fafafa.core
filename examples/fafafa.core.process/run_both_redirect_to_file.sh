#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p bin
fpc -MObjFPC -Scaghi -gl -Fu../../src -Fi../../src -FEbin example_both_redirect_to_file.pas
./bin/example_both_redirect_to_file || true

