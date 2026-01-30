#!/usr/bin/env bash
set -euo pipefail

BENCH_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$BENCH_DIR/../.."

mkdir -p "$BENCH_DIR/bin" "$BENCH_DIR/lib"

fpc -Mobjfpc -Sh -O2 \
  -Fu"$ROOT_DIR/src" \
  -FE"$BENCH_DIR/bin" \
  -FU"$BENCH_DIR/lib" \
  "$BENCH_DIR/bench_blockpool.lpr"

"$BENCH_DIR/bin/bench_blockpool" "$@"

