#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
LOG_DIR="${ROOT}/logs"
VERIFY_SCRIPT="${ROOT}/verify_windows_b07_evidence.sh"
ROADMAP_DOC="$(cd "${ROOT}/../.." && pwd)/docs/plans/2026-02-09-simd-unblock-closeout-roadmap.md"
MATRIX_DOC="${ROOT}/docs/simd_completeness_matrix.md"
RC_DOC="${ROOT}/docs/simd_release_candidate_checklist.md"

LBatchId="SIMD-$(date '+%Y%m%d')-152"
LEvidenceLog="${SIMD_WIN_EVIDENCE_LOG_FILE:-${LOG_DIR}/windows_b07_gate.log}"
LExplicitLog=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --batch-id)
      shift
      LBatchId="${1:-${LBatchId}}"
      ;;
    --log)
      shift
      LEvidenceLog="${1:-${LEvidenceLog}}"
      LExplicitLog=1
      ;;
    -h|--help)
      cat <<USAGE
Usage: $0 [--batch-id SIMD-YYYYMMDD-152] [--log path/to/windows_b07_gate.log]
USAGE
      exit 0
      ;;
    *)
      if [[ "${LExplicitLog}" == "0" && -f "$1" ]]; then
        LEvidenceLog="$1"
        LExplicitLog=1
      else
        LBatchId="$1"
      fi
      ;;
  esac
  shift || true
done

if [[ ! -f "${LEvidenceLog}" ]]; then
  if [[ "${LExplicitLog}" == "0" && -f "${LOG_DIR}/windows_b07_gate.simulated.log" ]]; then
    LEvidenceLog="${LOG_DIR}/windows_b07_gate.simulated.log"
  else
    echo "[CLOSEOUT] Missing evidence log: ${LEvidenceLog}"
    exit 2
  fi
fi

LIsSimulated=0
if grep -Eq '^\[B07\][[:space:]]+Simulated:[[:space:]]+yes$' "${LEvidenceLog}"; then
  LIsSimulated=1
fi

if [[ "${LIsSimulated}" == "1" ]]; then
  LSummaryPath="${LOG_DIR}/windows_b07_closeout_summary.simulated.md"
else
  LSummaryPath="${LOG_DIR}/windows_b07_closeout_summary.md"
fi

extract_value() {
  local aPrefix
  local aDefault
  local LLine

  aPrefix="$1"
  aDefault="$2"
  LLine="$(grep -m1 -F "${aPrefix}" "${LEvidenceLog}" || true)"
  if [[ -z "${LLine}" ]]; then
    printf '%s' "${aDefault}"
    return 0
  fi
  if [[ "${LLine}" == "${aPrefix}"* ]]; then
    printf '%s' "${LLine:${#aPrefix}}"
  else
    printf '%s' "${LLine}"
  fi
}

LStarted="$(extract_value '[B07] Started: ' 'unknown')"
LGateExitCode="$(extract_value '[B07] GATE_EXIT_CODE=' 'unknown')"
LTotal="$(extract_value '[B07] Total: ' '0')"
LPassed="$(extract_value '[B07] Passed: ' '0')"
LFailed="$(extract_value '[B07] Failed: ' '0')"

LVerifyCommand="bash tests/fafafa.core.simd/verify_windows_b07_evidence.sh \"${LEvidenceLog}\""
set +e
LVerifyOutput="$(bash "${VERIFY_SCRIPT}" "${LEvidenceLog}" 2>&1)"
LVerifyRC=$?
set -e
LVerifyOutputOneLine="$(printf '%s' "${LVerifyOutput}" | tr '\n' ' ' | sed 's/[[:space:]]\+/ /g; s/[[:space:]]$//')"
if [[ "${LVerifyRC}" == "0" ]]; then
  LVerifyResult="PASS"
else
  LVerifyResult="FAIL (rc=${LVerifyRC})"
fi

mkdir -p "${LOG_DIR}"
cat > "${LSummaryPath}" <<EOM
# SIMD Windows B07 Closeout Summary

- Generated: $(date '+%Y-%m-%d %H:%M:%S %z')
- Batch Id: ${LBatchId}
- Evidence Log: ${LEvidenceLog}
- [B07] Started: ${LStarted}
- [B07] GATE_EXIT_CODE=${LGateExitCode}
$(if [[ "${LIsSimulated}" == "1" ]]; then printf '%s\n' '- [B07] Simulated: yes'; fi)

## run_all Snapshot

- Total: ${LTotal}
- Passed: ${LPassed}
- Failed: ${LFailed}

## Verification

- Verifier: ${VERIFY_SCRIPT}
- Command: ${LVerifyCommand}
- Result: ${LVerifyResult}
$(if [[ -n "${LVerifyOutputOneLine}" ]]; then printf '%s\n' "- Detail: ${LVerifyOutputOneLine}"; fi)

## Next Doc Updates

- Update: ${ROADMAP_DOC}
- Update: ${MATRIX_DOC}
- Update: ${RC_DOC}
EOM

echo "[CLOSEOUT] Summary updated: ${LSummaryPath}"
if [[ "${LVerifyRC}" != "0" ]]; then
  echo "[CLOSEOUT] Note: verifier currently fails for ${LEvidenceLog}; summary captured that state"
fi
