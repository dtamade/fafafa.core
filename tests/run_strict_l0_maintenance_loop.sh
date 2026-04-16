#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

STRICT_L0_MODULES=(
  "fafafa.core.base"
  "fafafa.core.contracts"
  "fafafa.core.bits"
  "fafafa.core.layout"
  "fafafa.core.endian"
  "fafafa.core.span"
  "fafafa.core.option"
  "fafafa.core.result"
  "fafafa.core.atomic"
  "fafafa.core.mem.allocator.foundation"
  "fafafa.core.platform"
)

print_commands() {
  printf '%s\n' "bash tests/check_strict_l0_docs_consistency.sh"
  printf '%s\n' "bash tests/check_repo_submodule_hygiene.sh"
  printf '%s\n' "bash tests/test_active_shell_runners.sh"
  printf '%s\n' "bash tests/test_strict_l0_sync_mutex_example_older_fpc_contract.sh"
  printf '%s\n' "bash tests/test_strict_l0_examples_build_docs_contract.sh"
  printf '%s\n' "bash tests/test_strict_l0_examples_smoke_contract.sh"
  printf '%s\n' "STOP_ON_FAIL=1 bash tests/run_all_tests.sh ${STRICT_L0_MODULES[*]}"
  printf '%s\n' "git diff --check"
  printf '%s\n' "bash tests/test_windows_strict_l0_batch_runtime_matrix.sh"
  printf '%s\n' "bash tests/test_windows_strict_l0_native_closeout_stack.sh"
}

print_help() {
  cat <<'EOF'
Usage:
  bash tests/run_strict_l0_maintenance_loop.sh
  bash tests/run_strict_l0_maintenance_loop.sh --print-commands

This script runs the strict non-SIMD L0 Linux x64 maintenance loop.
EOF
}

run_case() {
  local aLabel="$1"
  shift
  echo "[INFO] ${aLabel}"
  "$@"
}

case "${1:-}" in
  --print-commands)
    print_commands
    exit 0
    ;;
  --help|-h)
    print_help
    exit 0
    ;;
  "")
    ;;
  *)
    echo "[FAIL] unknown argument: ${1}" >&2
    print_help >&2
    exit 2
    ;;
esac

run_case "strict L0 docs consistency" \
  bash "${REPO_ROOT}/tests/check_strict_l0_docs_consistency.sh"
run_case "strict L0 repo submodule metadata hygiene" \
  bash "${REPO_ROOT}/tests/check_repo_submodule_hygiene.sh"
run_case "strict L0 active shell runners" \
  bash "${REPO_ROOT}/tests/test_active_shell_runners.sh"
run_case "strict L0 sync.mutex older-FPC example contract" \
  bash "${REPO_ROOT}/tests/test_strict_l0_sync_mutex_example_older_fpc_contract.sh"
run_case "strict L0 examples/build current-entry contract" \
  bash "${REPO_ROOT}/tests/test_strict_l0_examples_build_docs_contract.sh"
run_case "strict L0 examples current-entry build smoke" \
  bash "${REPO_ROOT}/tests/test_strict_l0_examples_smoke_contract.sh"
run_case "strict L0 aggregate gate" \
  env STOP_ON_FAIL=1 bash "${REPO_ROOT}/tests/run_all_tests.sh" "${STRICT_L0_MODULES[@]}"
run_case "strict L0 diff hygiene" \
  git -C "${REPO_ROOT}" diff --check
run_case "strict L0 Windows batch runtime matrix" \
  bash "${REPO_ROOT}/tests/test_windows_strict_l0_batch_runtime_matrix.sh"
run_case "strict L0 Windows native closeout stack" \
  bash "${REPO_ROOT}/tests/test_windows_strict_l0_native_closeout_stack.sh"

echo "[PASS] strict L0 maintenance loop verified"
