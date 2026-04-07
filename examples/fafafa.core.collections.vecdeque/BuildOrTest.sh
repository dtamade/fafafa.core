#!/usr/bin/env bash
set -euo pipefail

echo "========================================"
echo "fafafa.core.collections.vecdeque 示例构建脚本"
echo "========================================"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
PROJECT_FILE="${SCRIPT_DIR}/example_vecdeque.lpi"
OUTPUT_DIR="${PROJECT_ROOT}/bin"
LIB_DIR="${SCRIPT_DIR}/lib"
LAZBUILD_BIN="${LAZBUILD:-lazbuild}"

if ! command -v "${LAZBUILD_BIN}" >/dev/null 2>&1; then
  echo "错误: 找不到 lazbuild 命令: ${LAZBUILD_BIN}" >&2
  exit 1
fi

mkdir -p "${OUTPUT_DIR}" "${LIB_DIR}"

echo
echo "正在编译示例项目..."
echo "项目文件: ${PROJECT_FILE}"
echo "输出目录: ${OUTPUT_DIR}"
echo

echo "[BUILD] lazbuild ${PROJECT_FILE} (project default mode)"
"${LAZBUILD_BIN}" "${PROJECT_FILE}"

EXAMPLE_EXE="${OUTPUT_DIR}/example_vecdeque"
if [[ -x "${EXAMPLE_EXE}.exe" ]]; then
  EXAMPLE_EXE="${EXAMPLE_EXE}.exe"
fi

if [[ ! -x "${EXAMPLE_EXE}" ]]; then
  echo "错误: 找不到示例可执行文件 ${EXAMPLE_EXE}" >&2
  exit 1
fi

echo
echo "========================================"
echo "运行示例程序"
echo "========================================"
echo
echo "执行示例: ${EXAMPLE_EXE}"
echo

set +e
"${EXAMPLE_EXE}"
EXAMPLE_RESULT=$?
set -e

echo
echo "========================================"
if [[ ${EXAMPLE_RESULT} -eq 0 ]]; then
  echo "✅ 示例运行完成！"
else
  echo "❌ 示例运行出现错误！"
  echo "退出代码: ${EXAMPLE_RESULT}"
fi
echo "========================================"

exit "${EXAMPLE_RESULT}"
