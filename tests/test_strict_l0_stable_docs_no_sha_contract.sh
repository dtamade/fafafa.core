#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TARGET_SCRIPT="${REPO_ROOT}/tests/check_strict_l0_docs_consistency.sh"

fail() {
  echo "[FAIL] $1" >&2
  exit 1
}

OUTPUT="$(bash "${TARGET_SCRIPT}" 2>&1)" || fail "docs consistency script failed while checking stable docs sha contract"

printf '%s\n' "${OUTPUT}" | rg -F "[CHECK] transient main SHA absent in docs/README.md" >/dev/null \
  || fail "docs consistency script did not verify README transient SHA removal"
printf '%s\n' "${OUTPUT}" | rg -F "[CHECK] transient main SHA absent in docs/INDEX.md" >/dev/null \
  || fail "docs consistency script did not verify INDEX transient SHA removal"
printf '%s\n' "${OUTPUT}" | rg -F "[CHECK] transient main SHA absent in docs/CI.md" >/dev/null \
  || fail "docs consistency script did not verify CI transient SHA removal"
printf '%s\n' "${OUTPUT}" | rg -F "[CHECK] transient main SHA absent in docs/fafafa.core.l0.roadmap.md" >/dev/null \
  || fail "docs consistency script did not verify roadmap transient SHA removal"

echo "[PASS] strict L0 stable docs no-sha contract verified"
