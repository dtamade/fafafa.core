#!/usr/bin/env bash
set -euo pipefail
# ResolvePathEx/realpath 性能评估（Linux/macOS）
# 用法：tests/fafafa.core.fs/BuildOrRunResolvePerf.sh [rootDir] [iterations]
# 默认 rootDir=tests/fafafa.core.fs/walk_bench_root, iterations=1000

ROOTDIR=${1:-tests/fafafa.core.fs/walk_bench_root}
ITERS=${2:-1000}

# 构建（复用现有 lazbuild 脚本）
./tests/fafafa.core.fs/BuildOrRunPerf.sh buildonly >/dev/null 2>&1 || true

# 构建 perf_resolve_bench（使用 fpc 或 lazbuild，按环境可选）
EXE2=tests/fafafa.core.fs/bin/perf_resolve_bench
if [[ ! -x "$EXE2" ]]; then
  fpc tests/fafafa.core.fs/perf_resolve_bench.lpr >/dev/null 2>&1 || true
fi
if [[ ! -x "$EXE2" ]]; then
  echo "[ERROR] perf_resolve_bench not found: $EXE2"
  exit 1
fi

EXE=tests/fafafa.core.fs/bin/perf_walk_bench
if [[ ! -x "$EXE" ]]; then
  echo "[ERROR] perf_walk_bench not found: $EXE"
  exit 1
fi

LOGDIR=tests/fafafa.core.fs/performance-data
mkdir -p "$LOGDIR"
OUT="$LOGDIR/perf_resolve_$(date +%F_%H-%M).txt"

"$EXE2" "$ROOTDIR" "$ITERS" > "$OUT"
echo >> "$OUT"
echo "==== Walk (genwalk) ==== " >> "$OUT"
"$EXE" "$ROOTDIR" genwalk 3 4 2 >> "$OUT"

echo "Wrote $OUT"

echo "Done."

