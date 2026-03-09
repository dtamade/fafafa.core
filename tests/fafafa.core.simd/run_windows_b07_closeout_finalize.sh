#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
FINALIZE_SCRIPT="${ROOT}/finalize_windows_b07_closeout.sh"
APPLY_SCRIPT="${ROOT}/apply_windows_b07_closeout_updates.sh"
FREEZE_SCRIPT="${ROOT}/evaluate_simd_freeze_status.py"

LBATCH_ID="${1:-SIMD-$(date '+%Y%m%d')-152}"
LEVIDENCE_LOG="${SIMD_WIN_EVIDENCE_LOG_FILE:-${ROOT}/logs/windows_b07_gate.log}"
LSUMMARY_FILE="${SIMD_WIN_CLOSEOUT_SUMMARY_FILE:-${ROOT}/logs/windows_b07_closeout_summary.md}"
LSKIP_FREEZE="${SIMD_WIN_CLOSEOUT_SKIP_FREEZE:-0}"
LALLOW_SIMULATED="${SIMD_WIN_CLOSEOUT_ALLOW_SIMULATED:-0}"
LTARGET_ROOT="${SIMD_WIN_CLOSEOUT_TARGET_ROOT:-}"
LFREEZE_JSON="${SIMD_WIN_FREEZE_STATUS_JSON_FILE:-${ROOT}/logs/freeze_status.json}"
LBATCH_DIR="${SIMD_WIN_CLOSEOUT_BATCH_DIR:-}"

if [[ ! -x "${FINALIZE_SCRIPT}" ]]; then
  echo "[CLOSEOUT] Missing finalize script: ${FINALIZE_SCRIPT}"
  exit 2
fi

if [[ ! -x "${APPLY_SCRIPT}" ]]; then
  echo "[CLOSEOUT] Missing apply script: ${APPLY_SCRIPT}"
  exit 2
fi

if [[ ! -f "${FREEZE_SCRIPT}" ]]; then
  echo "[CLOSEOUT] Missing freeze status script: ${FREEZE_SCRIPT}"
  exit 2
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "[CLOSEOUT] Missing python3"
  exit 2
fi

echo "[CLOSEOUT] batch=${LBATCH_ID}"
echo "[CLOSEOUT] finalize: log=${LEVIDENCE_LOG}, summary=${LSUMMARY_FILE}"
"${FINALIZE_SCRIPT}" "${LEVIDENCE_LOG}" "${LSUMMARY_FILE}"

if [[ -n "${LBATCH_DIR}" ]]; then
  mkdir -p "${LBATCH_DIR}"
  if [[ -f "${LEVIDENCE_LOG}" ]]; then
    cp "${LEVIDENCE_LOG}" "${LBATCH_DIR}/windows_b07_gate.log"
  fi
  if [[ -f "${ROOT}/logs/gate_summary.md" ]]; then
    cp "${ROOT}/logs/gate_summary.md" "${LBATCH_DIR}/gate_summary.md"
  fi
  if [[ -f "${ROOT}/logs/gate_summary.json" ]]; then
    cp "${ROOT}/logs/gate_summary.json" "${LBATCH_DIR}/gate_summary.json"
  fi
fi

if [[ "${LSKIP_FREEZE}" != "0" ]]; then
  echo "[CLOSEOUT] SKIP freeze+apply (SIMD_WIN_CLOSEOUT_SKIP_FREEZE=${LSKIP_FREEZE})"
  echo "[CLOSEOUT] Note: doc updates require freeze PASS and are intentionally blocked in skip mode."
  exit 0
fi

echo "[CLOSEOUT] freeze-status"
SIMD_FREEZE_WINDOWS_LOG_FILE="${LEVIDENCE_LOG}" \
SIMD_FREEZE_WINDOWS_CLOSEOUT_SUMMARY_FILE="${LSUMMARY_FILE}" \
python3 "${FREEZE_SCRIPT}" --root "${ROOT}" --json-file "${LFREEZE_JSON}"

if [[ -n "${LBATCH_DIR}" && -f "${LFREEZE_JSON}" ]]; then
  cp "${LFREEZE_JSON}" "${LBATCH_DIR}/freeze_status.json"
fi

LAPPLY_ARGS=("${LSUMMARY_FILE}" "--apply" "--batch-id" "${LBATCH_ID}" "--freeze-json" "${LFREEZE_JSON}")
if [[ "${LALLOW_SIMULATED}" != "0" ]]; then
  LAPPLY_ARGS+=("--allow-simulated")
fi
if [[ -n "${LTARGET_ROOT}" ]]; then
  LAPPLY_ARGS+=("--target-root" "${LTARGET_ROOT}")
fi

echo "[CLOSEOUT] apply-after-freeze: ${APPLY_SCRIPT} ${LAPPLY_ARGS[*]}"
"${APPLY_SCRIPT}" "${LAPPLY_ARGS[@]}"

if [[ "${LSUMMARY_FILE}" != "${ROOT}/logs/windows_b07_closeout_summary.md" && -f "${LSUMMARY_FILE}" ]]; then
  cp "${LSUMMARY_FILE}" "${ROOT}/logs/windows_b07_closeout_summary.md"
fi

if [[ "${LFREEZE_JSON}" != "${ROOT}/logs/freeze_status.json" && -f "${LFREEZE_JSON}" ]]; then
  cp "${LFREEZE_JSON}" "${ROOT}/logs/freeze_status.json"
fi
