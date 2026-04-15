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

  [[ -f "${REPO_ROOT}/${aPath}" ]] || fail "missing file: ${aPath}"
}

require_literal() {
  local aPath="$1"
  local aLiteral="$2"

  rg -Fx --quiet -- "${aLiteral}" "${REPO_ROOT}/${aPath}" \
    || fail "${aPath} missing literal: ${aLiteral}"
}

require_not_tracked() {
  local aPath="$1"

  if git -C "${REPO_ROOT}" ls-files --error-unmatch "${aPath}" >/dev/null 2>&1; then
    fail "${aPath} is still tracked"
  fi
}

require_file "tests/fafafa.core.env/.gitignore"
require_literal "tests/fafafa.core.env/.gitignore" "build_log.txt"
require_literal "tests/fafafa.core.env/.gitignore" "fpcdebug.txt"
require_not_tracked "tests/fafafa.core.env/build_log.txt"
require_not_tracked "tests/fafafa.core.env/fpcdebug.txt"

require_file "tests/fafafa.core.mem.manager.rtl/.gitignore"
require_literal "tests/fafafa.core.mem.manager.rtl/.gitignore" "mem_manager_heaptrc_output.txt"
require_not_tracked "tests/fafafa.core.mem.manager.rtl/mem_manager_heaptrc_output.txt"

echo "[PASS] strict L0 sidecar hygiene contract verified"
