#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
LOG_PATH="${1:-${ROOT}/logs/windows_b07_gate.log}"
SUMMARY_JSON_PATH="${2:-}"
SUMMARY_JSON_VERIFIER="${ROOT}/verify_gate_summary_json.py"
CHECK_LOG_PATH=""

print_usage() {
  echo "Usage: $0 [evidence-log-path] [gate-summary-json-path]"
  echo "Default log: ${ROOT}/logs/windows_b07_gate.log"
  echo "Default gate summary json: <sibling gate_summary.json or [B07] GateSummaryJson marker>"
}

if [[ "${LOG_PATH}" == "-h" || "${LOG_PATH}" == "--help" ]]; then
  print_usage
  exit 0
fi

if [[ ! -f "${LOG_PATH}" ]]; then
  echo "[EVIDENCE] Missing log: ${LOG_PATH}"
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

trim_value() {
  echo "${1:-}" | sed -E 's/^[[:space:]]+|[[:space:]]+$//g'
}

check_fixed() {
  local aPattern

  aPattern="$1"
  if grep -F -- "${aPattern}" "${CHECK_LOG_PATH}" >/dev/null; then
    return 0
  fi

  echo "[EVIDENCE] Missing pattern: ${aPattern}"
  return 1
}

check_regex() {
  local aPattern

  aPattern="$1"
  if grep -E -- "${aPattern}" "${CHECK_LOG_PATH}" >/dev/null; then
    return 0
  fi

  echo "[EVIDENCE] Missing regex: ${aPattern}"
  return 1
}

extract_metric() {
  local aMetric
  local LLine

  aMetric="$1"
  LLine="$(grep -E -- "^\\[B07\\][[:space:]]+${aMetric}:[[:space:]]*[0-9]+$" "${CHECK_LOG_PATH}" | tail -n 1 || true)"
  if [[ -z "${LLine}" ]]; then
    LLine="$(grep -E -- "^${aMetric}:[[:space:]]*[0-9]+$" "${CHECK_LOG_PATH}" | tail -n 1 || true)"
  fi

  if [[ -z "${LLine}" ]]; then
    echo ""
    return 0
  fi

  echo "${LLine}" | sed -E 's/.*:[[:space:]]*([0-9]+)[[:space:]]*$/\1/'
}

extract_b07_value() {
  local aKey
  local LLine

  aKey="$1"
  LLine="$(grep -E -- "^\\[B07\\][[:space:]]+${aKey}:[[:space:]].*$" "${CHECK_LOG_PATH}" | tail -n 1 || true)"
  if [[ -z "${LLine}" ]]; then
    echo ""
    return 0
  fi

  echo "${LLine}" | sed -E "s/^\\[B07\\][[:space:]]+${aKey}:[[:space:]]*//"
}

resolve_summary_json_path() {
  local LFromLog

  if [[ -n "${SUMMARY_JSON_PATH}" ]]; then
    echo "${SUMMARY_JSON_PATH}"
    return 0
  fi

  LFromLog="$(trim_value "$(extract_b07_value "GateSummaryJson")")"
  if [[ -n "${LFromLog}" ]]; then
    echo "${LFromLog}"
    return 0
  fi

  echo "$(dirname "${LOG_PATH}")/gate_summary.json"
}

verify_summary_json_if_present() {
  local LSummaryJson

  LSummaryJson="$(resolve_summary_json_path)"
  if [[ ! -f "${LSummaryJson}" ]]; then
    return 10
  fi

  if [[ ! -f "${SUMMARY_JSON_VERIFIER}" ]]; then
    echo "[EVIDENCE] Missing gate summary verifier: ${SUMMARY_JSON_VERIFIER}"
    return 2
  fi

  if ! command -v python3 >/dev/null 2>&1; then
    echo "[EVIDENCE] Missing python3 for gate summary json verification"
    return 2
  fi

  python3 "${SUMMARY_JSON_VERIFIER}" --summary-json "${LSummaryJson}"
}

