#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

BASE="examples/fafafa.core.sync.condvar"

if find "${BASE}" -type f -name 'buildOrTest.bat' | grep -q .; then
  echo "[FAIL] stale lowercase condvar example runner alias still exists"
  find "${BASE}" -type f -name 'buildOrTest.bat' | sort
  exit 1
fi

for dir in \
  "${BASE}/barrier" \
  "${BASE}/cond_vs_event" \
  "${BASE}/mpmc_queue" \
  "${BASE}/producer_consumer" \
  "${BASE}/robust_wait" \
  "${BASE}/timeout" \
  "${BASE}/wait_notify"
do
  [[ -f "${dir}/BuildOrRun.bat" ]] || { echo "[FAIL] missing ${dir}/BuildOrRun.bat"; exit 1; }
  [[ -f "${dir}/BuildOrRun.sh" ]] || { echo "[FAIL] missing ${dir}/BuildOrRun.sh"; exit 1; }
done

echo "[PASS] L0 sync condvar example runners are aligned with current entrypoint hygiene"
