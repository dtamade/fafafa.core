#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="${SCRIPT_DIR}/bin"

mkdir -p "${BIN_DIR}"

# Resolve lazbuild: prefer $LAZBUILD_EXE; fallback to lazbuild in PATH
run_lazbuild() {
  local proj="$1"
  if [[ -n "${LAZBUILD_EXE:-}" ]]; then
    echo "[tools] using LAZBUILD_EXE=${LAZBUILD_EXE}"
    "${LAZBUILD_EXE}" "${proj}"
  else
    if command -v lazbuild >/dev/null 2>&1; then
      echo "[tools] using PATH lazbuild"
      lazbuild "${proj}"
    else
      echo "[Build] ERROR: lazbuild not found. Set LAZBUILD_EXE or add lazbuild to PATH."
      exit 1
    fi
  fi
}

# Build all WINCH-related examples via example_term.lpi
run_lazbuild "${SCRIPT_DIR}/example_term.lpi"

echo "[Build] OK. Binaries in ${BIN_DIR}"

# Optional run
if [[ "${1:-}" == "run" ]]; then
  TARGET="${2:-}"
  if [[ -z "${TARGET}" ]]; then
    echo "Usage: $(basename "$0") run <target>"
    echo "Targets: resize_layout_demo, example_winch_channel, example_win_winch_poll, example_winch_portable"
    exit 0
  fi
  EXE="${BIN_DIR}/${TARGET}"
  if [[ -x "${EXE}" ]]; then
    echo "[Run] ${EXE}"
    "${EXE}"
  else
    echo "[Run] Not found or not executable: ${EXE}"
    echo "Available targets:"
    echo "  resize_layout_demo"
    echo "  example_winch_channel"
    echo "  example_win_winch_poll"
    echo "  example_winch_portable"
    exit 1
  fi
fi

exit 0

