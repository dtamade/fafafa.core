#!/usr/bin/env bash
set -euo pipefail

# Linux/macOS runner for the interface/factories contract suite.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
PCP_DIR="${SCRIPT_DIR}/.lazarus"
LAZBUILD_SH="${ROOT_DIR}/tools/lazbuild.sh"
LAZBUILD_BIN="$(command -v lazbuild 2>/dev/null || true)"
REQUESTED_COMPILER="${FAFAFA_LOCKFREE_FPC:-}"
DEFAULT_FPC="$(command -v fpc 2>/dev/null || true)"
EXTRA_OPTS_STRING="${FAFAFA_LOCKFREE_LAZBUILD_OPTS:-}"

if [[ -x "${LAZBUILD_SH}" ]]; then
  LAZBUILD="${LAZBUILD_SH}"
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

PROJECT_FILE="${SCRIPT_DIR}/fafafa.core.lockfree.ifaces_factories.test.lpi"
EXECUTABLE_BASE="${SCRIPT_DIR}/bin/lockfree_ifaces_factories_tests"
LOG_DIR="${SCRIPT_DIR}/logs"
LOG_FILE="${LOG_DIR}/latest_ifaces_factories.log"

mkdir -p "${PCP_DIR}"
mkdir -p "${LOG_DIR}"

echo "[IFACES] Building project: ${PROJECT_FILE}"
set +e
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
"${LAZBUILD}" "${LAZBUILD_ARGS[@]}" "${PROJECT_FILE}"
BUILD_RC=$?
set -e
if [[ ${BUILD_RC} -ne 0 ]]; then
  echo "[IFACES] Build failed with exit code ${BUILD_RC}"
  exit ${BUILD_RC}
fi

if [[ -x "${EXECUTABLE_BASE}" ]]; then
  EXECUTABLE="${EXECUTABLE_BASE}"
elif [[ -x "${EXECUTABLE_BASE}.exe" ]]; then
  EXECUTABLE="${EXECUTABLE_BASE}.exe"
else
  echo "[ERROR] Interface/factories test executable not found at ${EXECUTABLE_BASE}[.exe]"
  exit 1
fi

echo "[IFACES] Running ${EXECUTABLE}"
set +e
{
  echo "[run] ${EXECUTABLE} --all --format=plain --progress"
  "${EXECUTABLE}" --all --format=plain --progress
} 2>&1 | tee "${LOG_FILE}"
RUN_RC=${PIPESTATUS[0]}
set -e

if [[ ${RUN_RC} -ne 0 ]]; then
  echo "[IFACES] Runner exited with ${RUN_RC}"
  exit ${RUN_RC}
fi

echo "[IFACES] Interface/factories tests completed successfully"
