#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

TARGETS=(
  "${ROOT}/tests/fafafa.core.fs/BuildOrRunPerf.sh"
  "${ROOT}/tests/fafafa.core.fs/ArchivePerfResult.sh"
  "${ROOT}/tests/fafafa.core.fs/BuildOrRunPerfAll.sh"
  "${ROOT}/tests/fafafa.core.fs/BuildOrRunResolvePerf.sh"
)

for LTarget in "${TARGETS[@]}"; do
  if ! bash -n "${LTarget}" >/dev/null; then
    echo "[FAIL] bash -n failed: ${LTarget}" >&2
    exit 1
  fi
done

echo "[PASS] fs perf shell runners are syntactically valid"
