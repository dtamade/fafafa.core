#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p bin
fpc -MObjFPC -Scaghi -gl -Fu../../src -Fi../../src -FEbin example_capture_stdout_redirect_err.pas
./bin/example_capture_stdout_redirect_err || true

