#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="${1:-$(cd "${SCRIPT_DIR}/.." && pwd)}"

if [[ ! -d "${REPO_ROOT}/src" ]]; then
  echo "[CHECK] Missing src directory: ${REPO_ROOT}/src" >&2
  exit 2
fi

mapfile -t OFFENDERS < <(find "${REPO_ROOT}/src" -type f \( -name '*.o' -o -name '*.ppu' -o -name '*.bak' \) | sort)

if [[ "${#OFFENDERS[@]}" -gt 0 ]]; then
  echo "[CHECK] FAIL: source tree contains generated artifacts under src/" >&2
  printf '%s\n' "${OFFENDERS[@]}" >&2
  exit 1
fi

echo "[CHECK] OK (src tree hygiene: no .o/.ppu/.bak artifacts)"
