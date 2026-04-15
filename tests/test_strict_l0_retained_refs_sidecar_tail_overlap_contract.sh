#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TARGET_SCRIPT="${REPO_ROOT}/tests/report_strict_l0_retained_refs_sidecar_tail_overlap.sh"

fail() {
  echo "[FAIL] $1" >&2
  exit 1
}

[[ -f "${TARGET_SCRIPT}" ]] || fail "missing sidecar-tail overlap report script"

LTmpDir="$(mktemp -d)"
trap 'rm -rf "${LTmpDir}"' EXIT
mkdir -p "${LTmpDir}/bin"

cat >"${LTmpDir}/bin/git" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

LArgs=()
while [[ $# -gt 0 ]]; do
  if [[ "$1" == "-C" ]]; then
    shift 2
    continue
  fi
  LArgs+=("$1")
  shift
done

case "${LArgs[0]:-}" in
  rev-parse)
    case "${LArgs[1]:-}" in
      HEAD)
        echo "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
        exit 0
        ;;
      l0-sidecar-handoff-20260409)
        echo "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
        exit 0
        ;;
      l0-main-tail-cleanup-20260408-final)
        echo "cccccccccccccccccccccccccccccccccccccccc"
        exit 0
        ;;
    esac
    ;;
  merge-base)
    echo "dddddddddddddddddddddddddddddddddddddddd"
    exit 0
    ;;
  cherry)
    if [[ "${LArgs[2]:-}" == "l0-sidecar-handoff-20260409" ]]; then
      cat <<'OUT'
+ 2222222 tail span2 batch
+ 3333333 tail control plane batch
OUT
      exit 0
    fi
    if [[ "${LArgs[2]:-}" == "l0-main-tail-cleanup-20260408-final" ]]; then
      cat <<'OUT'
+ 1111111 sidecar runner cleanup batch
OUT
      exit 0
    fi
    ;;
  show)
    case "${LArgs[3]:-}" in
      1111111)
        cat <<'OUT'
examples/fafafa.core.sync/BuildOrRun.sh
tests/fafafa.core.sync/BuildOrTest.bat
docs/audits/l0_async_runner_audit_2026-04-08.md
OUT
        exit 0
        ;;
      2222222)
        cat <<'OUT'
src/fafafa.core.span.pas
tests/fafafa.core.span/fafafa.core.span.testcase.pas
workers/worker1.md
OUT
        exit 0
        ;;
      3333333)
        cat <<'OUT'
docs/fafafa.core.l0.roadmap.md
docs/audits/2026-04-09-l0-current-state-audit.md
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
  bash "${TARGET_SCRIPT}" 2>&1
)" || {
  printf '%s\n' "${OUTPUT}" >&2
  fail "sidecar-tail overlap report failed under contract stubs"
}

for LPatt in \
  'current_head=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa' \
  'sidecar_tail_merge_base=dddddddddddddddddddddddddddddddddddddddd' \
  'sidecar_only_commit_count=1' \
  'tail_only_commit_count=2' \
  'sidecar_safe_delete_now=no' \
  'tail_safe_delete_now=no' \
  'sidecar_only_docs_paths=1' \
  'sidecar_only_test_runner_paths=1' \
  'sidecar_only_example_runner_paths=1' \
  'tail_only_docs_paths=2' \
  'tail_only_src_paths=1' \
  'tail_only_test_code_paths=1' \
  'tail_only_worker_paths=1' \
  'sample_sidecar_only_commits=1111111 sidecar runner cleanup batch' \
  'sample_tail_only_commits=2222222 tail span2 batch | 3333333 tail control plane batch' \
  'pairwise_decision=keep-both' \
  'pairwise_cleanup_readiness=review-exclusive-batches-first'
do
  printf '%s\n' "${OUTPUT}" | rg -F --quiet -- "${LPatt}" \
    || fail "missing contract output: ${LPatt}"
done

echo "[PASS] strict L0 sidecar-tail overlap contract verified"
