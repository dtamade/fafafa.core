#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TARGET_SCRIPT="${REPO_ROOT}/tests/check_strict_l0_docs_consistency.sh"

fail() {
  echo "[FAIL] $1" >&2
  exit 1
}

OUTPUT="$(bash "${TARGET_SCRIPT}" 2>&1)" || fail "docs consistency script failed to satisfy contract"

printf '%s\n' "${OUTPUT}" | rg -F "[PASS] strict L0 docs consistency verified" >/dev/null \
  || fail "docs consistency script did not report PASS marker"
printf '%s\n' "${OUTPUT}" | rg -F "docs/README.md" >/dev/null \
  || fail "docs consistency script did not mention docs/README.md"
printf '%s\n' "${OUTPUT}" | rg -F "docs/INDEX.md" >/dev/null \
  || fail "docs consistency script did not mention docs/INDEX.md"
printf '%s\n' "${OUTPUT}" | rg -F "workers/worker1.md" >/dev/null \
  || fail "docs consistency script did not mention workers/worker1.md"

echo "[PASS] strict L0 docs consistency contract verified"
