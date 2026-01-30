#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p bin
if command -v lazbuild >/dev/null 2>&1; then
  lazbuild example_pipeline_failfast.lpi
fi
fpc -MObjFPC -Scaghi -gl -Fu../../src -Fi../../src -FEbin example_redirect_file_and_capture_err.pas
./bin/example_redirect_file_and_capture_err || true

