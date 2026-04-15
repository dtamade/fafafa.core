#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PERF_DIR="${SCRIPT_DIR}/performance-data"
RUN_SH="${SCRIPT_DIR}/BuildOrRunPerf.sh"

mkdir -p "${PERF_DIR}"

TS="$(date +%F_%H-%M-%S)"
TS_FILE="${PERF_DIR}/perf_resolve_${TS}.txt"
LATEST_FILE="${PERF_DIR}/perf_resolve_latest.txt"

bash "${RUN_SH}" resolve "$@"

[[ -f "${LATEST_FILE}" ]] || {
  echo "[FAIL] missing resolve perf latest output: ${LATEST_FILE}" >&2
  exit 1
}

cp -f "${LATEST_FILE}" "${TS_FILE}"

echo "Saved: ${TS_FILE}"
echo "Latest: ${LATEST_FILE}"
