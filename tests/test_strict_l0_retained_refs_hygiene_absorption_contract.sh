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

require_untracked() {
  local aPath="$1"
  if git -C "${REPO_ROOT}" ls-files --error-unmatch "${aPath}" >/dev/null 2>&1; then
    fail "path should not be tracked after hygiene absorb: ${aPath}"
  fi
}

require_literal() {
  local aPath="$1"
  local aLiteral="$2"
  rg -F "${aLiteral}" "${REPO_ROOT}/${aPath}" >/dev/null \
    || fail "missing literal in ${aPath}: ${aLiteral}"
}

reject_literal() {
  local aPath="$1"
  local aLiteral="$2"
  if rg -F "${aLiteral}" "${REPO_ROOT}/${aPath}" >/dev/null; then
    fail "stale literal should be absent in ${aPath}: ${aLiteral}"
  fi
}

require_file "tests/fafafa.core.archiver/.gitignore"
require_file "tests/fafafa.core.atomic/.gitignore"
require_file "tests/fafafa.core.fs/performance-data/.gitignore"
require_file "tests/fafafa.core.sync.barrier/.gitignore"

require_untracked "tests/fafafa.core.archiver/last-run.txt"
require_untracked "tests/fafafa.core.atomic/atomic_heaptrc_full_output.txt"
require_untracked "tests/fafafa.core.atomic/tests_atomic"
require_untracked "tests/fafafa.core.sync.barrier/all_test_output.txt"
require_untracked "tests/fafafa.core.sync.barrier/barrier_heaptrc_full_output.txt"
require_untracked "tests/fafafa.core.sync.barrier/barrier_heaptrc_output.txt"
require_untracked "tests/fafafa.core.sync.barrier/global_test_output.txt"
require_untracked "tests/fafafa.core.sync.barrier/ibarrier_test_output.txt"
require_untracked "tests/fafafa.core.sync.barrier/test_output.txt"
require_untracked "tests/fafafa.core.fs/performance-data/latest.txt"
require_untracked "tests/fafafa.core.fs/performance-data/perf_2025-08-12_周二-21-39.txt"
require_untracked "tests/fafafa.core.fs/performance-data/perf_2025-08-15_周五-0-11.txt"
require_untracked "tests/fafafa.core.fs/performance-data/perf_2025-08-15_周五-5-46.txt"
require_untracked "tests/fafafa.core.fs/performance-data/perf_2025-08-15_周五-5-47.txt"
require_untracked "tests/fafafa.core.fs/performance-data/perf_2025-08-15_周五-5-48.txt"
require_untracked "tests/fafafa.core.fs/performance-data/perf_2025-08-15_周五-5-49.txt"
require_untracked "tests/fafafa.core.fs/performance-data/perf_2025-08-15_周五-6-23.txt"
require_untracked "tests/fafafa.core.fs/performance-data/perf_all_latest.txt"
require_untracked "tests/fafafa.core.fs/performance-data/perf_resolve_2025-08-22_周五_23-48-42-31.txt"
require_untracked "tests/fafafa.core.fs/performance-data/perf_resolve_2025-08-22_周五_23-53-46-16.txt"
require_untracked "tests/fafafa.core.fs/performance-data/perf_resolve_2025-08-23_周六_00-00-25-01.txt"
require_untracked "tests/fafafa.core.fs/performance-data/perf_resolve_2025-08-23_周六_00-25-20-68.txt"
require_untracked "tests/fafafa.core.fs/performance-data/perf_resolve_2025-08-23_周六_00-28-57-48.txt"
require_untracked "tests/fafafa.core.fs/performance-data/perf_resolve_2025-08-23_周六_03-43-38-75.txt"
require_untracked "tests/fafafa.core.fs/performance-data/perf_resolve_2025-08-23_周六_04-09-47-10.txt"
require_untracked "tests/fafafa.core.fs/performance-data/perf_resolve_latest.txt"
require_untracked "tests/fafafa.core.fs/performance-data/perf_walk_latest.txt"

require_literal "tests/fafafa.core.atomic/.gitignore" "atomic_heaptrc_full_output.txt"
require_literal "tests/fafafa.core.atomic/.gitignore" "tests_atomic"
require_literal "tests/fafafa.core.archiver/.gitignore" "last-run.txt"
require_literal "tests/fafafa.core.sync.barrier/.gitignore" "all_test_output.txt"
require_literal "tests/fafafa.core.sync.barrier/.gitignore" "test_output.txt"
require_literal "tests/fafafa.core.fs/performance-data/.gitignore" "perf_resolve_latest.txt"
require_literal "tests/fafafa.core.fs/performance-data/.gitignore" "perf_walk_latest.txt"
require_literal "tests/fafafa.core.atomic/README.md" "运行期产物"
require_literal "tests/fafafa.core.atomic/README.md" 'logs/` 下的 build/test 日志与 heaptrc 输出仅用于本地验证，不纳入版本库'
reject_literal "tests/fafafa.core.atomic/README.md" "atomic_heaptrc_full_output.txt"

echo "[PASS] strict L0 retained refs hygiene absorption contract verified"
