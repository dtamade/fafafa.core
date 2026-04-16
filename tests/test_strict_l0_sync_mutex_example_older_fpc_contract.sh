#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TARGET_FILE="${REPO_ROOT}/examples/fafafa.core.sync.mutex/example_advanced_patterns.lpr"

fail() {
  echo "[FAIL] $1" >&2
  exit 1
}

[[ -f "${TARGET_FILE}" ]] || fail "missing target file: ${TARGET_FILE}"

if rg -n 'CreateAnonymousThread\s*\(' "${TARGET_FILE}" >/dev/null; then
  fail "sync.mutex advanced example regressed to CreateAnonymousThread; keep explicit TThread subclasses here for older-FPC compatibility."
fi

rg -n 'TQueueProducerThread\s*=\s*class\(TThread\)' "${TARGET_FILE}" >/dev/null \
  || fail "missing TQueueProducerThread compatibility worker"
rg -n 'TQueueConsumerThread\s*=\s*class\(TThread\)' "${TARGET_FILE}" >/dev/null \
  || fail "missing TQueueConsumerThread compatibility worker"

echo "[PASS] strict L0 sync.mutex example stays on explicit thread classes for older-FPC compatibility"
