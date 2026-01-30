#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
LAZBUILD="lazbuild"
PROJECT="$SCRIPT_DIR/example_mem.lpi"
MODE="Debug"
ACTION=""

if [[ ${1-} == "release" ]]; then
  MODE="Release"
fi
if [[ ${2-} == "run" ]]; then
  ACTION="run"
fi

"$LAZBUILD" --build-mode="$MODE" "$PROJECT"

BIN_DIR="$SCRIPT_DIR/bin"
EXE_NAME="example_mem"
if [[ "$MODE" == "Debug" ]]; then
  EXE_NAME+="_debug"
fi

EXE_PATH="$BIN_DIR/$EXE_NAME"
if [[ "$ACTION" == "run" ]]; then
  "$EXE_PATH"
fi

