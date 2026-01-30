#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

# build (reusing build.sh or direct fpc, here we try lazbuild path first)
if [[ -x "build.sh" ]]; then
  ./build.sh || true
fi

# Try to compile only this example with fpc if binary not present
if [[ ! -f bin/example_autodrain ]]; then
  fpc -MObjFPC -Scaghi -O1 -gw3 -gl -gh -Xg -gt -vewnhibq \
    -dFAFAFA_PROCESS_GROUPS \
    -Fi"lib" -Fi"../../src" -Fu"../../src" \
    -FU"lib" -FE"bin" -obin/example_autodrain \
    example_autodrain.lpr || true
fi

if [[ ! -x bin/example_autodrain && ! -f bin/example_autodrain.exe ]]; then
  echo "[ERROR] Build failed (no binary)." >&2
  exit 1
fi

# Prefer non-.exe on Unix, else .exe via wine (optional)
if [[ -x bin/example_autodrain ]]; then
  ./bin/example_autodrain
else
  echo "[WARN] Running Windows exe under Unix is not supported in this script." >&2
  exit 1
fi

