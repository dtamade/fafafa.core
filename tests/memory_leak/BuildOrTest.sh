#!/usr/bin/env bash
set -euo pipefail

TESTS_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LEAK_SCRIPT="$TESTS_ROOT/run_leak_tests.sh"

if [ ! -x "$LEAK_SCRIPT" ]; then
  echo "Leak test driver not found: $LEAK_SCRIPT" >&2
  exit 1
fi

# Allow callers to pass through any extra arguments (currently unused)
bash "$LEAK_SCRIPT" "$@"
