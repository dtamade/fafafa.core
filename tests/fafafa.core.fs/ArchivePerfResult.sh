#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PERF_DIR="${SCRIPT_DIR}/performance-data"
RUN_SH="${SCRIPT_DIR}/BuildOrRunPerf.sh"
LOG_FILE="${PERF_DIR}/latest.txt"

mkdir -p "${PERF_DIR}"

TS="$(date +%F_%H-%M-%S)"
TS_FILE="${PERF_DIR}/perf_${TS}.txt"
TMP_OUTPUT="$(mktemp)"
trap 'rm -f "${TMP_OUTPUT}"' EXIT

echo "[1/1] Running perf and archiving ..."
if bash "${RUN_SH}" "$@" | tee "${TMP_OUTPUT}"; then
  RET=0
else
  RET=$?
fi

{
  echo "Timestamp: ${TS}"
  printf 'Command: BuildOrRunPerf.sh'
  for a in "$@"; do
    printf ' %q' "${a}"
  done
  printf '\n'
  echo "--- Output ---"
  cat "${TMP_OUTPUT}"
} >"${TS_FILE}"

cp -f "${TS_FILE}" "${LOG_FILE}"

if [[ -f "${PERF_DIR}/baseline.txt" ]]; then
  echo
  echo "[Diff] latest vs baseline:"
  if command -v diff >/dev/null 2>&1; then
    diff -u "${PERF_DIR}/baseline.txt" "${LOG_FILE}" || true
  else
    echo "(diff not found)"
  fi
else
  echo
  echo "[Tip] You can set \"${PERF_DIR}/baseline.txt\" to enable baseline diff."
fi

echo
echo "Saved: ${TS_FILE}"
echo "Latest: ${LOG_FILE}"

exit "${RET}"
