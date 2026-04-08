#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
EXAMPLE_DIR="${ROOT}/examples/fafafa.core.sync"
LAZBUILD_BIN="${LAZBUILD:-lazbuild}"

if ! command -v "${LAZBUILD_BIN}" >/dev/null 2>&1; then
  echo "[SKIP] lazbuild not found; cannot verify example_sync build"
  exit 0
fi

cd "${EXAMPLE_DIR}"
rm -f "${ROOT}/bin/example_sync" "${ROOT}/bin/example_sync.exe"

echo "[INFO] building example_sync.lpi with ${LAZBUILD_BIN}"
"${LAZBUILD_BIN}" example_sync.lpi >/tmp/fafafa-core-example-sync-build.log 2>&1 || {
  cat /tmp/fafafa-core-example-sync-build.log
  echo "[FAIL] example_sync.lpi failed to build" >&2
  exit 1
}

if [[ ! -x "${ROOT}/bin/example_sync" && ! -x "${ROOT}/bin/example_sync.exe" ]]; then
  echo "[FAIL] example_sync executable was not produced" >&2
  exit 1
fi

echo "[PASS] example_sync current entry builds successfully"
