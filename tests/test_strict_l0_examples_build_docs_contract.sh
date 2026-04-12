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

echo "[PASS] strict L0 examples/build docs contract verified"
