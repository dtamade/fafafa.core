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
        echo "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
        exit 0
        ;;
    esac
    ;;
  cherry)
    case "${LArgs[3]:-}" in
      l0-mainline-closeout-20260411)
        cat <<'OUT'
+ 1111111 restore helper
+ 2222222 refresh example entrypoints
OUT
        exit 0
        ;;
      l0-sidecar-handoff-20260409)
        cat <<'OUT'
+ 3333333 archive collections reports
+ 4444444 archive root reports
OUT
        exit 0
        ;;
      l0-main-rescue)
        cat <<'OUT'
+ 5555555 restore helper
OUT
        exit 0
        ;;
      l0-main-tail-cleanup-20260408-final)
        cat <<'OUT'
+ 6666666 archive tail docs
OUT
        exit 0
        ;;
    esac
    ;;
  show)
    case "${LArgs[3]:-}" in
      1111111)
        cat <<'OUT'
examples/fafafa.core.base/BuildOrRun.sh
OUT
        exit 0
        ;;
      2222222)
        cat <<'OUT'
docs/ARCHITECTURE_LAYERS.md
OUT
        exit 0
        ;;
      3333333)
        cat <<'OUT'
archive/reports/docs-collections/COLLECTIONS_WORK_SUMMARY.md
docs/collections/reports/README.md
OUT
        exit 0
        ;;
      4444444)
        cat <<'OUT'
archive/reports/docs-root/COMPILATION_FIX_REPORT.md
docs/reports/README.md
OUT
        exit 0
        ;;
      5555555)
        cat <<'OUT'
src/fafafa.core.atomic.pas
tests/fafafa.core.atomic/README.md
OUT
        exit 0
        ;;
      6666666)
        cat <<'OUT'
archive/reports/docs-root/fafafa.core.mem.final-verification.md
docs/audits/2026-04-08-l0-tail-docs-audit.md
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
  fail "retained refs inventory script failed under contract stubs"
}

for LPatt in \
  'current_head=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa' \
  '== l0-mainline-closeout-20260411 ==' \
  'unique_commit_count=2' \
  'examples_or_build_paths=1' \
  'docs_current_entry_paths=1' \
  'recommendation=review-code-before-absorb' \
  '== l0-sidecar-handoff-20260409 ==' \
  'archive_docs_paths=4' \
  'recommendation=absorb-archive-first' \
  '== l0-main-rescue ==' \
  'code_or_tests_paths=2' \
  '== l0-main-tail-cleanup-20260408-final ==' \
  'archive_docs_paths=1' \
  '[PASS] strict L0 retained refs inventory completed'; do
  printf '%s' "${OUTPUT}" | rg -n -F "${LPatt}" >/dev/null \
    || {
      printf '%s\n' "${OUTPUT}" >&2
      fail "retained refs inventory output missing literal: ${LPatt}"
    }
done

echo "[PASS] strict L0 retained refs inventory contract verified"
