#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TARGET_SCRIPT="${REPO_ROOT}/tests/run_strict_l0_maintenance_loop.sh"

fail() {
  echo "[FAIL] $1" >&2
  exit 1
}

OUTPUT="$(bash "${TARGET_SCRIPT}" --print-commands 2>&1)" || fail "maintenance loop script failed to satisfy contract"

printf '%s\n' "${OUTPUT}" | rg -F "check_strict_l0_docs_consistency.sh" >/dev/null \
  || fail "maintenance loop did not print docs consistency step"
printf '%s\n' "${OUTPUT}" | rg -F "check_repo_submodule_hygiene.sh" >/dev/null \
  || fail "maintenance loop did not print submodule hygiene step"
printf '%s\n' "${OUTPUT}" | rg -F "git diff --check" >/dev/null \
  || fail "maintenance loop did not print git diff step"
printf '%s\n' "${OUTPUT}" | rg -F "tests/run_all_tests.sh" >/dev/null \
  || fail "maintenance loop did not print strict L0 gate"
printf '%s\n' "${OUTPUT}" | rg -F "test_windows_strict_l0_batch_runtime_matrix.sh" >/dev/null \
  || fail "maintenance loop did not print runtime matrix step"
printf '%s\n' "${OUTPUT}" | rg -F "test_windows_strict_l0_native_closeout_stack.sh" >/dev/null \
  || fail "maintenance loop did not print native closeout stack step"

echo "[PASS] strict L0 maintenance loop contract verified"
