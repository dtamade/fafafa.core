#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

TARGETS=(
  "${ROOT}/tests/cleanup_orphan_dirs.sh"
  "${ROOT}/tests/run_leak_tests.sh"
  "${ROOT}/tests/lint_math_facade.sh"
  "${ROOT}/tests/fafafa.core.benchmark/buildOrTest.sh"
  "${ROOT}/tests/fafafa.core.crypto.examples_smoke/BuildOrRun.sh"
  "${ROOT}/tests/fafafa.core.lockfree/BuildAndTest.sh"
  "${ROOT}/tests/fafafa.core.os/plays_no_proc.sh"
  "${ROOT}/tests/fafafa.core.process/buildOrTest.sh"
  "${ROOT}/tests/fafafa.core.process/run_spawn_groups_subset.sh"
  "${ROOT}/tests/fafafa.core.process/run_spawn_subset.sh"
  "${ROOT}/tests/fafafa.core.socket/perf.sh"
  "${ROOT}/tests/fafafa.core.socket/smoke.sh"
  "${ROOT}/tests/fafafa.core.term/benchmarks/build_benchmarks.sh"
  "${ROOT}/tests/fafafa.core.term/integration/build_integration_tests.sh"
  "${ROOT}/tests/fafafa.core.term/integration/run_tests.sh"
  "${ROOT}/tests/fafafa.core.test.min/BuildOrRun.sh"
)

for LTarget in "${TARGETS[@]}"; do
  if ! bash -n "${LTarget}" >/dev/null; then
    echo "[FAIL] bash -n failed: ${LTarget}" >&2
    exit 1
  fi
done

echo "[PASS] active test-side shell runners are syntactically valid"
