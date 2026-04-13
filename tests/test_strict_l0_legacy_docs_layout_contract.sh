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

LEGACY_FILES=(
  "docs/legacy/l0/2026-04-07-l0-rescue-triage-audit.md"
  "docs/legacy/l0/2026-04-08-l0-tail-docs-audit.md"
  "docs/legacy/l0/2026-04-09-l0-current-state-audit.md"
  "docs/legacy/l0/2026-04-10-l0-current-state-audit.md"
  "docs/legacy/l0/2026-03-26-l0-candidates-platform-span-admission.md"
  "docs/legacy/l0/2026-03-26-strict-l0-merge-closeout.md"
  "docs/legacy/l0/2026-03-27-l0-control-plane-closeout.md"
  "docs/legacy/l0/2026-04-07-l0-rescue-split-closeout.md"
  "docs/legacy/l0/2026-04-09-l0-kernel-span2-closeout.md"
  "docs/legacy/l0/2026-04-09-l0-mainline-merge-checklist.md"
)

STALE_FILES=(
  "docs/audits/2026-04-07-l0-rescue-triage-audit.md"
  "docs/audits/2026-04-08-l0-tail-docs-audit.md"
  "docs/audits/2026-04-09-l0-current-state-audit.md"
  "docs/audits/2026-04-10-l0-current-state-audit.md"
  "docs/plans/2026-03-26-l0-candidates-platform-span-admission.md"
  "docs/plans/2026-03-26-strict-l0-merge-closeout.md"
  "docs/plans/2026-03-27-l0-control-plane-closeout.md"
  "docs/plans/2026-04-07-l0-rescue-split-closeout.md"
  "docs/plans/2026-04-09-l0-kernel-span2-closeout.md"
  "docs/plans/2026-04-09-l0-mainline-merge-checklist.md"
)

for LPath in "${LEGACY_FILES[@]}"; do
  require_file "${LPath}"
done

for LPath in "${STALE_FILES[@]}"; do
  reject_file "${LPath}"
done

require_literal "docs/README.md" "docs/legacy/l0/README.md"
require_literal "docs/INDEX.md" "docs/legacy/l0/README.md"
require_literal "docs/README.md" "docs/audits/2026-04-13-l0-retained-refs-sixth-absorption-audit.md"
require_literal "docs/INDEX.md" "docs/audits/2026-04-13-l0-retained-refs-sixth-absorption-audit.md"
require_literal "docs/legacy/l0/README.md" "2026-04-10-l0-current-state-audit.md"
require_literal "docs/legacy/l0/README.md" "2026-04-09-l0-kernel-span2-closeout.md"
require_literal "docs/legacy/l0/README.md" "2026-03-26-strict-l0-merge-closeout.md"

echo "[PASS] strict L0 legacy docs layout contract verified"
