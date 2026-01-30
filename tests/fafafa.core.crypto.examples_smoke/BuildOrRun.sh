#!/usr/bin/env bash
set -euo pipefail
# Build and run minimal crypto smoke tests (non-CI)

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT_DIR"

# Try lazbuild then fallback to fpc
if command -v lazbuild >/dev/null 2>&1; then
  lazbuild --bm=Release tests/fafafa.core.crypto.examples_smoke/tests_crypto_smoke.lpi || true
else
  echo "[INFO] lazbuild not found, using fpc fallback"
fi

if [[ ! -f tests/fafafa.core.crypto.examples_smoke/bin/tests_crypto_smoke ]]; then
  fpc -Mobjfpc -Scghi -Fu"src" -Fi"src" -FE"tests/fafafa.core.crypto.examples_smoke/bin" tests/fafafa.core.crypto.examples_smoke/smoke_runner.lpr
fi

# Run
if [[ -f tests/fafafa.core.crypto.examples_smoke/bin/tests_crypto_smoke ]]; then
  tests/fafafa.core.crypto.examples_smoke/bin/tests_crypto_smoke
else
  tests/fafafa.core.crypto.examples_smoke/bin/tests_crypto_smoke.exe
fi

