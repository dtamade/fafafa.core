#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

TARGETS=(
  "tests/cleanup_orphan_dirs.sh"
  "tests/fafafa.core.fs/ArchivePerfResult.sh"
  "tests/fafafa.core.fs/BuildOrRunPerf.sh"
  "tests/fafafa.core.fs/BuildOrRunPerfAll.sh"
  "tests/fafafa.core.fs/BuildOrRunResolvePerf.sh"
)

fail() {
  echo "[FAIL] $1" >&2
  exit 1
}

require_file() {
  local aPath="$1"
  [[ -f "${REPO_ROOT}/${aPath}" ]] || fail "missing file: ${aPath}"
}

require_literal_in_file() {
  local aPath="$1"
  local aLiteral="$2"
  rg -F --quiet -- "${aLiteral}" "${REPO_ROOT}/${aPath}" \
    || fail "${aPath} missing literal: ${aLiteral}"
}

assert_no_crlf() {
  local aPath="$1"
  if grep -n $'\r$' "${REPO_ROOT}/${aPath}" >/dev/null; then
    fail "${aPath} still contains CRLF line endings"
  fi
}

assert_bash_syntax_ok() {
  local aPath="$1"
  bash -n "${REPO_ROOT}/${aPath}" || fail "bash -n failed: ${aPath}"
}

assert_bash_shebang() {
  local aPath="$1"
  local aShebang

  aShebang="$(head -n 1 "${REPO_ROOT}/${aPath}")"
  [[ "${aShebang}" == "#!/usr/bin/env bash" || "${aShebang}" == "#!/bin/bash" ]] \
    || fail "${aPath} missing bash shebang"
}

for LPath in "${TARGETS[@]}"; do
  require_file "${LPath}"
  assert_no_crlf "${LPath}"
  assert_bash_syntax_ok "${LPath}"
  assert_bash_shebang "${LPath}"
done

require_literal_in_file "tests/cleanup_orphan_dirs.sh" "set -euo pipefail"
require_literal_in_file "tests/cleanup_orphan_dirs.sh" "--run"
require_literal_in_file "tests/cleanup_orphan_dirs.sh" "--root"
require_literal_in_file "tests/fafafa.core.fs/ArchivePerfResult.sh" "set -euo pipefail"
require_literal_in_file "tests/fafafa.core.fs/BuildOrRunPerf.sh" "set -euo pipefail"
require_literal_in_file "tests/fafafa.core.fs/BuildOrRunPerfAll.sh" "set -euo pipefail"
require_literal_in_file "tests/fafafa.core.fs/BuildOrRunResolvePerf.sh" "set -euo pipefail"

LTmpDir="$(mktemp -d)"
trap 'rm -rf "${LTmpDir}"' EXIT
mkdir -p "${LTmpDir}/tmp_active_shell_runner_case/subdir"
printf 'shell-runner\n' > "${LTmpDir}/tmp_active_shell_runner_case/subdir/marker.txt"

OUTPUT="$(
  bash "${REPO_ROOT}/tests/cleanup_orphan_dirs.sh" --root "${LTmpDir}" 2>&1
)" || {
  printf '%s\n' "${OUTPUT}" >&2
  fail "cleanup_orphan_dirs.sh preview mode failed"
}
printf '%s\n' "${OUTPUT}" | rg -F --quiet "发现孤儿目录: 1 个" \
  || fail "cleanup preview output missing orphan count"
[[ -d "${LTmpDir}/tmp_active_shell_runner_case" ]] \
  || fail "cleanup preview unexpectedly deleted the orphan directory"

OUTPUT="$(
  bash "${REPO_ROOT}/tests/cleanup_orphan_dirs.sh" --root "${LTmpDir}" --run 2>&1
)" || {
  printf '%s\n' "${OUTPUT}" >&2
  fail "cleanup_orphan_dirs.sh run mode failed"
}
printf '%s\n' "${OUTPUT}" | rg -F --quiet "已清理: 1 个目录" \
  || fail "cleanup run output missing deletion count"
[[ ! -d "${LTmpDir}/tmp_active_shell_runner_case" ]] \
  || fail "cleanup run mode did not delete the orphan directory"

bash "${REPO_ROOT}/tests/test_fs_perf_shell_scripts.sh"

echo "[PASS] active shell runners contract verified"
