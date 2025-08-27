#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PORT="${1:-9099}"
MSG="${2:-}"

# 后台启动非阻塞服务器
"$SCRIPT_DIR/run_example_socket.sh" tcp-server-nb "$PORT" &
SERVER_PID=$!

# 等待服务器就绪
sleep 1

# 启动客户端完成一次往返
"$SCRIPT_DIR/run_example_socket.sh" tcp-client-nb 127.0.0.1 "$PORT" "$MSG"

# 清理后台服务（若仍在运行）
kill "$SERVER_PID" >/dev/null 2>&1 || true

