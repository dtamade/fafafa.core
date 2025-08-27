#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$REPO_ROOT"

mkdir -p tests/fafafa.core.sync.event/bin

fpc tests/fafafa.core.sync.event/fafafa.core.sync.event.test.lpr \
  -B -FEtests/fafafa.core.sync.event/bin \
  -Fusrc -O2 -S2 -MObjFPC

exec tests/fafafa.core.sync.event/bin/fafafa.core.sync.event.test --all --progress --format=plain

