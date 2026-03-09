#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
LOG_DIR="${ROOT}/logs"
SUMMARY_FILE="${SIMD_GATE_SUMMARY_FILE:-${LOG_DIR}/gate_summary.md}"
BACKUP_DIR="${LOG_DIR}/rehearsal/backups"
INJECT_DIR="${LOG_DIR}/rehearsal/injected"
SCENARIO="${1:-mixed}"
SAMPLE_OUTPUT="${2:-${INJECT_DIR}/gate_summary.injected.${SCENARIO}.md}"
WARN_MS="${SIMD_GATE_STEP_WARN_MS:-20000}"
FAIL_MS="${SIMD_GATE_STEP_FAIL_MS:-120000}"

mkdir -p "${BACKUP_DIR}" "${INJECT_DIR}"
python3 "${ROOT}/generate_gate_summary_sample.py" --scenario "${SCENARIO}" --warn-ms "${WARN_MS}" --fail-ms "${FAIL_MS}" --output "${SAMPLE_OUTPUT}"

if [[ "${SIMD_GATE_SUMMARY_APPLY:-0}" == "1" ]]; then
  LStamp="$(date '+%Y%m%d-%H%M%S')"
  LBackup="${BACKUP_DIR}/gate_summary.backup.${LStamp}.md"
  if [[ -f "${SUMMARY_FILE}" ]]; then
    cp "${SUMMARY_FILE}" "${LBackup}"
    echo "[GATE-SUMMARY-INJECT] backup=${LBackup}"
  fi
  cp "${SAMPLE_OUTPUT}" "${SUMMARY_FILE}"
  echo "[GATE-SUMMARY-INJECT] applied target=${SUMMARY_FILE}"
else
  echo "[GATE-SUMMARY-INJECT] non-invasive mode (set SIMD_GATE_SUMMARY_APPLY=1 to replace target)"
fi

echo "[GATE-SUMMARY-INJECT] sample=${SAMPLE_OUTPUT}"
