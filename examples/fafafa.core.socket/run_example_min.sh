#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN="$DIR/bin"
SERVER="$BIN/echo_server"
CLIENT="$BIN/example_echo_min_poll_nb"

if [[ ! -x "$SERVER" ]]; then
  echo "[run_example_min] server not found. Building examples..."
  bash "$DIR/build_examples.sh"
fi
if [[ ! -x "$SERVER" ]]; then
  echo "[run_example_min] server still not found at $SERVER"
  exit 1
fi
if [[ ! -x "$CLIENT" ]]; then
  echo "[run_example_min] client not found. Building examples..."
  bash "$DIR/build_examples.sh"
fi
if [[ ! -x "$CLIENT" ]]; then
  echo "[run_example_min] client still not found at $CLIENT"
  exit 1
fi

echo "[run_example_min] starting server on port 8080..."
"$SERVER" --port=8080 &
SERVER_PID=$!
sleep 0.5

echo "[run_example_min] running minimal client..."
"$CLIENT"

# Optional: stop server if desired
kill "$SERVER_PID" >/dev/null 2>&1 || true

