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

require_absent() {
  local aPath="$1"
  [[ ! -e "${REPO_ROOT}/${aPath}" ]] || fail "expected archived-away path to be absent: ${aPath}"
}

require_literal() {
  local aPath="$1"
  local aPattern="$2"
  rg -n -F "${aPattern}" "${REPO_ROOT}/${aPath}" >/dev/null \
    || fail "missing literal in ${aPath}: ${aPattern}"
}

for LPath in \
  "docs/benchmarks/reports/README.md" \
  "docs/collections/reports/README.md" \
  "docs/reports/README.md" \
  "archive/reports/docs-benchmarks/PERFORMANCE_OPTIMIZATION_REPORT.md" \
  "archive/reports/docs-collections/COLLECTIONS_WORK_SUMMARY.md" \
  "archive/reports/docs-root/COMPILATION_FIX_REPORT.md" \
  "archive/reports/docs-root/fafafa.core.mem.final-verification.md" \
  "archive/reports/docs-root/test_report_week1_day2.md"; do
  require_file "${LPath}"
done

for LPath in \
  "docs/benchmarks/reports/PERFORMANCE_OPTIMIZATION_REPORT.md" \
  "docs/collections/reports/COLLECTIONS_WORK_SUMMARY.md" \
  "docs/COMPILATION_FIX_REPORT.md" \
  "docs/fafafa.core.mem.final-verification.md" \
  "docs/test_report_week1_day2.md"; do
  require_absent "${LPath}"
done

require_literal "docs/benchmarks/reports/README.md" "archive/reports/docs-benchmarks/"
require_literal "docs/collections/reports/README.md" "archive/reports/docs-collections/"
require_literal "docs/reports/README.md" "archive/reports/docs-root/"

echo "[PASS] strict L0 archive reports layout contract verified"
