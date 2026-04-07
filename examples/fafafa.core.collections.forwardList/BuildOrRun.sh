#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAZBUILD_BIN="${LAZBUILD:-lazbuild}"
PROJECT="${SCRIPT_DIR}/example_forwardList.lpi"
DEFAULT_EXE="${SCRIPT_DIR}/../../bin/example_forwardList"
DEBUG_EXE="${SCRIPT_DIR}/../../bin/example_forwardList_debug"

if ! command -v "${LAZBUILD_BIN}" >/dev/null 2>&1; then
  echo "lazbuild not found: ${LAZBUILD_BIN}" >&2
  exit 1
fi

build_default() {
  echo "[BUILD] lazbuild ${PROJECT} (project default mode)"
  "${LAZBUILD_BIN}" "${PROJECT}"
}

build_release() {
  echo "[BUILD] lazbuild --build-mode=Release ${PROJECT}"
  "${LAZBUILD_BIN}" --build-mode=Release "${PROJECT}"
}

run_example() {
  local exe="${DEFAULT_EXE}"

  if [[ ! -x "${exe}" && -x "${exe}.exe" ]]; then
    exe="${exe}.exe"
  fi

  if [[ ! -x "${exe}" ]]; then
    exe="${DEBUG_EXE}"
  fi

  if [[ ! -x "${exe}" && -x "${exe}.exe" ]]; then
    exe="${exe}.exe"
  fi

  if [[ ! -x "${exe}" ]]; then
    echo "Executable not found in ../../bin/" >&2
    exit 1
  fi

  echo "[RUN] ${exe}"
  "${exe}"
}

case "${1:-build}" in
  build)
    build_default
    ;;
  run)
    build_default
    echo
    run_example
    ;;
  release)
    build_release
    echo "Build (Release) successful: ${DEFAULT_EXE}"
    ;;
  *)
    echo "Usage:"
    echo "  $(basename "$0") build     (Build with the project default mode)"
    echo "  $(basename "$0") run       (Build with the project default mode and run)"
    echo "  $(basename "$0") release   (Build Release executable)"
    exit 1
    ;;
esac
