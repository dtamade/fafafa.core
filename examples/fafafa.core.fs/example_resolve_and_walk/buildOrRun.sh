#!/usr/bin/env bash
set -euo pipefail

# Build and run example_resolve_and_walk using lazbuild on Linux/macOS
# Usage:
#   ./buildOrRun.sh
# Env:
#   LAZBUILD_EXE  Override lazbuild executable path (optional)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAZBUILD_EXE="${LAZBUILD_EXE:-lazbuild}"
PRJ="${SCRIPT_DIR}/example_resolve_and_walk.lpi"

"${LAZBUILD_EXE}" "${PRJ}"

BIN="${SCRIPT_DIR}/bin/example_resolve_and_walk"
if [[ -x "${BIN}" ]]; then
  echo "Running example..."
  "${BIN}"
else
  echo "Executable not found at: ${BIN}"
  exit 1
fi

