#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

ACTION="${1:-test}"
PROJECT_LPI="${PROJECT_LPI:-fafafa.core.sync.namedBarrier.test.lpi}"
TEST_BIN="${TEST_BIN:-bin/fafafa.core.sync.namedBarrier.test}"
FORCE_NAMED_SYNC_TESTS="${FAFAFA_FORCE_NAMED_SYNC_TESTS:-0}"

LAZBUILD_BIN="${LAZBUILD:-lazbuild}"

if ! command -v "${LAZBUILD_BIN}" >/dev/null 2>&1; then
  echo "[ERROR] lazbuild not found in PATH" >&2
  exit 1
fi

if [[ "${ACTION}" == "test" || "${ACTION}" == "run" ]]; then
  if [[ "${FORCE_NAMED_SYNC_TESTS}" != "1" ]]; then
    if [[ ! -d "/dev/shm" ]]; then
      echo "[SKIP] /dev/shm 不存在，跳过 fafafa.core.sync.namedBarrier（可设置 FAFAFA_FORCE_NAMED_SYNC_TESTS=1 强制运行）"
      exit 0
    fi

    PROBE_FILE="/dev/shm/fafafa_named_probe_$$"
    if ! (umask 077 && : > "${PROBE_FILE}") 2>/dev/null; then
      echo "[SKIP] /dev/shm 不可写，跳过 fafafa.core.sync.namedBarrier（受限环境常见；可设置 FAFAFA_FORCE_NAMED_SYNC_TESTS=1 强制运行）"
      exit 0
    fi
    rm -f "${PROBE_FILE}" 2>/dev/null || true
  fi
fi

rm -rf ./bin ./lib/*-*/
mkdir -p ./bin ./lib

echo "[BUILD] ${LAZBUILD_BIN} ${PROJECT_LPI}"
"${LAZBUILD_BIN}" "${PROJECT_LPI}"

if [[ "${ACTION}" == "test" || "${ACTION}" == "run" ]]; then
  echo "[RUN] ${TEST_BIN}"
  if [[ -x "${TEST_BIN}" ]]; then
    "${TEST_BIN}" --all --format=plain
  elif [[ -x "${TEST_BIN}.exe" ]]; then
    "${TEST_BIN}.exe" --all --format=plain
  else
    echo "[ERROR] test executable not found: ${TEST_BIN}[.exe]" >&2
    exit 100
  fi
else
  echo "[INFO] build-only mode (${ACTION})"
fi
