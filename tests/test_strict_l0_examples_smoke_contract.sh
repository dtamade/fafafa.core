#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

run_case() {
  local aLabel="$1"
  shift
  echo "[INFO] ${aLabel}"
  "$@"
}

run_case "strict L0 atomic current-entry build smoke" \
  bash "${REPO_ROOT}/examples/fafafa.core.atomic/BuildOrRun.sh" build
run_case "strict L0 env current-entry build smoke" \
  bash "${REPO_ROOT}/examples/fafafa.core.env/BuildOrRun.sh" build quickstart
run_case "strict L0 platform current-entry build smoke" \
  bash "${REPO_ROOT}/examples/fafafa.core.platform/BuildOrRun.sh" build
run_case "strict L0 json current-entry build smoke" \
  bash "${REPO_ROOT}/examples/fafafa.core.json/BuildOrRun.sh" build
run_case "strict L0 sync.mutex current-entry build smoke" \
  bash "${REPO_ROOT}/examples/fafafa.core.sync.mutex/BuildOrRun.sh" build

echo "[PASS] strict L0 examples smoke contract verified"
