#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
BACKUP_DIR="${ROOT}/logs/rehearsal/backups"

if [[ ! -d "${BACKUP_DIR}" ]]; then
  echo "[GATE-SUMMARY-BACKUPS] none"
  exit 0
fi

LFound=0
while IFS= read -r LFile; do
  if [[ -n "${LFile}" ]]; then
    if [[ "${LFound}" == "0" ]]; then
      echo "[GATE-SUMMARY-BACKUPS] dir=${BACKUP_DIR}"
      LFound=1
    fi
    basename "${LFile}"
  fi
done < <(find "${BACKUP_DIR}" -maxdepth 1 -type f -name 'gate_summary.backup.*.md' | sort -r)

if [[ "${LFound}" == "0" ]]; then
  echo "[GATE-SUMMARY-BACKUPS] none"
fi
