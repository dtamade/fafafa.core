#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

# Try to compile the example
if [[ ! -f bin/example_silent_interactive ]]; then
  fpc -MObjFPC -Scaghi -O1 -gw3 -gl -gh -Xg -gt -vewnhibq \
    -Fi"lib" -Fi"../../src" -Fu"../../src" \
    -FU"lib" -FE"bin" -obin/example_silent_interactive \
    example_silent_interactive.lpr || true
fi

if [[ -x bin/example_silent_interactive ]]; then
  ./bin/example_silent_interactive
elif [[ -f bin/example_silent_interactive.exe ]]; then
  echo "[WARN] Running Windows EXE on Unix is not supported."
else
  echo "[ERROR] Build failed (no binary)." >&2
  exit 1
fi

