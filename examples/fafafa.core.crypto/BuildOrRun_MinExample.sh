#!/usr/bin/env bash
set -euo pipefail

# Locate lazbuild: prefer env LAZBUILD_EXE, fallback to PATH
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
PRJ_LPI="${SCRIPT_DIR}/example_aead_inplace_append_min.lpi"
PRJ_PAS="${SCRIPT_DIR}/example_aead_inplace_append_min.pas"

if [[ -f "${PRJ_LPI}" ]]; then
  echo "[build] lpi: ${PRJ_LPI}"
  "${LAZBUILD_EXE}" --bm=Release "${PRJ_LPI}" || BUILD_RC=$?
else
  echo "[warn] .lpi not found, building .pas directly (ensure src path is discoverable)"
  "${LAZBUILD_EXE}" --bm=Release "${PRJ_PAS}" || BUILD_RC=$?
fi
BUILD_RC=${BUILD_RC:-0}
if [[ ${BUILD_RC} -ne 0 ]]; then
  echo "[error] build failed with exit code ${BUILD_RC}" >&2
  echo "        Hint: verify lazbuild can resolve src path (OtherUnitFiles=../../src) and permissions." >&2
  exit ${BUILD_RC}
fi

EXE="${SCRIPT_DIR}/example_aead_inplace_append_min"
[[ -f "${EXE}.exe" ]] && EXE="${EXE}.exe"

if [[ -x "${EXE}" ]]; then
  echo "[run] ${EXE}"
  "${EXE}"
else
  echo "[error] built executable not found: ${EXE}" >&2
  echo "        Hint: check Target.Filename in .lpi or the default output location." >&2
  exit 1
fi

