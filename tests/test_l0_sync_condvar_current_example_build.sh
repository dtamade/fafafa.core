#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

LOG_FILE="$(mktemp)"
trap 'rm -f "${LOG_FILE}"' EXIT

if ! bash examples/fafafa.core.sync.condvar/BuildOrRun.sh build >"${LOG_FILE}" 2>&1; then
  echo "[FAIL] condvar example suite no longer builds from current BuildOrRun entry"
  cat "${LOG_FILE}"
  exit 1
fi

echo "[PASS] condvar example suite current entry builds successfully"