LFail=0
LTotal=""
LPassed=""
LFailed=""

check_fixed "[B07] Windows evidence capture" || LFail=1
check_regex '^\[B07\][[:space:]]+Source:[[:space:]]+collect_windows_b07_evidence\.bat[[:space:]]*$' || LFail=1
check_regex '^\[B07\][[:space:]]+HostOS:[[:space:]]+Windows_NT[[:space:]]*$' || LFail=1
check_regex '^\[B07\][[:space:]]+CmdVer:[[:space:]]+Microsoft[[:space:]]+Windows.*$' || LFail=1
check_regex '^\[B07\][[:space:]]+Working dir:[[:space:]]+[A-Za-z]:\\.*$' || LFail=1
  if ! grep -F -- "[B07] Command: buildOrTest.bat gate" "${CHECK_LOG_PATH}" >/dev/null && \
   ! grep -F -- "[B07] Command: BuildOrTest.sh gate" "${CHECK_LOG_PATH}" >/dev/null; then
  echo "[EVIDENCE] Missing command marker for gate entry"
  LFail=1
fi
check_fixed "[GATE] OK" || LFail=1
check_fixed "[B07] GATE_EXIT_CODE=0" || LFail=1

if grep -E -- '^\[B07\][[:space:]]+Simulated:[[:space:]]+yes$' "${CHECK_LOG_PATH}" >/dev/null; then
  echo "[EVIDENCE] Invalid source: simulated marker detected"
  LFail=1
fi

if grep -E -- '^\[B07\][[:space:]]+Source:[[:space:]]+simulate_windows_b07_evidence\.sh$' "${CHECK_LOG_PATH}" >/dev/null; then
  echo "[EVIDENCE] Invalid source: simulator source marker detected"
  LFail=1
fi

set +e
verify_summary_json_if_present
LSummaryJsonRc=$?
set -e

case "${LSummaryJsonRc}" in
  0)
    ;;
  10)
    check_fixed "[GATE] 1/6 Build + check SIMD module" || LFail=1
    check_fixed "[GATE] 2/6 SIMD list suites" || LFail=1
    check_fixed "[GATE] 3/6 SIMD AVX2 fallback suite" || LFail=1
    check_fixed "[GATE] 4/6 CPUInfo portable suites" || LFail=1
    check_fixed "[GATE] 5/6 CPUInfo x86 suites" || LFail=1
    check_fixed "[GATE] 6/6 Filtered run_all chain" || LFail=1
    ;;
  *)
    LFail=1
    ;;
esac

LTotal="$(extract_metric "Total")"
LPassed="$(extract_metric "Passed")"
LFailed="$(extract_metric "Failed")"

if [[ -z "${LTotal}" || -z "${LPassed}" || -z "${LFailed}" ]]; then
  echo "[EVIDENCE] Missing summary metrics: total='${LTotal}' passed='${LPassed}' failed='${LFailed}'"
  LFail=1
fi

if [[ -n "${LFailed}" && "${LFailed}" != "0" ]]; then
  echo "[EVIDENCE] Invalid summary: failed=${LFailed} (expect 0)"
  LFail=1
fi

if [[ -n "${LTotal}" && -n "${LPassed}" && "${LTotal}" != "${LPassed}" ]]; then
  echo "[EVIDENCE] Invalid summary: total=${LTotal} passed=${LPassed} (expect total==passed)"
  LFail=1
fi

if [[ -n "${LTotal}" && "${LTotal}" =~ ^[0-9]+$ && "${LTotal}" -lt 3 ]]; then
  echo "[EVIDENCE] Invalid summary: total=${LTotal} (expect >=3)"
  LFail=1
fi

if [[ "${LFail}" != "0" ]]; then
  echo "[EVIDENCE] FAILED: ${LOG_PATH}"
  exit 1
fi

echo "[EVIDENCE] OK: ${LOG_PATH}"
