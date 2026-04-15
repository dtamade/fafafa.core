#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

fail() {
  echo "[FAIL] $1" >&2
  exit 1
}

require_bash_entry_contract() {
  local aPath="$1"
  local LMode
  local LShebang

  require_file "${aPath}"

  LShebang="$(head -n 1 "${REPO_ROOT}/${aPath}")"
  [[ "${LShebang}" == "#!/usr/bin/env bash" || "${LShebang}" == "#!/bin/bash" ]] \
    || fail "${aPath} missing bash shebang"

  if grep -n $'\r$' "${REPO_ROOT}/${aPath}" >/dev/null; then
    fail "${aPath} still contains CRLF line endings"
  fi

  bash -n "${REPO_ROOT}/${aPath}" || fail "bash -n failed: ${aPath}"
  [[ -x "${REPO_ROOT}/${aPath}" ]] || fail "${aPath} must be executable in the working tree"

  LMode="$(git -C "${REPO_ROOT}" ls-files -s -- "${aPath}" | awk '{print $1}')"
  [[ -n "${LMode}" ]] || fail "${aPath} is not tracked in git"
  [[ "${LMode}" == "100755" ]] || fail "${aPath} must be tracked as mode 100755 (got ${LMode})"
}

require_file() {
  local aPath="$1"
  [[ -f "${REPO_ROOT}/${aPath}" ]] || fail "missing required file: ${aPath}"
}

require_literal() {
  local aPath="$1"
  local aLiteral="$2"
  rg -F --quiet -- "${aLiteral}" "${REPO_ROOT}/${aPath}" \
    || fail "${aPath} missing literal: ${aLiteral}"
}

REQUIRED_FILES=(
  "docs/EXAMPLES.md"
  "examples/fafafa.core.base/README.md"
  "examples/fafafa.core.option/README.md"
  "examples/fafafa.core.env/README.md"
  "examples/fafafa.core.atomic/README.md"
  "examples/fafafa.core.json/README.md"
  "examples/fafafa.core.sync.mutex/README.md"
  "examples/fafafa.core.result/README.md"
  "examples/fafafa.core.platform/README.md"
)

for LPath in "${REQUIRED_FILES[@]}"; do
  require_file "${LPath}"
done

require_literal "docs/EXAMPLES.md" "examples/fafafa.core.base/README.md"
require_literal "docs/EXAMPLES.md" "examples/fafafa.core.option/README.md"
require_literal "docs/EXAMPLES.md" "examples/fafafa.core.env/README.md"
require_literal "docs/EXAMPLES.md" "examples/fafafa.core.atomic/README.md"
require_literal "docs/EXAMPLES.md" "examples/fafafa.core.json/README.md"
require_literal "docs/EXAMPLES.md" "examples/fafafa.core.sync.mutex/README.md"
require_literal "docs/EXAMPLES.md" "examples/fafafa.core.result/README.md"
require_literal "docs/EXAMPLES.md" "examples/fafafa.core.platform/README.md"
require_literal "docs/EXAMPLES.md" 'bin/`、`lib/` 和本地 logs 只代表生成产物，不是 source-of-truth。'

for LPath in \
  "examples/fafafa.core.base/README.md" \
  "examples/fafafa.core.option/README.md" \
  "examples/fafafa.core.env/README.md" \
  "examples/fafafa.core.atomic/README.md" \
  "examples/fafafa.core.json/README.md" \
  "examples/fafafa.core.sync.mutex/README.md" \
  "examples/fafafa.core.result/README.md" \
  "examples/fafafa.core.platform/README.md"; do
  require_literal "${LPath}" 'bin/` 和 `lib/` 只代表本地构建结果，不是 source-of-truth。'
done

require_literal "examples/fafafa.core.base/README.md" "examples/fafafa.core.base/BuildOrRun.sh"
require_literal "examples/fafafa.core.option/README.md" "examples/fafafa.core.option/BuildOrRun.sh"
require_literal "examples/fafafa.core.env/README.md" "examples/fafafa.core.env/BuildOrRun.sh"
require_literal "examples/fafafa.core.atomic/README.md" "examples/fafafa.core.atomic/BuildOrRun.sh"
require_literal "examples/fafafa.core.json/README.md" "examples/fafafa.core.json/BuildOrRun.sh"
require_literal "examples/fafafa.core.sync.mutex/README.md" "examples/fafafa.core.sync.mutex/BuildOrRun.sh"
require_literal "examples/fafafa.core.result/README.md" "examples/fafafa.core.result/BuildOrRun.sh"
require_literal "examples/fafafa.core.platform/README.md" "examples/fafafa.core.platform/BuildOrRun.sh"

for LPath in \
  "examples/fafafa.core.base/BuildOrRun.sh" \
  "examples/fafafa.core.option/BuildOrRun.sh" \
  "examples/fafafa.core.env/BuildOrRun.sh" \
  "examples/fafafa.core.atomic/BuildOrRun.sh" \
  "examples/fafafa.core.json/BuildOrRun.sh" \
  "examples/fafafa.core.sync.mutex/BuildOrRun.sh" \
  "examples/fafafa.core.result/BuildOrRun.sh" \
  "examples/fafafa.core.platform/BuildOrRun.sh"; do
  require_bash_entry_contract "${LPath}"
done

echo "[PASS] strict L0 examples/build docs contract verified"
