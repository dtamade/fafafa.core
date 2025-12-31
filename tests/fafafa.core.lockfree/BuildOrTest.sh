#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
PCP_DIR="${SCRIPT_DIR}/.lazarus"
LAZBUILD_PATH="${ROOT_DIR}/tools/lazbuild.sh"
LAZBUILD_BIN="$(command -v lazbuild 2>/dev/null || true)"
REQUESTED_COMPILER="${FAFAFA_LOCKFREE_FPC:-}"
DEFAULT_FPC="$(command -v fpc 2>/dev/null || true)"
EXTRA_OPTS_STRING="${FAFAFA_LOCKFREE_LAZBUILD_OPTS:-}"

if [[ -x "${LAZBUILD_PATH}" ]]; then
  LAZBUILD="${LAZBUILD_PATH}"
else
  if [[ -n "${LAZBUILD_BIN}" ]]; then
    echo "[WARN] tools/lazbuild.sh not found or not executable, using lazbuild from PATH"
    LAZBUILD="${LAZBUILD_BIN}"
  else
    echo "[ERROR] lazbuild not available (missing tools/lazbuild.sh and lazbuild in PATH)"
    exit 1
  fi
fi

if [[ -z "${LAZARUS_DIR:-}" ]]; then
  if [[ -n "${LAZBUILD_BIN}" ]]; then
    LAZARUS_DIR="$(cd "$(dirname "${LAZBUILD_BIN}")" && pwd)"
  else
    LAZARUS_DIR=""
  fi
fi

if [[ ! -d "${LAZARUS_DIR}/lcl" ]]; then
  echo "[ERROR] Lazarus directory not found or invalid (set LAZARUS_DIR): ${LAZARUS_DIR}"
  exit 1
fi

if [[ -n "${REQUESTED_COMPILER}" ]]; then
  CUSTOM_COMPILER="${REQUESTED_COMPILER}"
else
  CUSTOM_COMPILER="${DEFAULT_FPC}"
fi

DEFAULT_UNIT_FLAGS=()
if [[ -n "${DEFAULT_FPC}" ]]; then
  FPC_ROOT="$(cd "$(dirname "${DEFAULT_FPC}")/.." && pwd)"
  for TARGET in x86_64-linux x86_64-win64; do
    OBJPAS="${FPC_ROOT}/units/${TARGET}/rtl-objpas"
    if [[ -d "${OBJPAS}" ]]; then
      DEFAULT_UNIT_FLAGS+=("-Fu${OBJPAS}")
    fi
  done
fi
UNIT_OPTS=""
if [[ ${#DEFAULT_UNIT_FLAGS[@]} -gt 0 ]]; then
  UNIT_OPTS="${DEFAULT_UNIT_FLAGS[*]}"
fi
if [[ ${#DEFAULT_UNIT_FLAGS[@]} -gt 0 ]]; then
  UNIT_OPTS="${DEFAULT_UNIT_FLAGS[*]}"
  export FPCOPT="${FPCOPT:-} ${UNIT_OPTS}"
fi

PROJECT_FILE="${SCRIPT_DIR}/fafafa.core.lockfree.tests.lpi"
TEST_EXEC_BASE="${SCRIPT_DIR}/bin/lockfree_tests"

mkdir -p "${PCP_DIR}"

echo "[BUILD] Project: ${PROJECT_FILE}"
declare -a LAZBUILD_ARGS
LAZBUILD_ARGS+=("--pcp=${PCP_DIR}" "--lazarusdir=${LAZARUS_DIR}")
if [[ -n "${CUSTOM_COMPILER}" ]]; then
  LAZBUILD_ARGS+=("--compiler=${CUSTOM_COMPILER}")
fi
if [[ -n "${EXTRA_OPTS_STRING}" ]]; then
  # shellcheck disable=SC2206
  EXTRA_SPLIT=(${EXTRA_OPTS_STRING})
  LAZBUILD_ARGS+=("${EXTRA_SPLIT[@]}")
fi
if [[ -n "${UNIT_OPTS}" ]]; then
  LAZBUILD_ARGS+=("--build-ide-options=${UNIT_OPTS}")
fi
if ! "${LAZBUILD}" "${LAZBUILD_ARGS[@]}" "${PROJECT_FILE}"; then
  echo "[BUILD] Failed."
  exit 1
fi

echo
echo "[BUILD] Successful."
echo

ACTION="${1:-}"

if [[ "${ACTION}" == "test" ]]; then
  if [[ -x "${TEST_EXEC_BASE}" ]]; then
    TEST_EXEC="${TEST_EXEC_BASE}"
  elif [[ -x "${TEST_EXEC_BASE}.exe" ]]; then
    TEST_EXEC="${TEST_EXEC_BASE}.exe"
  else
    echo "[ERROR] Test executable not found (looked for ${TEST_EXEC_BASE}[.exe])"
    exit 1
  fi
  echo "[TEST] Running ${TEST_EXEC} --all --format=plain --progress"
  "${TEST_EXEC}" --all --format=plain --progress
else
  echo "To run tests, call this script with the 'test' parameter."
fi

IFACES_SCRIPT="${SCRIPT_DIR}/build_ifaces_factories_tests.sh"
echo
if [[ -x "${IFACES_SCRIPT}" ]]; then
  echo "[IFACES] Building and running interface/factories suite..."
  "${IFACES_SCRIPT}"
else
  echo "[INFO] Interface/factories runner script not found (${IFACES_SCRIPT}); skipping."
fi
