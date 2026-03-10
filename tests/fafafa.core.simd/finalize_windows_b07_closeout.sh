#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
LOG_PATH="${1:-${ROOT}/logs/windows_b07_gate.log}"
OUT_PATH="${2:-${ROOT}/logs/windows_b07_closeout_summary.md}"
VERIFIER="${ROOT}/verify_windows_b07_evidence.sh"

print_usage() {
  echo "Usage: $0 [evidence-log-path] [summary-output-path]"
  echo "Default log: ${ROOT}/logs/windows_b07_gate.log"
  echo "Default summary: ${ROOT}/logs/windows_b07_closeout_summary.md"
}

if [[ "${LOG_PATH}" == "-h" || "${LOG_PATH}" == "--help" ]]; then
  print_usage
  exit 0
fi

if [[ ! -f "${LOG_PATH}" ]]; then
  echo "[CLOSEOUT] Missing log: ${LOG_PATH}"
  exit 2
fi

if [[ ! -x "${VERIFIER}" ]]; then
  echo "[CLOSEOUT] Missing verifier: ${VERIFIER}"
  exit 2
fi

extract_last_line() {
  local aRegex
  local aFile

  aRegex="$1"
  aFile="$2"
  grep -E -- "${aRegex}" "${aFile}" | tail -n 1 || true
}

extract_metric_value() {
  local aLine

  aLine="$1"
  echo "${aLine}" | sed -E 's/.*:[[:space:]]*([0-9]+).*/\1/'
}

LVerifierRc=0
LVerifierOutput=""
LVerifierResult="PASS"
LVerifierDetail=""

set +e
LVerifierOutput="$("${VERIFIER}" "${LOG_PATH}" 2>&1)"
LVerifierRc=$?
set -e

if [[ "${LVerifierRc}" -ne 0 ]]; then
  LVerifierResult="FAIL (rc=${LVerifierRc})"
fi

LVerifierDetail="$(printf '%s' "${LVerifierOutput}" | tr '\n' ' ' | sed -E 's/[[:space:]]+/ /g' | sed -E 's/^[[:space:]]+|[[:space:]]+$//g')"
if [[ -z "${LVerifierDetail}" ]]; then
  LVerifierDetail="n/a"
fi

LStarted="$(extract_last_line '^\[B07\][[:space:]]+Started:' "${LOG_PATH}")"
LGateRc="$(extract_last_line '^\[B07\][[:space:]]+GATE_EXIT_CODE=' "${LOG_PATH}")"

LTotalLine="$(extract_last_line '^\[B07\][[:space:]]+Total:[[:space:]]+[0-9]+$' "${LOG_PATH}")"
LPassedLine="$(extract_last_line '^\[B07\][[:space:]]+Passed:[[:space:]]+[0-9]+$' "${LOG_PATH}")"
LFailedLine="$(extract_last_line '^\[B07\][[:space:]]+Failed:[[:space:]]+[0-9]+$' "${LOG_PATH}")"

if [[ -z "${LTotalLine}" ]]; then
  LTotalLine="$(extract_last_line '^Total:[[:space:]]+[0-9]+$' "${LOG_PATH}")"
fi
if [[ -z "${LPassedLine}" ]]; then
  LPassedLine="$(extract_last_line '^Passed:[[:space:]]+[0-9]+$' "${LOG_PATH}")"
fi
if [[ -z "${LFailedLine}" ]]; then
  LFailedLine="$(extract_last_line '^Failed:[[:space:]]+[0-9]+$' "${LOG_PATH}")"
fi

LTotal="$(extract_metric_value "${LTotalLine}")"
LPassed="$(extract_metric_value "${LPassedLine}")"
LFailed="$(extract_metric_value "${LFailedLine}")"

mkdir -p "$(dirname "${OUT_PATH}")"

cat > "${OUT_PATH}" <<EOM
# SIMD Windows B07 Closeout Summary

- Generated: $(date '+%Y-%m-%d %H:%M:%S %z')
- Evidence Log: ${LOG_PATH}
- ${LStarted:-[B07] Started: N/A}
- ${LGateRc:-[B07] GATE_EXIT_CODE=N/A}

## run_all Snapshot

- Total: ${LTotal:-N/A}
- Passed: ${LPassed:-N/A}
- Failed: ${LFailed:-N/A}

## Verification

- Verifier: ${VERIFIER}
- Command: bash tests/fafafa.core.simd/verify_windows_b07_evidence.sh "${LOG_PATH}"
- Result: ${LVerifierResult}
- Detail: ${LVerifierDetail}

## Next Doc Updates

- Update: docs/plans/2026-02-09-simd-unblock-closeout-roadmap.md
- Update: tests/fafafa.core.simd/docs/simd_completeness_matrix.md
- Update: progress.md
EOM

if [[ "${LVerifierRc}" -eq 0 ]]; then
  echo "[CLOSEOUT] OK: ${OUT_PATH}"
  exit 0
fi

echo "[CLOSEOUT] FAILED: verifier rc=${LVerifierRc} (summary updated: ${OUT_PATH})"
exit "${LVerifierRc}"
