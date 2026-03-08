#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
LOG_DIR="${ROOT}/logs"
BATCH_ID="${1:-SIMD-$(date '+%Y%m%d')-152}"
FREEZE_JSON="${SIMD_FREEZE_STATUS_JSON_FILE:-${LOG_DIR}/freeze_status.json}"

if [[ $# -gt 0 ]]; then
  shift
fi

bash "${ROOT}/finalize_windows_b07_closeout.sh" --batch-id "${BATCH_ID}" "$@"

set +e
python3 "${ROOT}/evaluate_simd_freeze_status.py" --root "${ROOT}" --json-file "${FREEZE_JSON}"
LFreezeRC=$?
set -e

if [[ "${LFreezeRC}" != "0" ]]; then
  echo "[CLOSEOUT] Freeze status is not ready; skip apply"
  exit "${LFreezeRC}"
fi

bash "${ROOT}/apply_windows_b07_closeout_updates.sh" --apply --batch-id "${BATCH_ID}"
python3 "${ROOT}/evaluate_simd_freeze_status.py" --root "${ROOT}" --json-file "${FREEZE_JSON}"

echo "[CLOSEOUT] Windows B07 closeout finalized (batch=${BATCH_ID})"
