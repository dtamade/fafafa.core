#!/usr/bin/env bash
set -euo pipefail

LOG_PATH="${1:-}"
if [[ -z "${LOG_PATH}" ]]; then
  echo "Usage: $0 <windows_b07_gate.log>"
  exit 2
fi

if [[ ! -f "${LOG_PATH}" ]]; then
  echo "[EVIDENCE] Missing log: ${LOG_PATH}"
  exit 2
fi

LSANITIZED_LOG="$(mktemp)"
trap 'rm -f "${LSANITIZED_LOG}"' EXIT
tr -d '' < "${LOG_PATH}" > "${LSANITIZED_LOG}"

require_regex() {
  local aPattern
  aPattern="$1"
  if ! grep -Eq "${aPattern}" "${LSANITIZED_LOG}"; then
    echo "[EVIDENCE] Missing regex: ${aPattern}"
    return 1
  fi
}

LFailed=0
LIsSimulated=0
if grep -Eq '^\[B07\][[:space:]]+Simulated:[[:space:]]+yes$' "${LOG_PATH}"; then
  LIsSimulated=1
fi

for LPattern in \
  '^\[B07\][[:space:]]+Windows evidence capture$' \
  '^\[B07\][[:space:]]+Started:[[:space:]]+.+' \
  '^\[B07\][[:space:]]+Working dir:[[:space:]]+.+' \
  '^\[B07\][[:space:]]+Command:[[:space:]]+buildOrTest\.bat gate$' \
  '^\[GATE\][[:space:]]+OK$' \
  '^\[B07\][[:space:]]+GATE_EXIT_CODE=0$' \
  '^\[B07\][[:space:]]+Total:[[:space:]]+[0-9]+$' \
  '^\[B07\][[:space:]]+Passed:[[:space:]]+[0-9]+$' \
  '^\[B07\][[:space:]]+Failed:[[:space:]]+[0-9]+$'; do
  if ! require_regex "${LPattern}"; then
    LFailed=1
  fi
done

if [[ "${LIsSimulated}" == "1" ]]; then
  if ! require_regex '^\[B07\][[:space:]]+Source:[[:space:]]+simulate_windows_b07_evidence\.sh$'; then
    LFailed=1
  fi
else
  for LPattern in \
    '^\[B07\][[:space:]]+Source:[[:space:]]+collect_windows_b07_evidence\.bat$' \
    '^\[B07\][[:space:]]+HostOS:[[:space:]]+Windows_NT$' \
    '^\[B07\][[:space:]]+CmdVer:[[:space:]]+Microsoft[[:space:]]+Windows' \
    '^\[B07\][[:space:]]+Working dir:[[:space:]]+[A-Za-z]:\\'; do
    if ! require_regex "${LPattern}"; then
      LFailed=1
    fi
  done
fi

if [[ "${LFailed}" != "0" ]]; then
  echo "[EVIDENCE] FAILED: ${LOG_PATH}"
  exit 1
fi

echo "[EVIDENCE] PASS: ${LOG_PATH} (simulated=${LIsSimulated})"
