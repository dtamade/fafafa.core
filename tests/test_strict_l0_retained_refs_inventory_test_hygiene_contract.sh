#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TARGET_SCRIPT="${REPO_ROOT}/tests/report_strict_l0_retained_refs_inventory.sh"

fail() {
  echo "[FAIL] $1" >&2
  exit 1
}

[[ -f "${TARGET_SCRIPT}" ]] || fail "missing strict L0 retained refs inventory script"

LTmpDir="$(mktemp -d)"
trap 'rm -rf "${LTmpDir}"' EXIT
mkdir -p "${LTmpDir}/bin"

cat >"${LTmpDir}/bin/git" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

LArgs=()
while [[ $# -gt 0 ]]; do
  if [[ "${1}" == "-C" ]]; then
    shift 2
    continue
  fi
  LArgs+=("${1}")
  shift
done

case "${LArgs[0]:-}" in
  rev-parse)
    case "${LArgs[1]:-}" in
      HEAD)
        echo "dddddddddddddddddddddddddddddddddddddddd"
        exit 0
        ;;
    esac
    ;;
  cherry)
    case "${LArgs[3]:-}" in
      l0-mainline-closeout-20260411)
        cat <<'OUT'
+ 1111111 closeout source review
OUT
        exit 0
        ;;
      l0-sidecar-handoff-20260409)
        cat <<'OUT'
+ 2222222 sidecar test hygiene split
OUT
        exit 0
        ;;
      l0-main-rescue)
        cat <<'OUT'
+ 3333333 rescue current docs review
OUT
        exit 0
        ;;
      l0-main-tail-cleanup-20260408-final)
        cat <<'OUT'
+ 4444444 tail archive first
OUT
        exit 0
        ;;
    esac
    ;;
  show)
    case "${LArgs[3]:-}" in
      1111111)
        cat <<'OUT'
src/fafafa.core.option.pas
tests/fafafa.core.option/fafafa.core.option.testcase.pas
OUT
        exit 0
        ;;
      2222222)
        cat <<'OUT'
tests/fafafa.core.fs.async/test_async_basic.pas
tests/fafafa.core.fs/BuildOrRunPerf.sh
tests/fafafa.core.fs/ArchivePerfResult.sh
tests/fafafa.core.fs/BuildOrRunResolvePerf.sh
tests/fafafa.core.fs/BuildOrRunPerfAll.sh
tests/cleanup_orphan_dirs.sh
tests/fafafa.core.atomic/README.md
tests/fafafa.core.archiver/last-run.txt
tests/fafafa.core.fs/performance-data/latest.txt
tests/fafafa.core.sync.barrier/.gitignore
tests/fafafa.core.sync.barrier/test_output.txt
tests/fafafa.core.atomic/tests_atomic
OUT
        exit 0
        ;;
      3333333)
        cat <<'OUT'
docs/fafafa.core.option.md
OUT
        exit 0
        ;;
      4444444)
        cat <<'OUT'
archive/reports/docs-root/COMPILATION_FIX_REPORT.md
OUT
        exit 0
        ;;
    esac
    ;;
esac

echo "[stub-git] unexpected invocation: ${LArgs[*]}" >&2
exit 98
EOF
chmod +x "${LTmpDir}/bin/git"

OUTPUT="$(
  PATH="${LTmpDir}/bin:${PATH}" \
  bash "${TARGET_SCRIPT}" --details 2>&1
)" || {
  printf '%s\n' "${OUTPUT}" >&2
  fail "retained refs inventory test-hygiene mode failed under contract stubs"
}

for LPatt in \
  'current_head=dddddddddddddddddddddddddddddddddddddddd' \
  '== l0-mainline-closeout-20260411 ==' \
  'test_code_paths=1' \
  'next_focus=source-review-first' \
  '== l0-sidecar-handoff-20260409 ==' \
  'test_source_paths=7' \
  'test_code_paths=1' \
  'test_script_paths=5' \
  'test_doc_paths=1' \
  'test_runtime_record_paths=2' \
  'test_control_paths=1' \
  'test_output_artifact_paths=1' \
  'test_binary_artifact_paths=1' \
  'next_focus=test-hygiene-first' \
  'sample_test_code_paths=tests/fafafa.core.fs.async/test_async_basic.pas' \
  'sample_test_script_paths=tests/fafafa.core.fs/BuildOrRunPerf.sh | tests/fafafa.core.fs/ArchivePerfResult.sh | tests/fafafa.core.fs/BuildOrRunResolvePerf.sh' \
  'sample_test_doc_paths=tests/fafafa.core.atomic/README.md' \
  'sample_test_runtime_record_paths=tests/fafafa.core.archiver/last-run.txt | tests/fafafa.core.fs/performance-data/latest.txt' \
  'sample_test_control_paths=tests/fafafa.core.sync.barrier/.gitignore' \
  'sample_test_output_artifact_paths=tests/fafafa.core.sync.barrier/test_output.txt' \
  'sample_test_binary_artifact_paths=tests/fafafa.core.atomic/tests_atomic' \
  '== l0-main-rescue ==' \
  'next_focus=current-docs-first' \
  '== l0-main-tail-cleanup-20260408-final ==' \
  'next_focus=archive-docs-first' \
  '[PASS] strict L0 retained refs inventory completed'; do
  printf '%s' "${OUTPUT}" | rg -n -F "${LPatt}" >/dev/null \
    || {
      printf '%s\n' "${OUTPUT}" >&2
      fail "retained refs inventory test-hygiene output missing literal: ${LPatt}"
    }
done

echo "[PASS] strict L0 retained refs inventory test-hygiene contract verified"
