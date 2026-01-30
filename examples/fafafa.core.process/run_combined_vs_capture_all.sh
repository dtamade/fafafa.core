#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

# Try to compile the example
if [[ ! -f bin/example_combined_vs_capture_all ]]; then
  fpc -MObjFPC -Scaghi -O1 -gw3 -gl -gh -Xg -gt -vewnhibq \
    -Fi"lib" -Fi"../../src" -Fu"../../src" \
    -FU"lib" -FE"bin" -obin/example_combined_vs_capture_all \
    example_combined_vs_capture_all.lpr || true
fi

if [[ -x bin/example_combined_vs_capture_all ]]; then
  ./bin/example_combined_vs_capture_all
elif [[ -f bin/example_combined_vs_capture_all.exe ]]; then
  echo "[WARN] Running Windows EXE on Unix is not supported."
else
  echo "[ERROR] Build failed (no binary)." >&2
  exit 1
fi

