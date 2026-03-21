#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
DEFAULT_LOG_PATH="${ROOT}/logs/windows_b07_gate.log"
DEFAULT_OUT_PATH="${ROOT}/logs/windows_b07_closeout_summary.md"
LOG_PATH=""
OUT_PATH=""
VERIFIER="${ROOT}/verify_windows_b07_evidence.sh"
ALLOW_SIMULATED=0
CHECK_LOG_PATH=""

print_usage() {
  echo "Usage: $0 [evidence-log-path] [summary-output-path] [--allow-simulated]"
  echo "Default log: ${ROOT}/logs/windows_b07_gate.log"
  echo "Default summary: ${ROOT}/logs/windows_b07_closeout_summary.md"
  echo "--allow-simulated: allow simulated evidence for dryrun/rehearsal only"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      print_usage
      exit 0
      ;;
    --allow-simulated)
      ALLOW_SIMULATED=1
      shift
      ;;
    *)
      if [[ -z "${LOG_PATH}" ]]; then
        LOG_PATH="$1"
      elif [[ -z "${OUT_PATH}" ]]; then
        OUT_PATH="$1"
      else
        echo "[CLOSEOUT] Unexpected argument: $1"
        exit 2
      fi
      shift
      ;;
  esac
done

if [[ -z "${LOG_PATH}" ]]; then
  LOG_PATH="${DEFAULT_LOG_PATH}"
fi
if [[ -z "${OUT_PATH}" ]]; then
  OUT_PATH="${DEFAULT_OUT_PATH}"
fi

if [[ ! -f "${LOG_PATH}" ]]; then
  echo "[CLOSEOUT] Missing log: ${LOG_PATH}"
  exit 2
fi

if [[ ! -x "${VERIFIER}" ]]; then
  echo "[CLOSEOUT] Missing verifier: ${VERIFIER}"
  exit 2
fi

CHECK_LOG_PATH="$(mktemp)"
cleanup() {
  if [[ -n "${CHECK_LOG_PATH}" && -f "${CHECK_LOG_PATH}" ]]; then
    rm -f "${CHECK_LOG_PATH}"
  fi
}
trap cleanup EXIT
tr -d '\r' < "${LOG_PATH}" > "${CHECK_LOG_PATH}"

extract_last_line() {
  local aRegex
  local aFile

  aRegex="$1"
  aFile="$2"
  grep -E -- "${aRegex}" "${aFile}" | tail -n 1 | sed -E 's/[[:space:]]+$//' || true
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
LVerifierCommand="bash tests/fafafa.core.simd/verify_windows_b07_evidence.sh \"${LOG_PATH}\""

set +e
if [[ "${ALLOW_SIMULATED}" == "1" ]]; then
  LVerifierOutput="$("${VERIFIER}" --allow-simulated "${LOG_PATH}" 2>&1)"
  LVerifierCommand="bash tests/fafafa.core.simd/verify_windows_b07_evidence.sh --allow-simulated \"${LOG_PATH}\""
else
  LVerifierOutput="$("${VERIFIER}" "${LOG_PATH}" 2>&1)"
fi
LVerifierRc=$?
set -e

if [[ "${LVerifierRc}" -ne 0 ]]; then
  LVerifierResult="FAIL (rc=${LVerifierRc})"
fi

LVerifierDetail="$(printf '%s' "${LVerifierOutput}" | tr '\n' ' ' | sed -E 's/[[:space:]]+/ /g' | sed -E 's/^[[:space:]]+|[[:space:]]+$//g')"
if [[ -z "${LVerifierDetail}" ]]; then
  LVerifierDetail="n/a"
fi

LStarted="$(extract_last_line '^\[B07\][[:space:]]+Started:' "${CHECK_LOG_PATH}")"
LGateRc="$(extract_last_line '^\[B07\][[:space:]]+GATE_EXIT_CODE=' "${CHECK_LOG_PATH}")"

LTotalLine="$(extract_last_line '^\[B07\][[:space:]]+Total:[[:space:]]+[0-9]+$' "${CHECK_LOG_PATH}")"
LPassedLine="$(extract_last_line '^\[B07\][[:space:]]+Passed:[[:space:]]+[0-9]+$' "${CHECK_LOG_PATH}")"
LFailedLine="$(extract_last_line '^\[B07\][[:space:]]+Failed:[[:space:]]+[0-9]+$' "${CHECK_LOG_PATH}")"

if [[ -z "${LTotalLine}" ]]; then
  LTotalLine="$(extract_last_line '^Total:[[:space:]]+[0-9]+$' "${CHECK_LOG_PATH}")"
fi
if [[ -z "${LPassedLine}" ]]; then
  LPassedLine="$(extract_last_line '^Passed:[[:space:]]+[0-9]+$' "${CHECK_LOG_PATH}")"
fi
if [[ -z "${LFailedLine}" ]]; then
  LFailedLine="$(extract_last_line '^Failed:[[:space:]]+[0-9]+$' "${CHECK_LOG_PATH}")"
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
- Command: ${LVerifierCommand}
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
