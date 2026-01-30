#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAZBUILD="$SCRIPT_DIR/../../tools/lazbuild.bat"
PROJECT="$SCRIPT_DIR/example_forwardList.lpi"
DEBUG_EXE="$SCRIPT_DIR/../../bin/example_forwardList_debug"
RELEASE_EXE="$SCRIPT_DIR/../../bin/example_forwardList"

# On Linux, lazbuild is usually available as lazbuild; allow override
if command -v lazbuild >/dev/null 2>&1; then
  LAZBUILD_BIN="lazbuild"
else
  LAZBUILD_BIN="$LAZBUILD"
fi

echo "Building project (Debug): $PROJECT"
"$LAZBUILD_BIN" "$PROJECT" --build-mode=Debug

echo
if [[ "${1:-}" == "run" ]]; then
  echo "Running example (prefer Debug executable)..."
  if [[ -x "$DEBUG_EXE" ]]; then
    "$DEBUG_EXE"
  elif [[ -x "$RELEASE_EXE" ]]; then
    "$RELEASE_EXE"
  else
    echo "Executable not found in ../../bin/"
    echo "You can build Release with: $0 release"
  fi
elif [[ "${1:-}" == "release" ]]; then
  echo "Building project (Release): $PROJECT"
  "$LAZBUILD_BIN" "$PROJECT" --build-mode=Release
  echo "Build (Release) successful: $RELEASE_EXE"
else
  echo "Usage:"
  echo "  $(basename "$0") run       (Build Debug and run example)"
  echo "  $(basename "$0") release   (Build Release executable)"
fi

