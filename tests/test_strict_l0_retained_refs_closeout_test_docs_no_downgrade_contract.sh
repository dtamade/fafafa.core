#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

fail() {
  echo "[FAIL] $1" >&2
  exit 1
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

COMMON_DOCS=(
  "tests/fafafa.core.endian/README.md"
  "tests/fafafa.core.layout/README.md"
  "tests/fafafa.core.mem.allocator.foundation/README.md"
  "tests/fafafa.core.platform/README.md"
  "tests/fafafa.core.span/README.md"
)

for LPath in "${COMMON_DOCS[@]}"; do
  require_literal "${LPath}" "bash tests/run_strict_l0_maintenance_loop.sh"
  require_literal "${LPath}" "exact Windows native evidence 只接受 GitHub Actions 或真实 Windows runner 产物。"
done

ATOMIC_DOC="tests/fafafa.core.atomic/README.md"
require_literal "${ATOMIC_DOC}" "bash tests/run_strict_l0_maintenance_loop.sh"
require_literal "${ATOMIC_DOC}" "exact Windows native evidence 只接受 GitHub Actions 或真实 Windows runner 产物。"
require_literal "${ATOMIC_DOC}" '`logs/` 下的 build/test 日志与 heaptrc 输出仅用于本地验证，不纳入版本库'
reject_literal "${ATOMIC_DOC}" "atomic_heaptrc_full_output.txt"

echo "[PASS] strict L0 closeout test-doc no-downgrade contract verified"
