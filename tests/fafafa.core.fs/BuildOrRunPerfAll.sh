#!/usr/bin/env bash
set -euo pipefail

# Aggregate: run resolve and walk perf; write combined summary
ROOT="${1:-tests/fafafa.core.fs/walk_bench_root}"
ITERS="${2:-2000}"
DEPTH=3
FANOUT=4
FILES=2

# Run resolve perf
bash tests/fafafa.core.fs/BuildOrRunResolvePerf.sh "$ROOT" "$ITERS"

# Build and run walk perf (perf_walk_bench)
EXE=tests/fafafa.core.fs/bin/perf_walk_bench
if [[ ! -x "$EXE" ]]; then
  fpc tests/fafafa.core.fs/perf_walk_bench.lpr >/dev/null 2>&1 || true
fi
"$EXE" "$ROOT" genwalk "$DEPTH" "$FANOUT" "$FILES" >/dev/null 2>&1 || true
"$EXE" "$ROOT" walk "$DEPTH" "$FANOUT" "$FILES" >/dev/null 2>&1 || true

OUTDIR=tests/fafafa.core.fs/performance-data
OUT1="$OUTDIR/perf_resolve_latest.txt"
OUT2="$OUTDIR/perf_walk_latest.txt"
ALL="$OUTDIR/perf_all_latest.txt"
mkdir -p "$OUTDIR"

echo "==== ResolvePathEx ==== " > "$ALL"
if [[ -f "$OUT1" ]]; then cat "$OUT1" >> "$ALL"; fi
echo >> "$ALL"
echo "==== Walk ==== " >> "$ALL"
if [[ -f "$OUT2" ]]; then cat "$OUT2" >> "$ALL"; fi

echo "Output file: $ALL"
grep -E "^CSV," "$ALL" || true

