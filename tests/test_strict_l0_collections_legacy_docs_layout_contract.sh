#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

fail() {
  echo "[FAIL] $1" >&2
  exit 1
}

require_file() {
  local aPath="$1"
  [[ -f "${REPO_ROOT}/${aPath}" ]] || fail "missing required file: ${aPath}"
}

reject_file() {
  local aPath="$1"
  [[ ! -e "${REPO_ROOT}/${aPath}" ]] || fail "stale path still exists: ${aPath}"
}

require_literal() {
  local aPath="$1"
  local aLiteral="$2"
  rg -F --quiet -- "${aLiteral}" "${REPO_ROOT}/${aPath}" \
    || fail "${aPath} missing literal: ${aLiteral}"
}

reject_literal() {
  local aPath="$1"
  local aLiteral="$2"
  if rg -F --quiet -- "${aLiteral}" "${REPO_ROOT}/${aPath}"; then
    fail "${aPath} still contains stale literal: ${aLiteral}"
  fi
}

LEGACY_FILES=(
  "docs/collections/legacy/README.md"
  "docs/collections/legacy/COLLECTIONS_REFINEMENT_PLAN.md"
  "docs/collections/legacy/COLLECTIONS_NEW_CONTAINERS_PLAN_2025-11-03.md"
  "docs/collections/legacy/COLLECTIONS_CURRENT_STATUS_2025-11-03.md"
  "docs/collections/legacy/COLLECTIONS_OVERVIEW_2025-11-03.md"
  "docs/collections/legacy/COLLECTIONS_API_CONSISTENCY_REVIEW_2025-11-03.md"
  "docs/collections/legacy/COLLECTIONS_CODE_QUALITY_REVIEW_2025-11-03.md"
)

STALE_FILES=(
  "docs/collections/plans/COLLECTIONS_REFINEMENT_PLAN.md"
  "docs/collections/plans/COLLECTIONS_NEW_CONTAINERS_PLAN_2025-11-03.md"
  "docs/collections/status/COLLECTIONS_CURRENT_STATUS_2025-11-03.md"
  "docs/collections/status/COLLECTIONS_OVERVIEW_2025-11-03.md"
  "docs/collections/reviews/COLLECTIONS_API_CONSISTENCY_REVIEW_2025-11-03.md"
  "docs/collections/reviews/COLLECTIONS_CODE_QUALITY_REVIEW_2025-11-03.md"
)

for LPath in "${LEGACY_FILES[@]}"; do
  require_file "${LPath}"
done

for LPath in "${STALE_FILES[@]}"; do
  reject_file "${LPath}"
done

require_file "docs/collections/guides/UnChecked_Methods_Summary.md"
reject_file "docs/reports/UnChecked_Methods_Summary.md"

require_literal "docs/fafafa.core.collections.md" "docs/collections/legacy/README.md"

require_literal "docs/fafafa.core.collections.arr.md" "docs/collections/guides/UnChecked_Methods_Summary.md"
reject_literal "docs/fafafa.core.collections.arr.md" "docs/UnChecked_Methods_Summary.md"

require_literal "docs/fafafa.core.collections.vec.md" "docs/collections/guides/UnChecked_Methods_Summary.md"
reject_literal "docs/fafafa.core.collections.vec.md" "docs/UnChecked_Methods_Summary.md"

require_literal "docs/fafafa.core.collections.vecdeque.md" "docs/collections/guides/TVecDeque_Guide.md"
reject_literal "docs/fafafa.core.collections.vecdeque.md" "docs/TVecDeque_Guide.md"

require_literal "docs/collections/guides/README_VecDeque.md" "docs/collections/guides/UnChecked_Methods_Summary.md"
reject_literal "docs/collections/guides/README_VecDeque.md" "docs/UnChecked_Methods_Summary.md"

echo "[PASS] strict L0 collections legacy docs layout contract verified"
