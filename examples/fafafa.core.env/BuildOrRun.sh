#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

LAZBUILD_BIN="${LAZBUILD:-lazbuild}"
FPC_BIN="${FPC:-fpc}"

ACTION="${1:-run}"
TARGET="${2:-quickstart}"

# Allow shorthand: ./BuildOrRun.sh quickstart|overrides|security|all
case "${ACTION}" in
  quickstart|overrides|security|all)
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
  echo "[BUILD] lazbuild --build-mode=Debug ${lpi}"
  "${laz}" --build-mode=Debug "${lpi}"
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
  local name="$1"
  local lpi="$2"
  local lpr="$3"

  if ! build_with_lazbuild "${lpi}"; then
    echo "[WARN] lazbuild not found; falling back to fpc for ${name}" >&2
    build_with_fpc "${lpr}"
  fi
}

run_one() {
  local exe="$1"
  if [[ ! -x "${exe}" ]]; then
    echo "[ERROR] executable not found: ${exe}" >&2
    exit 100
  fi
  echo "[RUN] ${exe}"
  "${exe}"
}

# Deterministic outputs
# NOTE: do NOT delete ./lib entirely, because the repo may contain tracked import libs under lib/.
rm -rf ./bin
rm -rf ./lib/*-*/
mkdir -p ./bin ./lib

target_build_and_run() {
  local target="$1"
  case "${target}" in
    quickstart)
      build_one quickstart "example_quickstart.lpi" "example_quickstart.lpr"
      [[ "${ACTION}" == "run" ]] && run_one "./bin/example_quickstart"
      ;;
    overrides)
      build_one overrides "example_overrides_showcase.lpi" "example_overrides_showcase.lpr"
      [[ "${ACTION}" == "run" ]] && run_one "./bin/example_overrides_showcase"
      ;;
    security)
      build_one security "example_security_showcase.lpi" "example_security_showcase.lpr"
      [[ "${ACTION}" == "run" ]] && run_one "./bin/example_security_showcase"
      ;;
    all)
      target_build_and_run quickstart
      echo
      target_build_and_run overrides
      echo
      target_build_and_run security
      ;;
    *)
      echo "Usage: $0 [build|run] [quickstart|overrides|security|all]" >&2
      echo "  Examples:" >&2
      echo "    $0 run quickstart" >&2
      echo "    $0 build all" >&2
      echo "    $0 security   # shorthand = run security" >&2
      exit 2
      ;;
  esac
}

case "${ACTION}" in
  build|run) ;; 
  *)
    echo "Usage: $0 [build|run] [quickstart|overrides|security|all]" >&2
    exit 2
    ;;
esac

target_build_and_run "${TARGET}"
