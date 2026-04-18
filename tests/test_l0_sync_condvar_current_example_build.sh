#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EXAMPLE_DIR="${ROOT}/examples/fafafa.core.sync.condvar"
LAZBUILD_BIN="${LAZBUILD:-lazbuild}"

if ! command -v "${LAZBUILD_BIN}" >/dev/null 2>&1; then
  echo "[SKIP] lazbuild not found; cannot verify sync.condvar current-entry build"
  exit 0
fi

cd "${ROOT}"

LOG_FILE="$(mktemp)"
trap 'rm -f "${LOG_FILE}"' EXIT

if ! bash examples/fafafa.core.sync.condvar/BuildOrRun.sh build >"${LOG_FILE}" 2>&1; then
  echo "[FAIL] condvar example suite no longer builds from current BuildOrRun entry"
  cat "${LOG_FILE}"
  exit 1
fi

EXPECTED_BINS=(
  "example_multi_thread_coordination"
  "example_cond_vs_event"
  "example_mpmc_queue"
  "example_producer_consumer"
  "example_robust_wait"
  "example_timeout"
  "example_wait_notify"
)

for example_name in "${EXPECTED_BINS[@]}"; do
  if [[ ! -x "${EXAMPLE_DIR}/bin/${example_name}" && ! -x "${EXAMPLE_DIR}/bin/${example_name}.exe" ]]; then
    echo "[FAIL] missing expected condvar example binary: ${example_name}[.exe]"
    exit 1
  fi
done

echo "[PASS] condvar example suite current entry builds successfully"
