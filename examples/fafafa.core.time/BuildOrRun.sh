#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

LAZBUILD_BIN="${LAZBUILD:-lazbuild}"
FPC_BIN="${FPC:-fpc}"

ACTION="${1:-run}"
TARGET="${2:-all}"

# Allow shorthand: ./BuildOrRun.sh quickstart|periodic|options|all
case "${ACTION}" in
  quickstart|periodic|options|all)
    TARGET="${ACTION}"
    ACTION="run"
    ;;
esac

build_one() {
  local base="$1"
  local lpi="${base}.lpi"
  local lpr="${base}.lpr"

  if command -v "${LAZBUILD_BIN}" >/dev/null 2>&1 && [[ -f "${lpi}" ]]; then
    echo "[BUILD] lazbuild --build-mode=Debug ${lpi}"
    "${LAZBUILD_BIN}" --build-mode=Debug "${lpi}"
    return 0
  fi

  echo "[BUILD] fpc ${lpr}"
  mkdir -p "bin" "lib/fpc"
  "${FPC_BIN}" -Mobjfpc -Sh -O1 -g -gl \
    -I../../src -Fu../../src -Fu. \
    -FUlib/fpc -FEbin \
    "${lpr}"
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

# Deterministic outputs
rm -rf ./bin
rm -rf ./lib
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
