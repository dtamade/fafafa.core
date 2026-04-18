#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT="${SCRIPT_DIR}/tests_mem_allocator_only.lpi"
EXECUTABLE="${SCRIPT_DIR}/bin/tests_mem_allocator_only"

LAZARUSDIR="${LAZARUSDIR:-}"
LAZBUILD="${LAZBUILD:-lazbuild}"
LAZARUS_OPT=()
if [ -n "${LAZARUSDIR}" ]; then
  LAZARUS_OPT+=(--lazarusdir="${LAZARUSDIR}")
elif [ -d "/opt/fpcupdeluxe/lazarus/lcl" ]; then
  LAZARUS_OPT+=(--lazarusdir="/opt/fpcupdeluxe/lazarus")
fi

# Clean previous build artifacts
rm -rf "${SCRIPT_DIR}/bin" "${SCRIPT_DIR}/lib"
mkdir -p "${SCRIPT_DIR}/bin" "${SCRIPT_DIR}/lib"

echo "Building project: ${PROJECT} (Debug)"
if ! "${LAZBUILD}" "${LAZARUS_OPT[@]}" "${PROJECT}"; then
  # lazbuild 在某些最小配置环境下会在成功编译后返回非 0（例如输出 "File not found: \"\""），
  # 这里以生成的可执行文件是否存在作为最终判定，避免阻断测试执行。
  if [ ! -x "${EXECUTABLE}" ]; then
    echo
    echo "Build failed."
    exit 1
  fi
fi

echo
echo "Build successful."

echo "Running tests..."
if ! "${EXECUTABLE}" --all --format=plain; then
  echo
  echo "Tests failed!"
  exit 1
fi

echo
echo "All tests passed."
exit 0
