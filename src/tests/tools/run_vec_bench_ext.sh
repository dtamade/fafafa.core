#!/usr/bin/env bash
set -euo pipefail

# Resolve repo root from this script (src/tests/tools)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
cd "${REPO_ROOT}"

mkdir -p bin report/benchmarks

# Build vec_bench_ext into bin
fpc src/tests/tools/vec_bench_ext.lpr \
  -B -FEbin \
  -Fusrc -Fusrc/tests -Fusrc/tests/lib -Fusrc/tests/lib/x86_64-win64 -Fusrc/plat -Fusrc/tests/tools \
  -O2 -S2 -MObjFPC \
  > build_vec_bench_ext.log 2>&1 || { echo "Build failed, see build_vec_bench_ext.log"; exit 1; }

N="${1:-1000000}"
CSV="report/benchmarks/vec_bench_ext_${N}.csv"

bin/vec_bench_ext --n="${N}" --aligned-elements=64 --cases=all --csv > "${CSV}" || {
  echo "Run failed, exit code $?" >> build_vec_bench_ext.log
  exit 1
}

echo "Report saved: ${CSV}"

