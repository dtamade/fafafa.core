#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
PREFLIGHT_SCRIPT="${REPO_ROOT}/tests/test_windows_lazbuild_smoke_preflight.sh"

if [[ ! -x "${PREFLIGHT_SCRIPT}" ]]; then
  echo "[FAIL] missing executable preflight script: ${PREFLIGHT_SCRIPT}" >&2
  exit 1
fi

set +e
OUTPUT="$("${PREFLIGHT_SCRIPT}" 2>&1)"
RC=$?
set -e

if [[ ${RC} -eq 31 ]]; then
  if ! printf '%s' "${OUTPUT}" | rg -n "LAZBUILD_EXE|lazbuild\.exe" >/dev/null; then
    echo "[FAIL] preflight blocker output does not explain how to provide Windows lazbuild.exe" >&2
    printf '%s\n' "${OUTPUT}" >&2
    exit 1
  fi

  if ! printf '%s' "${OUTPUT}" | rg -n "set LAZBUILD_EXE=|tests\\\\fafafa\.core\.platform\\\\BuildOrTest\.bat test" >/dev/null; then
    echo "[FAIL] preflight blocker output does not include actionable next-step commands" >&2
    printf '%s\n' "${OUTPUT}" >&2
    exit 1
  fi

  echo "[PASS] preflight blocker output includes recovery guidance"
  exit 0
fi

if [[ ${RC} -eq 20 ]]; then
  echo "[PASS] preflight correctly reports missing wine"
  exit 0
fi

if [[ ${RC} -eq 0 ]]; then
  echo "[PASS] preflight passed with a Windows lazbuild.exe available"
  exit 0
fi

echo "[FAIL] unexpected preflight exit code: ${RC}" >&2
printf '%s\n' "${OUTPUT}" >&2
exit 1
