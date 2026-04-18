#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LAZBUILD_BIN="${LAZBUILD:-lazbuild}"
LOG_FILE="$(mktemp)"
trap 'rm -f "${LOG_FILE}"' EXIT

if ! command -v "${LAZBUILD_BIN}" >/dev/null 2>&1; then
  echo "[SKIP] lazbuild not found; cannot verify sync.mutex current-entry codetools cleanliness"
  exit 0
fi

cd "${ROOT}"

if ! bash examples/fafafa.core.sync.mutex/BuildOrRun.sh build >"${LOG_FILE}" 2>&1; then
  echo "[FAIL] sync.mutex current-entry build failed unexpectedly"
  cat "${LOG_FILE}"
  exit 1
fi

if rg -n 'include file not found "fafafa\.core\.settings\.inc"' "${LOG_FILE}" >/dev/null; then
  echo "[FAIL] sync.mutex current-entry still triggers Lazarus include resolution errors"
  cat "${LOG_FILE}"
  exit 1
fi

echo "[PASS] sync.mutex current-entry build is free of codetools include-resolution errors"
