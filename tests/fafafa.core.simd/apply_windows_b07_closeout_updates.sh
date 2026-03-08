#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${ROOT}/../.." && pwd)"
ROADMAP_DOC="${REPO_ROOT}/docs/plans/2026-02-09-simd-unblock-closeout-roadmap.md"
MATRIX_DOC="${ROOT}/docs/simd_completeness_matrix.md"
RC_DOC="${ROOT}/docs/simd_release_candidate_checklist.md"
SUMMARY_REAL="${ROOT}/logs/windows_b07_closeout_summary.md"
SUMMARY_SIM="${ROOT}/logs/windows_b07_closeout_summary.simulated.md"

LApply=0
LBatchId="SIMD-$(date '+%Y%m%d')-152"
LSummaryPath=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --apply)
      LApply=1
      ;;
    --batch-id)
      shift
      LBatchId="${1:-${LBatchId}}"
      ;;
    --summary)
      shift
      LSummaryPath="${1:-}"
      ;;
    -h|--help)
      cat <<USAGE
Usage: $0 [--apply] [--batch-id SIMD-YYYYMMDD-152] [--summary path/to/windows_b07_closeout_summary.md]
USAGE
      exit 0
      ;;
    *)
      LBatchId="$1"
      ;;
  esac
  shift || true
done

if [[ -z "${LSummaryPath}" ]]; then
  if [[ -f "${SUMMARY_REAL}" ]]; then
    LSummaryPath="${SUMMARY_REAL}"
  elif [[ -f "${SUMMARY_SIM}" ]]; then
    LSummaryPath="${SUMMARY_SIM}"
  fi
fi

if [[ -z "${LSummaryPath}" || ! -f "${LSummaryPath}" ]]; then
  echo "[CLOSEOUT] Missing closeout summary"
  exit 2
fi

LIsSimulated=0
if [[ "${LSummaryPath}" == *.simulated.md ]] || grep -Eq '^- \[B07\] Simulated:[[:space:]]+yes$' "${LSummaryPath}"; then
  LIsSimulated=1
fi

if [[ "${LApply}" == "0" ]]; then
  echo "[CLOSEOUT] Planned doc updates"
  echo "- ${ROADMAP_DOC}: mark Windows 实机证据"
  echo "- ${MATRIX_DOC}: mark Windows 实机证据已归档"
  echo "- ${RC_DOC}: mark Windows 实机证据日志已归档"
  echo "- batch-id=${LBatchId}"
  echo "- summary=${LSummaryPath}"
  if [[ "${LIsSimulated}" == "1" ]]; then
    echo "[CLOSEOUT] Note: simulated summary is preview-only and will be rejected by --apply"
  fi
  exit 0
fi

if [[ "${LIsSimulated}" == "1" ]]; then
  echo "[CLOSEOUT] Refuse to apply simulated summary: ${LSummaryPath}"
  exit 1
fi

python3 "${ROOT}/evaluate_simd_freeze_status.py" --root "${ROOT}" --json-file "${ROOT}/logs/freeze_status.json" >/dev/null

python3 - "${ROADMAP_DOC}" "${MATRIX_DOC}" "${RC_DOC}" "${LBatchId}" "${LSummaryPath}" <<'PY'
import sys
from pathlib import Path

roadmap = Path(sys.argv[1])
matrix = Path(sys.argv[2])
rc = Path(sys.argv[3])
batch = sys.argv[4]
summary = sys.argv[5]
summary_name = Path(summary).name

files = [
    (roadmap, "Windows 实机证据", f"- [x] Windows 实机证据（batch={batch}，summary={summary_name}）"),
    (matrix, "Windows 实机证据已归档", f"- [x] Windows 实机证据已归档（batch={batch}，summary={summary_name}）"),
    (rc, "Windows 实机证据日志已归档", f"- [x] Windows 实机证据日志已归档（batch={batch}，summary={summary_name}）"),
]

for path, needle, replacement in files:
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.exists():
        lines = path.read_text(encoding="utf-8", errors="ignore").splitlines()
    else:
        lines = []
    replaced = False
    new_lines = []
    for line in lines:
        if needle in line:
            new_lines.append(replacement)
            replaced = True
        else:
            new_lines.append(line)
    if not replaced:
        if new_lines and new_lines[-1] != "":
            new_lines.append("")
        new_lines.append(replacement)
    path.write_text("\n".join(new_lines) + "\n", encoding="utf-8")
PY

echo "[CLOSEOUT] Updated doc anchors with batch=${LBatchId}"
