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
        echo "eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee"
        exit 0
        ;;
    esac
    ;;
  cherry)
    case "${LArgs[3]:-}" in
      l0-mainline-closeout-20260411)
        cat <<'OUT'
+ 1111111 closeout live docs
OUT
        exit 0
        ;;
      l0-sidecar-handoff-20260409)
        cat <<'OUT'
+ 2222222 sidecar docs absorb candidates
OUT
        exit 0
        ;;
      l0-main-rescue)
        cat <<'OUT'
+ 3333333 rescue mixed docs
OUT
        exit 0
        ;;
      l0-main-tail-cleanup-20260408-final)
        cat <<'OUT'
+ 4444444 tail docs absorb candidates
OUT
        exit 0
        ;;
    esac
    ;;
  show)
    case "${LArgs[3]:-}" in
      1111111)
        cat <<'OUT'
docs/README.md
docs/fafafa.core.option.md
docs/topics/sync/api/SYNC_API_REFERENCE.md
OUT
        exit 0
        ;;
      2222222)
        cat <<'OUT'
docs/collections/plans/COLLECTIONS_REFINEMENT_PLAN.md
docs/reports/README.md
docs/legacy/l0/README.md
docs/collections/guides/README_VecDeque.md
docs/reports/time/TIME_PRODUCTION_READINESS_REPORT.md
OUT
        exit 0
        ;;
      3333333)
        cat <<'OUT'
docs/INDEX.md
docs/fafafa.core.mem.md
docs/benchmarks/reports/README.md
OUT
        exit 0
        ;;
      4444444)
        cat <<'OUT'
docs/collections/status/COLLECTIONS_CURRENT_STATUS_2025-11-03.md
docs/collections/reports/README.md
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
  fail "retained refs inventory docs-current-entry mode failed under contract stubs"
}

for LPatt in \
  'current_head=eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee' \
  '== l0-mainline-closeout-20260411 ==' \
  'docs_root_entry_paths=1' \
  'docs_module_paths=1' \
  'docs_topic_paths=1' \
  '== l0-sidecar-handoff-20260409 ==' \
  'docs_guide_paths=1' \
  'docs_archive_pointer_paths=1' \
  'docs_collections_dated_paths=1' \
  'docs_legacy_paths=1' \
  'docs_report_topic_paths=1' \
  'docs_absorb_candidate_paths=3' \
  'sample_docs_absorb_candidate_paths=docs/collections/plans/COLLECTIONS_REFINEMENT_PLAN.md | docs/reports/README.md | docs/legacy/l0/README.md' \
  '== l0-main-rescue ==' \
  'docs_archive_pointer_paths=1' \
  'docs_module_paths=1' \
  '== l0-main-tail-cleanup-20260408-final ==' \
  'docs_archive_pointer_paths=1' \
  'docs_collections_dated_paths=1' \
  'docs_absorb_candidate_paths=2' \
  '[PASS] strict L0 retained refs inventory completed'; do
  printf '%s' "${OUTPUT}" | rg -n -F "${LPatt}" >/dev/null \
    || {
      printf '%s\n' "${OUTPUT}" >&2
      fail "retained refs inventory docs-current-entry output missing literal: ${LPatt}"
    }
done

echo "[PASS] strict L0 retained refs inventory docs-current-entry contract verified"
