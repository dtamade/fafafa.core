#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

# Build and run TreeSet tests
mkdir -p bin lib
if command -v lazbuild >/dev/null 2>&1; then
  lazbuild -B tests_treeSet.lpi
  ./tests_treeSet || true
else
  echo "lazbuild not found. Please install Lazarus or add fpcunit path manually."
  exit 1
fi
