#!/usr/bin/env bash
set -euo pipefail

THREADS=(1 2 4 8)
QUEUE_CAPS=(64 256 1024 -1)
TASK_MS=(0 1 2 5)
TASKS=50000
LOOPS=3
CSV="bench.csv"

lazbuild benchmarks/fafafa.core.thread/queue_bench.lpr

for t in "${THREADS[@]}"; do
  for q in "${QUEUE_CAPS[@]}"; do
    for m in "${TASK_MS[@]}"; do
      export BENCH_THREADS="$t"
      export BENCH_QUEUE_CAP="$q"
      export BENCH_TASKS="$TASKS"
      export BENCH_LOOPS="$LOOPS"
      export BENCH_TASK_MS="$m"
      export BENCH_CSV="$CSV"
      echo "Running t=$t q=$q ms=$m ..."
      ./benchmarks/fafafa.core.thread/queue_bench
    done
  done
done

