#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
LOG_PATH="${1:-${ROOT}/logs/windows_b07_gate.log}"

print_usage() {
  echo "Usage: $0 [evidence-log-path]"
  echo "Default log: ${ROOT}/logs/windows_b07_gate.log"
}

if [[ "${LOG_PATH}" == "-h" || "${LOG_PATH}" == "--help" ]]; then
  print_usage
  exit 0
fi

if [[ ! -f "${LOG_PATH}" ]]; then
  echo "[EVIDENCE] Missing log: ${LOG_PATH}"
  exit 2
fi

check_fixed() {
  local aPattern

  aPattern="$1"
  if grep -F -- "${aPattern}" "${LOG_PATH}" >/dev/null; then
    return 0
  fi

  echo "[EVIDENCE] Missing pattern: ${aPattern}"
  return 1
}

check_regex() {
  local aPattern

  aPattern="$1"
  if grep -E -- "${aPattern}" "${LOG_PATH}" >/dev/null; then
    return 0
  fi

  echo "[EVIDENCE] Missing regex: ${aPattern}"
  return 1
}

extract_metric() {
  local aMetric
  local LLine

  aMetric="$1"
  LLine="$(grep -E -- "^\\[B07\\][[:space:]]+${aMetric}:[[:space:]]*[0-9]+$" "${LOG_PATH}" | tail -n 1 || true)"
  if [[ -z "${LLine}" ]]; then
    LLine="$(grep -E -- "^${aMetric}:[[:space:]]*[0-9]+$" "${LOG_PATH}" | tail -n 1 || true)"
  fi

  if [[ -z "${LLine}" ]]; then
    echo ""
    return 0
  fi

  echo "${LLine}" | sed -E 's/.*:[[:space:]]*([0-9]+)[[:space:]]*$/\1/'
}

LFail=0
LTotal=""
LPassed=""
LFailed=""

check_fixed "[B07] Windows evidence capture" || LFail=1
check_regex '^\[B07\][[:space:]]+Source:[[:space:]]+collect_windows_b07_evidence\.bat$' || LFail=1
check_regex '^\[B07\][[:space:]]+HostOS:[[:space:]]+Windows_NT$' || LFail=1
check_regex '^\[B07\][[:space:]]+CmdVer:[[:space:]]+Microsoft[[:space:]]+Windows' || LFail=1
check_regex '^\[B07\][[:space:]]+Working dir:[[:space:]]+[A-Za-z]:\\' || LFail=1
check_fixed "[B07] Command: buildOrTest.bat gate" || LFail=1
check_fixed "[GATE] 1/6 Build + check SIMD module" || LFail=1
check_fixed "[GATE] 2/6 SIMD list suites" || LFail=1
check_fixed "[GATE] 3/6 SIMD AVX2 fallback suite" || LFail=1
check_fixed "[GATE] 4/6 CPUInfo portable suites" || LFail=1
check_fixed "[GATE] 5/6 CPUInfo x86 suites" || LFail=1
check_fixed "[GATE] 6/6 Filtered run_all chain" || LFail=1
check_fixed "[GATE] OK" || LFail=1
check_fixed "[B07] GATE_EXIT_CODE=0" || LFail=1

check_regex '^Total:[[:space:]]+[0-9]+$' || LFail=1
check_regex '^Passed:[[:space:]]+[0-9]+$' || LFail=1
check_regex '^Failed:[[:space:]]+0$' || LFail=1

if ! grep -E -- '^\[B07\][[:space:]]+Total:[[:space:]]+[0-9]+$' "${LOG_PATH}" >/dev/null; then
  echo "[EVIDENCE] Missing regex: ^\\[B07\\][[:space:]]+Total:[[:space:]]+[0-9]+$"
  LFail=1
fi

if ! grep -E -- '^\[B07\][[:space:]]+Passed:[[:space:]]+[0-9]+$' "${LOG_PATH}" >/dev/null; then
  echo "[EVIDENCE] Missing regex: ^\\[B07\\][[:space:]]+Passed:[[:space:]]+[0-9]+$"
  LFail=1
fi

if ! grep -E -- '^\[B07\][[:space:]]+Failed:[[:space:]]+0$' "${LOG_PATH}" >/dev/null; then
  echo "[EVIDENCE] Missing regex: ^\\[B07\\][[:space:]]+Failed:[[:space:]]+0$"
  LFail=1
fi

if grep -E -- '^\[B07\][[:space:]]+Simulated:[[:space:]]+yes$' "${LOG_PATH}" >/dev/null; then
  echo "[EVIDENCE] Invalid source: simulated marker detected"
  LFail=1
fi

if grep -E -- '^\[B07\][[:space:]]+Source:[[:space:]]+simulate_windows_b07_evidence\.sh$' "${LOG_PATH}" >/dev/null; then
  echo "[EVIDENCE] Invalid source: simulator source marker detected"
  LFail=1
fi

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
