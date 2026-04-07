#!/usr/bin/env bash
set -euo pipefail

echo "==========================================="
echo "集合性能基准测试 - 简化版"
echo "==========================================="
echo

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_FILE="${SCRIPT_DIR}/simple_benchmark.lpi"
MAIN_FILE="${SCRIPT_DIR}/simple_benchmark.lpr"
BIN_DIR="${SCRIPT_DIR}/bin"
LIB_DIR="${SCRIPT_DIR}/lib/fpc"
EXECUTABLE="${BIN_DIR}/collections_performance_benchmark"
LAZBUILD_BIN="${LAZBUILD:-lazbuild}"
FPC_BIN="${FPC:-fpc}"

mkdir -p "${BIN_DIR}"

resolve_fpc() {
  local laz_path
  local root_dir
  local candidate

  if [[ -x "${FPC_BIN}" ]]; then
    echo "${FPC_BIN}"
    return 0
  fi

  if command -v "${FPC_BIN}" >/dev/null 2>&1; then
    command -v "${FPC_BIN}"
    return 0
  fi

  if command -v "${LAZBUILD_BIN}" >/dev/null 2>&1; then
    laz_path="$(command -v "${LAZBUILD_BIN}")"
    root_dir="$(cd "$(dirname "${laz_path}")/.." && pwd)"
    candidate="${root_dir}/fpc/bin/$(uname -m)-$(uname | tr '[:upper:]' '[:lower:]')/fpc"
    if [[ -x "${candidate}" ]]; then
      echo "${candidate}"
      return 0
    fi
  fi

  return 1
}

build_with_lazbuild() {
  if ! command -v "${LAZBUILD_BIN}" >/dev/null 2>&1; then
    return 1
  fi

  echo "[BUILD] lazbuild ${PROJECT_FILE} (project default mode)"
  "${LAZBUILD_BIN}" "${PROJECT_FILE}"
}

build_with_fpc() {
  local fpc

  fpc="$(resolve_fpc)" || {
    echo "编译失败: 找不到可用的 fpc 编译器" >&2
    return 1
  }

  mkdir -p "${BIN_DIR}" "${LIB_DIR}"
  echo "[BUILD] fpc ${MAIN_FILE} -> ${EXECUTABLE}"
  (
    cd "${SCRIPT_DIR}"
    "${fpc}" -MObjFPC -Scaghi -O1 -g -gl -l -vewnhibq \
      -Fu../../src -Fu. \
      -FU"${LIB_DIR}" \
      -o"${EXECUTABLE}" \
      "$(basename "${MAIN_FILE}")"
  )
}

resolve_executable() {
  if [[ -x "${EXECUTABLE}" ]]; then
    echo "${EXECUTABLE}"
    return 0
  fi

  if [[ -x "${EXECUTABLE}.exe" ]]; then
    echo "${EXECUTABLE}.exe"
    return 0
  fi

  return 1
}

if build_with_lazbuild; then
  if resolved_exe="$(resolve_executable)"; then
    EXECUTABLE="${resolved_exe}"
  else
    echo "[WARN] lazbuild completed but executable not found, falling back to fpc" >&2
    build_with_fpc
    EXECUTABLE="$(resolve_executable)"
  fi
else
  echo "[WARN] lazbuild build failed, falling back to fpc" >&2
  build_with_fpc
  EXECUTABLE="$(resolve_executable)"
fi

if [[ ! -x "${EXECUTABLE}" ]]; then
  echo "编译失败: 未找到可执行文件 ${EXECUTABLE}" >&2
  exit 1
fi

echo
echo "运行基准测试..."
echo "==========================================="
"${EXECUTABLE}"
echo "==========================================="
echo "基准测试完成!"
