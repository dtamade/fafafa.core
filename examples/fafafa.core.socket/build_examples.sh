#!/usr/bin/env bash
set -euo pipefail

echo "========================================"
echo "fafafa.core.socket 示例构建脚本"
echo "========================================"
echo

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
LAZBUILD_BIN="${LAZBUILD:-lazbuild}"
PROJECTS=(
  "example_socket.lpi"
  "echo_server.lpi"
  "echo_client.lpi"
  "udp_server.lpi"
  "udp_client.lpi"
  "example_echo_min_poll_nb.lpi"
)

echo "项目根目录: ${PROJECT_ROOT}"
echo "示例目录: ${SCRIPT_DIR}"
echo

if ! command -v "${LAZBUILD_BIN}" >/dev/null 2>&1; then
  echo "错误: 找不到 lazbuild 命令: ${LAZBUILD_BIN}" >&2
  exit 1
fi

for LProject in "${PROJECTS[@]}"; do
  echo "[BUILD] lazbuild ${LProject} (project default mode)"
  "${LAZBUILD_BIN}" "${SCRIPT_DIR}/${LProject}"
done

echo
echo "========================================"
echo "构建完成"
echo "========================================"
echo "已构建项目:"
for LProject in "${PROJECTS[@]}"; do
  echo "  ${LProject}"
done
