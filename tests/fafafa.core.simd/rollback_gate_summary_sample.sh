#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
LOG_DIR="${ROOT}/logs"
SUMMARY_FILE="${SIMD_GATE_SUMMARY_FILE:-${LOG_DIR}/gate_summary.md}"
BACKUP_DIR="${LOG_DIR}/rehearsal/backups"
RESTORE_FILE="${SIMD_GATE_SUMMARY_BACKUP_FILE:-}"

if [[ -z "${RESTORE_FILE}" ]]; then
  RESTORE_FILE="$(find "${BACKUP_DIR}" -maxdepth 1 -type f -name 'gate_summary.backup.*.md' | sort -r | head -n 1 || true)"
fi

if [[ -z "${RESTORE_FILE}" ]]; then
  echo "[GATE-SUMMARY-ROLLBACK] No backup found"
  exit 2
fi

if [[ ! -f "${RESTORE_FILE}" ]]; then
  echo "[GATE-SUMMARY-ROLLBACK] Backup not found: ${RESTORE_FILE}"
  exit 2
fi

cp "${RESTORE_FILE}" "${SUMMARY_FILE}"
echo "[GATE-SUMMARY-ROLLBACK] restored=${SUMMARY_FILE} from=${RESTORE_FILE}"
