#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TARGET_SCRIPT="${REPO_ROOT}/tests/report_strict_l0_retained_refs_source_review_shortlist.sh"

fail() {
  echo "[FAIL] $1" >&2
  exit 1
}

[[ -f "${TARGET_SCRIPT}" ]] || fail "missing strict L0 retained refs source-review shortlist script"

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
        echo "ffffffffffffffffffffffffffffffffffffffff"
        exit 0
        ;;
      l0-mainline-closeout-20260411)
        echo "1111111111111111111111111111111111111111"
        exit 0
        ;;
      l0-main-rescue)
        echo "2222222222222222222222222222222222222222"
        exit 0
        ;;
    esac
    ;;
  diff)
    case "${LArgs[2]:-}" in
      HEAD..l0-mainline-closeout-20260411)
        cat <<'OUT'
M	tests/fafafa.core.fs.async/BuildOrTest.bat
M	tests/fafafa.core.fs.async/README.md
M	tests/fafafa.core.fs.async/buildOrTest.bat
M	tests/fafafa.core.fs.async/run_async_tests.lpr
M	tests/fafafa.core.fs.async/test_async_basic.pas
M	tests/fafafa.core.fs.async/test_simple.pas
M	tests/fafafa.core.socket.async/BuildOrTest.bat
M	tests/fafafa.core.socket.async/BuildOrTest.sh
M	src/fafafa.core.atomic.pas
M	tests/fafafa.core.atomic/Test_fafafa.core.atomic.pas
M	tests/fafafa.core.platform/BuildOrTest.sh
M	.github/workflows/l0-windows-native-evidence.yml
M	examples/fafafa.core.base/BuildOrRun.sh
M	examples/fafafa.core.result/example_result_filters_and_try.lpr
D	.github/workflows/l0-linux-maintenance.yml
D	tests/run_strict_l0_maintenance_loop.sh
D	docs/README.md
OUT
        exit 0
        ;;
      HEAD..l0-main-rescue)
        cat <<'OUT'
M	tests/fafafa.core.fs.async/BuildOrTest.bat
M	tests/fafafa.core.fs.async/buildOrTest.bat
M	tests/fafafa.core.socket.async/BuildOrTest.bat
D	.github/workflows/l0-windows-native-evidence.yml
M	src/fafafa.core.args.base.pas
M	tests/fafafa.core.atomic/Test_fafafa.core.atomic.core.contract.pas
M	tests/fafafa.core.platform/BuildOrTest.bat
M	tests/fafafa.core.atomic/README.md
M	examples/fafafa.core.atomic/BuildOrRun.sh
D	examples/fafafa.core.contracts/README.md
D	docs/legacy/l0/2026-04-11-l0-mainline-refs-and-ci-closeout.md
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
  fail "source-review shortlist failed under contract stubs"
}

for LPatt in \
  'current_head=ffffffffffffffffffffffffffffffffffffffff' \
  '== l0-mainline-closeout-20260411 ==' \
  'ref_sha=1111111111111111111111111111111111111111' \
  'review_candidate_paths=3' \
  'review_skip_paths=11' \
  'src_review_paths=0' \
  'test_code_review_paths=0' \
  'test_script_review_paths=1' \
  'test_doc_review_paths=0' \
  'ci_review_paths=0' \
  'examples_build_review_paths=2' \
  'simd_out_of_scope_paths=0' \
  'dangerous_delete_paths=3' \
  'reject_wholesale_absorb=yes' \
  'sample_review_candidate_paths=tests/fafafa.core.platform/BuildOrTest.sh | examples/fafafa.core.base/BuildOrRun.sh | examples/fafafa.core.result/example_result_filters_and_try.lpr' \
  'sample_review_skip_paths=tests/fafafa.core.fs.async/BuildOrTest.bat | tests/fafafa.core.fs.async/buildOrTest.bat | tests/fafafa.core.socket.async/BuildOrTest.bat' \
  'sample_dangerous_delete_paths=.github/workflows/l0-linux-maintenance.yml | tests/run_strict_l0_maintenance_loop.sh | docs/README.md' \
  '== l0-main-rescue ==' \
  'ref_sha=2222222222222222222222222222222222222222' \
  'review_candidate_paths=2' \
  'review_skip_paths=6' \
  'src_review_paths=1' \
  'test_code_review_paths=1' \
  'test_script_review_paths=0' \
  'test_doc_review_paths=0' \
  'ci_review_paths=0' \
  'examples_build_review_paths=0' \
  'simd_out_of_scope_paths=0' \
  'dangerous_delete_paths=3' \
  'reject_wholesale_absorb=yes' \
  'sample_review_candidate_paths=src/fafafa.core.args.base.pas | tests/fafafa.core.atomic/Test_fafafa.core.atomic.core.contract.pas' \
  'sample_review_skip_paths=tests/fafafa.core.fs.async/BuildOrTest.bat | tests/fafafa.core.fs.async/buildOrTest.bat | tests/fafafa.core.socket.async/BuildOrTest.bat' \
  'sample_dangerous_delete_paths=.github/workflows/l0-windows-native-evidence.yml | examples/fafafa.core.contracts/README.md | docs/legacy/l0/2026-04-11-l0-mainline-refs-and-ci-closeout.md' \
  '[PASS] strict L0 retained refs source-review shortlist completed'; do
  printf '%s' "${OUTPUT}" | rg -n -F "${LPatt}" >/dev/null \
    || {
      printf '%s\n' "${OUTPUT}" >&2
      fail "source-review shortlist output missing literal: ${LPatt}"
    }
done

echo "[PASS] strict L0 retained refs source-review shortlist contract verified"
