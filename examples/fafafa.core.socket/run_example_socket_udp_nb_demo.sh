#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PORT="${1:-9098}"
MSG="${2:-}"

"$SCRIPT_DIR/run_example_socket.sh" udp-server-nb "$PORT" &
SERVER_PID=$!

sleep 1
"$SCRIPT_DIR/run_example_socket.sh" udp-client-nb 127.0.0.1 "$PORT" "$MSG"

kill "$SERVER_PID" >/dev/null 2>&1 || true

