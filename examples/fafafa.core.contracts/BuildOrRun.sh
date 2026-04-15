#!/usr/bin/env bash
set -euo pipefail

ACTION="${1:-run}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
cd "${SCRIPT_DIR}"

PROJECT="${SCRIPT_DIR}/example_contracts_basics.lpi"
EXECUTABLE="${SCRIPT_DIR}/bin/example_contracts_basics"
TOOLS_LAZBUILD="${ROOT_DIR}/tools/lazbuild.sh"

LZ_Q=()
if [[ "${FAFAFA_BUILD_QUIET:-1}" != "0" ]]; then
  LZ_Q+=("--quiet")
fi

LAZBUILD_BIN="${LAZBUILD:-}"
if [[ -z "${LAZBUILD_BIN}" ]]; then
  if [[ -x "${TOOLS_LAZBUILD}" ]]; then
    LAZBUILD_BIN="${TOOLS_LAZBUILD}"
  else
    LAZBUILD_BIN="lazbuild"
  fi
fi

build_project() {
  echo "[BUILD] Project: ${PROJECT}"
  "${LAZBUILD_BIN}" "${LZ_Q[@]}" --build-all "${PROJECT}"
}

run_example() {
  if [[ -x "${EXECUTABLE}" ]]; then
    "${EXECUTABLE}"
  elif [[ -x "${EXECUTABLE}.exe" ]]; then
    "${EXECUTABLE}.exe"
  else
    echo "[ERROR] Example executable not found: ${EXECUTABLE}[.exe]" >&2
    return 1
  fi
}

case "${ACTION}" in
  build)
    build_project
    ;;
  run)
    build_project
    run_example
    ;;
  *)
    echo "Usage: $0 [build|run]"
    exit 2
    ;;
esac
