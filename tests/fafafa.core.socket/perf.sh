#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNNER="$SCRIPT_DIR/buildOrTest.sh"

# Defaults if not provided
: "${PERF_TCP_SHORT_CONN_C:=20}"
: "${PERF_TCP_LONG_CLIENTS:=3}"
: "${PERF_TCP_LONG_ITER:=50}"
: "${PERF_PAYLOAD_SIZE:=256}"
: "${PERF_ACCEPT_TIMEOUT_MS:=1000}"
: "${PERF_UDP_PACKETS:=200}"
: "${PERF_UDP_RECV_TIMEOUT_MS:=10}"

"$RUNNER" test-perf

