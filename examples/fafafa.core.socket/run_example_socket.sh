#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BIN="$PROJECT_ROOT/bin"
LPI="$SCRIPT_DIR/example_socket.lpi"

if [ ! -x "$BIN/example_socket" ]; then
  echo "Building example_socket..."
  if command -v lazbuild >/dev/null 2>&1; then
    lazbuild "$LPI"
  else
    echo "ERROR: lazbuild not found in PATH." >&2
    exit 1
  fi
fi

"$BIN/example_socket" "$@"

