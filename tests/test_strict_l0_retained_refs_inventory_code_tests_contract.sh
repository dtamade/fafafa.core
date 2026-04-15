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
        echo "cccccccccccccccccccccccccccccccccccccccc"
        exit 0
        ;;
    esac
    ;;
  cherry)
    case "${LArgs[3]:-}" in
      l0-mainline-closeout-20260411)
        cat <<'OUT'
+ 1111111 src drift batch
OUT
        exit 0
        ;;
      l0-sidecar-handoff-20260409)
        cat <<'OUT'
+ 2222222 test source batch
OUT
        exit 0
        ;;
      l0-main-rescue)
        cat <<'OUT'
+ 3333333 workflow batch
OUT
        exit 0
        ;;
      l0-main-tail-cleanup-20260408-final)
        cat <<'OUT'
+ 4444444 test artifact batch
OUT
        exit 0
        ;;
    esac
    ;;
  show)
    case "${LArgs[3]:-}" in
      1111111)
        cat <<'OUT'
src/fafafa.core.result.pas
OUT
        exit 0
        ;;
      2222222)
        cat <<'OUT'
tests/fafafa.core.result/README.md
tests/fafafa.core.result/fafafa.core.result.testcase.pas
OUT
        exit 0
        ;;
      3333333)
        cat <<'OUT'
.github/workflows/l0-linux-maintenance.yml
OUT
        exit 0
        ;;
      4444444)
        cat <<'OUT'
tests/_run_all_logs_sh/fafafa.core.result.log
tests/fafafa.core.sync.barrier/barrier_heaptrc_output.txt
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
  fail "retained refs inventory code/tests mode failed under contract stubs"
}

for LPatt in \
  'current_head=cccccccccccccccccccccccccccccccccccccccc' \
  '== l0-mainline-closeout-20260411 ==' \
  'src_paths=1' \
  'test_code_paths=1' \
  'next_focus=source-review-first' \
  '== l0-sidecar-handoff-20260409 ==' \
  'test_source_paths=2' \
  'test_code_paths=1' \
  'test_doc_paths=1' \
  'next_focus=source-review-first' \
  '== l0-main-rescue ==' \
  'ci_workflow_paths=1' \
  'next_focus=source-review-first' \
  '== l0-main-tail-cleanup-20260408-final ==' \
  'test_artifact_paths=2' \
  'test_output_artifact_paths=2' \
  'next_focus=test-hygiene-first' \
  'sample_src_paths=src/fafafa.core.result.pas' \
  'sample_test_source_paths=tests/fafafa.core.result/README.md | tests/fafafa.core.result/fafafa.core.result.testcase.pas' \
  'sample_test_code_paths=tests/fafafa.core.result/fafafa.core.result.testcase.pas' \
  'sample_test_doc_paths=tests/fafafa.core.result/README.md' \
  'sample_ci_workflow_paths=.github/workflows/l0-linux-maintenance.yml' \
  'sample_test_artifact_paths=tests/_run_all_logs_sh/fafafa.core.result.log | tests/fafafa.core.sync.barrier/barrier_heaptrc_output.txt' \
  'sample_test_output_artifact_paths=tests/_run_all_logs_sh/fafafa.core.result.log | tests/fafafa.core.sync.barrier/barrier_heaptrc_output.txt' \
  '[PASS] strict L0 retained refs inventory completed'; do
  printf '%s' "${OUTPUT}" | rg -n -F "${LPatt}" >/dev/null \
    || {
      printf '%s\n' "${OUTPUT}" >&2
      fail "retained refs inventory code/tests output missing literal: ${LPatt}"
    }
done

echo "[PASS] strict L0 retained refs inventory code/tests contract verified"
