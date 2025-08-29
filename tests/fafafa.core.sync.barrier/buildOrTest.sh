#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

# Prefer lazbuild if available to honor .lpi settings and unit paths
mkdir -p bin lib
if command -v lazbuild >/dev/null 2>&1; then
  lazbuild -B fafafa.core.sync.barrier.test.lpi
  ./fafafa.core.sync.barrier.test || true
else
  fpc -MObjFPC -Scghi -Cg -O1 -g -gl -l -vewnhibq \
    -Fu../../src -Fi../../src \
    -FUlib \
    -FE. \
    fafafa.core.sync.barrier.test.lpr
  ./fafafa.core.sync.barrier.test || true
fi

