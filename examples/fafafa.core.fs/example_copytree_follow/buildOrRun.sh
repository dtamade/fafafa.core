#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

if command -v lazbuild >/dev/null 2>&1; then
  lazbuild example_copytree_follow.lpi
else
  fpc -MObjFPC -Scghi -O1 -g -gl -vewnhibq -Fi. -Fi../../../src -Fu../../../src -o./bin/example_copytree_follow example_copytree_follow.lpr
fi

./bin/example_copytree_follow

