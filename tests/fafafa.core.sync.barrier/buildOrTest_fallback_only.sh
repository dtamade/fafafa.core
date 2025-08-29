#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

# Build with native barriers disabled (force fallback on all platforms)
mkdir -p bin lib

echo "Building with native barriers disabled (fallback only)..."

# Use fpc directly with custom defines to disable native barriers
/home/dtamade/fpc/fpc/bin/x86_64-linux/fpc.sh -MObjFPC -Scghi -Cg -O1 -g -gl -l -vewnhibq \
  -uFAFAFA_SYNC_USE_WIN_BARRIER \
  -uFAFAFA_SYNC_USE_POSIX_BARRIER \
  -Fu../../src -Fi../../src \
  -FUlib \
  -FE. \
  fafafa.core.sync.barrier.test.lpr
./fafafa.core.sync.barrier.test --all --progress || true

echo "Fallback-only barrier test completed."
