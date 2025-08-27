#!/usr/bin/env bash
set -euo pipefail

# Jump to repo root (this script is under src/tests)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
cd "${REPO_ROOT}"

mkdir -p bin report/benchmarks

# Build and run tests (output to bin)
fpc src/tests/run_tests.lpr \
  -B -FEbin \
  -Fusrc -Fusrc/tests -Fusrc/tests/lib -Fusrc/tests/lib/x86_64-linux -Fusrc/plat -Fusrc/tests/tools \
  -O2 -S2 -MObjFPC \
  -dFAFAFA_CORE_INLINE -dFAFAFA_COLLECTIONS_INLINE -dFAFAFA_ENABLE_TOML_TESTS \
  > build_run_tests.log 2>&1 || { echo "Build tests failed, see build_run_tests.log"; exit 1; }

bin/run_tests --all --format=plain > src/tests/tests_all_output.txt 2>&1 || {
  echo "Tests run finished with non-zero exit code. See src/tests/tests_all_output.txt"
}

echo "Tests OK. See src/tests/tests_all_output.txt"

# Build and run vec bench (extended)
bash src/tests/tools/run_vec_bench_ext.sh 1000000 || {
  echo "vec_bench_ext run failed, exit code $?" >> build_vec_bench_ext.log
  exit 1
}

echo "All done. Outputs:"
echo "  - tests: src/tests/tests_all_output.txt"
echo "  - bench: report/benchmarks/vec_bench_ext_1000000.csv"
