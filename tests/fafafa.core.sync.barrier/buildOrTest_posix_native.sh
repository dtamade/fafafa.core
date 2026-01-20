#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

# Build with POSIX native barrier enabled (Unix only)
mkdir -p bin lib

echo "Building with FAFAFA_SYNC_USE_POSIX_BARRIER enabled..."

# Use fpc directly with custom define
/home/dtamade/fpc/fpc/bin/x86_64-linux/fpc.sh -MObjFPC -Scghi -Cg -O1 -g -gl -l -vewnhibq \
  -dFAFAFA_SYNC_USE_POSIX_BARRIER \
  -Fu../../src -Fi../../src \
  -FUlib \
  -FE. \
  fafafa.core.sync.barrier.test.lpr
./fafafa.core.sync.barrier.test --all --progress

echo "POSIX native barrier test completed."
