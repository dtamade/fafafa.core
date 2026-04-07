#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

run_and_capture() {
  local name="$1"
  local expect="$2"
  shift 2
  local output

  if ! output="$("$@" 2>&1)"; then
    echo "[FAIL] ${name} failed" >&2
    echo "${output}" >&2
    exit 1
  fi

  if [[ "${output}" != *"${expect}"* ]]; then
    echo "[FAIL] ${name} output missing expected marker: ${expect}" >&2
    echo "${output}" >&2
    exit 1
  fi
}

run_and_capture \
  "color palette demo" \
  "Strategy Deserialize t=0.2" \
  bash "${ROOT}/examples/fafafa.core.color/run_demo.sh"

run_and_capture \
  "collections benchmark" \
  "基准测试完成!" \
  bash "${ROOT}/benchmarks/fafafa.core.collections/run_simple_benchmark.sh"

echo "[PASS] L0 real smoke runners passed"
