#!/usr/bin/env bash
set -euo pipefail

LAZBUILD_EXE=${LAZBUILD_EXE:-}
if [[ -z "${LAZBUILD_EXE}" ]]; then
  if command -v lazbuild >/dev/null 2>&1; then
    LAZBUILD_EXE="lazbuild"
  else
    echo "[error] lazbuild not found. Set LAZBUILD_EXE or ensure lazbuild is in PATH." >&2
    exit 1
  fi
fi

echo "[info] Using lazbuild: ${LAZBUILD_EXE}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PRJ="${SCRIPT_DIR}/file_encryption.lpr"

"${LAZBUILD_EXE}" --bm=Release "${PRJ}"

EXE="${SCRIPT_DIR}/file_encryption"
[[ -f "${EXE}.exe" ]] && EXE="${EXE}.exe"

if [[ -x "${EXE}" ]]; then
  echo "[run] ${EXE}"
  "${EXE}"
else
  echo "[error] built executable not found: ${EXE}" >&2
  exit 1
fi

