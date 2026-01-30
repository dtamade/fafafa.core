#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

echo "[BUILD] lazbuild --build-mode=Debug *.lpi"
lazbuild --build-mode=Debug *.lpi

echo "[RUN] Running example..."
for exe in bin/*; do
  if [ -x "$exe" ] && [ ! -d "$exe" ]; then
    echo "[RUN] $exe"
    "$exe"
  fi
done
