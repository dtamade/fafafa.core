#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LAZBUILD_BIN="${LAZBUILD:-lazbuild}"
RUNS="${SYNC_MUTEX_ADV_REPEAT:-10}"
LOG_FILE="$(mktemp)"
trap 'rm -f "${LOG_FILE}"' EXIT

if ! command -v "${LAZBUILD_BIN}" >/dev/null 2>&1; then
  echo "[SKIP] lazbuild not found; cannot verify sync.mutex current-entry default run"
  exit 0
fi

cd "${ROOT}"

if ! bash examples/fafafa.core.sync.mutex/BuildOrRun.sh build >"${LOG_FILE}" 2>&1; then
  echo "[FAIL] sync.mutex current-entry build failed unexpectedly"
  cat "${LOG_FILE}"
  exit 1
fi

for ((i = 1; i <= RUNS; i++)); do
  if ! examples/fafafa.core.sync.mutex/bin/example_advanced_patterns </dev/null >"${LOG_FILE}" 2>&1; then
    echo "[FAIL] sync.mutex advanced current-entry run failed on iteration ${i}"
    cat "${LOG_FILE}"
    exit 1
  fi

  if rg -n 'EZeroDivide|发生异常:' "${LOG_FILE}" >/dev/null; then
    echo "[FAIL] sync.mutex advanced current-entry run still reports a runtime exception on iteration ${i}"
    cat "${LOG_FILE}"
    exit 1
  fi
done

if ! examples/fafafa.core.sync.mutex/bin/example_basic_usage </dev/null >"${LOG_FILE}" 2>&1; then
  echo "[FAIL] sync.mutex basic current-entry run failed unexpectedly"
  cat "${LOG_FILE}"
  exit 1
fi

if rg -n '发生异常:' "${LOG_FILE}" >/dev/null; then
  echo "[FAIL] sync.mutex basic current-entry run still reports a runtime exception"
  cat "${LOG_FILE}"
  exit 1
fi

echo "[PASS] sync.mutex current-entry default run completes without runtime exceptions"
