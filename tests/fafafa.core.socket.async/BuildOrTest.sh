#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

ACTION="${1:-test}"
PROJECT_LPR="fafafa.core.socket.async.test.lpr"
TEST_BIN="bin/fafafa.core.socket.async.test"

find_fpc() {
  local candidate

  for candidate in "${FPC_BIN:-}" "${FPC:-}"; do
    if [[ -n "${candidate}" && -x "${candidate}" ]]; then
      printf '%s\n' "${candidate}"
      return 0
    fi

    if [[ -n "${candidate}" ]] && command -v "${candidate}" >/dev/null 2>&1; then
      command -v "${candidate}"
      return 0
    fi
  done

  if command -v fpc >/dev/null 2>&1; then
    command -v fpc
    return 0
  fi

  if [[ -x "/opt/fpcupdeluxe/fpc/bin/x86_64-linux/fpc" ]]; then
    printf '%s\n' "/opt/fpcupdeluxe/fpc/bin/x86_64-linux/fpc"
    return 0
  fi

  return 1
}

case "${ACTION}" in
  build|test|run|clean) ;;
  *)
    echo "[ERROR] Unsupported action: ${ACTION}" >&2
    echo "Usage: $(basename "$0") [build|test|clean]" >&2
    exit 2
    ;;
esac

if [[ "${ACTION}" == "clean" ]]; then
  rm -rf ./bin ./lib
  echo "[CLEAN] removed bin and lib"
  exit 0
fi

FPC_PATH="$(find_fpc || true)"
if [[ -z "${FPC_PATH}" ]]; then
  echo "[ERROR] fpc not found. Set FPC_BIN or FPC." >&2
  exit 1
fi

rm -rf ./bin ./lib
mkdir -p ./bin ./lib

echo "[BUILD] ${FPC_PATH} ${PROJECT_LPR}"
"${FPC_PATH}" -MObjFPC -Scghi -O2 -vewnhibq \
  -Fu../../src -Fu. \
  -FUlib \
  -FEbin \
  "${PROJECT_LPR}"

if [[ "${ACTION}" == "build" ]]; then
  echo "[INFO] build-only mode"
  exit 0
fi

echo "[RUN] ${TEST_BIN}"
if [[ -x "${TEST_BIN}" ]]; then
  "${TEST_BIN}" --all --progress --format=plain
elif [[ -x "${TEST_BIN}.exe" ]]; then
  "${TEST_BIN}.exe" --all --progress --format=plain
else
  echo "[ERROR] test executable not found: ${TEST_BIN}[.exe]" >&2
  exit 100
fi
