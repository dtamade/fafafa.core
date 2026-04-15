#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAZBUILD="${LAZBUILD:-lazbuild}"
PROJECT="${SCRIPT_DIR}/example_json.lpi"
BIN_DIR="${SCRIPT_DIR}/bin"
LIB_DIR="${SCRIPT_DIR}/lib"
ACTION="${1:-run}"

cleanup_outputs() {
  rm -rf "${BIN_DIR}" "${LIB_DIR}"
  rm -f "${SCRIPT_DIR}/example_json.res"
  find "${SCRIPT_DIR}" -maxdepth 1 -type d -name 'lib\\*' -exec rm -rf {} +
  mkdir -p "${BIN_DIR}" "${LIB_DIR}"
}

build_example() {
  cleanup_outputs
  cd "${SCRIPT_DIR}"
  echo "[BUILD] ${PROJECT}"
  "${LAZBUILD}" "${PROJECT}" --bm=Debug --ws=nogui || {
    echo "[BUILD] FAILED ${PROJECT}"
    exit 1
  }
  rm -f "${SCRIPT_DIR}/example_json.res"
}

run_example() {
  local LExe

  LExe="${BIN_DIR}/example_json"
  if [[ -x "${LExe}" || -f "${LExe}" ]]; then
    echo "[RUN] example_json"
    "${LExe}" || {
      echo "[RUN] FAILED example_json"
      exit 1
    }
    return 0
  fi

  echo "[RUN] NOT_FOUND ${LExe}"
  exit 1
}

case "${ACTION}" in
  build)
    build_example
    ;;
  run)
    build_example
    run_example
    ;;
  *)
    echo "Usage: $0 [build|run]" >&2
    exit 2
    ;;
esac
