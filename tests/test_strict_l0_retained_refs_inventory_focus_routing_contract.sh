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
+ 1111111 closeout source review
OUT
        exit 0
        ;;
      l0-sidecar-handoff-20260409)
        cat <<'OUT'
+ 2222222 sidecar test hygiene routing
OUT
        exit 0
        ;;
      l0-main-rescue)
        cat <<'OUT'
+ 3333333 rescue source review routing
OUT
        exit 0
        ;;
      l0-main-tail-cleanup-20260408-final)
        cat <<'OUT'
+ 4444444 tail test hygiene routing
OUT
        exit 0
        ;;
    esac
    ;;
  show)
    case "${LArgs[3]:-}" in
      1111111)
        cat <<'OUT'
src/fafafa.core.atomic.pas
tests/fafafa.core.atomic/Test_fafafa.core.atomic.pas
.github/workflows/l0-windows-native-evidence.yml
examples/fafafa.core.atomic/BuildOrRun.sh
docs/legacy/l0/README.md
OUT
        exit 0
        ;;
      2222222)
        cat <<'OUT'
tests/fafafa.core.archiver/last-run.txt
tests/fafafa.core.sync.barrier/.gitignore
tests/fafafa.core.sync.barrier/test_output.txt
tests/fafafa.core.atomic/tests_atomic
docs/reports/README.md
OUT
        exit 0
        ;;
      3333333)
        cat <<'OUT'
src/fafafa.core.args.base.pas
tests/fafafa.core.platform/BuildOrTest.sh
examples/fafafa.core.base/example_base.lpr
docs/legacy/l0/README.md
OUT
        exit 0
        ;;
      4444444)
        cat <<'OUT'
tests/fafafa.core.fs/performance-data/latest.txt
tests/fafafa.core.sync.barrier/.gitignore
tests/_run_all_logs_sh/fafafa.core.base.log
tests/fafafa.core.atomic/tests_atomic
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

set +e
OUTPUT="$(
  PATH="${LTmpDir}/bin:${PATH}" \
  bash "${TARGET_SCRIPT}" --details 2>&1
)"
RC=$?
set -e

if [[ "${RC}" != "0" ]]; then
  printf '%s\n' "${OUTPUT}" >&2
  fail "retained refs inventory focus-routing mode failed under contract stubs"
fi

for LPatt in \
  'current_head=eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee' \
  '== l0-mainline-closeout-20260411 ==' \
  'source_review_candidate_paths=4' \
  'sample_source_review_candidate_paths=src/fafafa.core.atomic.pas | tests/fafafa.core.atomic/Test_fafafa.core.atomic.pas | .github/workflows/l0-windows-native-evidence.yml' \
  'next_focus=source-review-first' \
  '== l0-sidecar-handoff-20260409 ==' \
  'test_hygiene_candidate_paths=4' \
  'sample_test_hygiene_candidate_paths=tests/fafafa.core.archiver/last-run.txt | tests/fafafa.core.sync.barrier/.gitignore | tests/fafafa.core.sync.barrier/test_output.txt' \
  'next_focus=test-hygiene-first' \
  '== l0-main-rescue ==' \
  'source_review_candidate_paths=3' \
  'sample_source_review_candidate_paths=src/fafafa.core.args.base.pas | tests/fafafa.core.platform/BuildOrTest.sh | examples/fafafa.core.base/example_base.lpr' \
  'next_focus=source-review-first' \
  '== l0-main-tail-cleanup-20260408-final ==' \
  'test_hygiene_candidate_paths=4' \
  'sample_test_hygiene_candidate_paths=tests/fafafa.core.fs/performance-data/latest.txt | tests/fafafa.core.sync.barrier/.gitignore | tests/_run_all_logs_sh/fafafa.core.base.log' \
  'next_focus=test-hygiene-first' \
  '[PASS] strict L0 retained refs inventory completed'; do
  printf '%s' "${OUTPUT}" | rg -n -F "${LPatt}" >/dev/null \
    || {
      printf '%s\n' "${OUTPUT}" >&2
      fail "retained refs inventory focus-routing output missing literal: ${LPatt}"
    }
done

echo "[PASS] strict L0 retained refs inventory focus-routing contract verified"
