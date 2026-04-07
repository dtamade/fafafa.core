#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

LAZBUILD_BIN="${LAZBUILD:-lazbuild}"
FPC_BIN="${FPC:-fpc}"

ACTION="${1:-run}"
TARGET="${2:-all}"

case "${ACTION}" in
  quickstart|periodic|options|all)
    TARGET="${ACTION}"
    ACTION="run"
    ;;
esac

resolve_lazbuild() {
  if command -v "${LAZBUILD_BIN}" >/dev/null 2>&1; then
    echo "${LAZBUILD_BIN}"
    return 0
  fi

  return 1
}

build_with_lazbuild() {
  local lpi="$1"
  local laz

  laz="$(resolve_lazbuild)" || return 1
  echo "[BUILD] lazbuild ${lpi} (project default mode)"
  "${laz}" "${lpi}"
}

build_with_fpc() {
  local lpr="$1"

  echo "[BUILD] fpc ${lpr}"
  mkdir -p "lib/fpc"
  "${FPC_BIN}" -Mobjfpc -Sh -O1 -g -gl \
    -I../../src -Fu../../src -Fu. \
    -FUlib/fpc -FEbin \
    "${lpr}"
}

build_one() {
  local base="$1"
  local lpi="${base}.lpi"
  local lpr="${base}.lpr"

  if ! build_with_lazbuild "${lpi}"; then
    echo "[WARN] lazbuild not found; falling back to fpc for ${base}" >&2
    build_with_fpc "${lpr}"
  fi
}

run_exe() {
  local base="$1"
  local exe="./bin/${base}"

  [[ -x "${exe}" ]] || exe="./bin/${base}.exe"
  if [[ ! -x "${exe}" ]]; then
    echo "[ERROR] executable not found: ${base} (looked for ./bin/${base} and ./bin/${base}.exe)" >&2
    exit 100
  fi

  echo "[RUN] ${exe}"
  "${exe}"
}

rm -rf ./bin
rm -rf ./lib/fpc ./lib/*-*/
mkdir -p ./bin ./lib

case "${ACTION}" in
  build|run) ;;
  *)
    echo "Usage: $0 [build|run] [quickstart|periodic|options|all]" >&2
    exit 2
    ;;
esac

case "${TARGET}" in
  quickstart)
    build_one example_timer_quickstart
    if [[ "${ACTION}" == "run" ]]; then
      run_exe example_timer_quickstart
    fi
    ;;
  periodic)
    build_one example_timer_periodic
    if [[ "${ACTION}" == "run" ]]; then
      run_exe example_timer_periodic
    fi
    ;;
  options)
    build_one example_timer_options_async_executor
    if [[ "${ACTION}" == "run" ]]; then
      run_exe example_timer_options_async_executor
    fi
    ;;
  all)
    build_one example_timer_quickstart
    build_one example_timer_periodic
    build_one example_timer_options_async_executor
    if [[ "${ACTION}" == "run" ]]; then
      echo
      run_exe example_timer_quickstart
      echo
      run_exe example_timer_periodic
      echo
      run_exe example_timer_options_async_executor
    fi
    ;;
  *)
    echo "Usage: $0 [build|run] [quickstart|periodic|options|all]" >&2
    exit 2
    ;;
esac
