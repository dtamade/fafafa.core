#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
RETAINED_REFS=(
  "l0-mainline-closeout-20260411"
  "l0-main-rescue"
)

print_usage() {
  cat <<'EOF'
Usage:
  bash tests/report_strict_l0_retained_refs_source_review_shortlist.sh

This script reports a shortlist-first review surface for retained strict L0 refs
that are still marked source-review-first. It never deletes refs or applies
their diffs. It separates fresh review candidates, already-reviewed skip
hotspots, and dangerous deletions.
EOF
}

append_sample() {
  local -n aArrayRef="$1"
  local aValue="$2"
  local aLimit="$3"
  local LExisting

  for LExisting in "${aArrayRef[@]}"; do
    if [[ "${LExisting}" == "${aValue}" ]]; then
      return 0
    fi
  done

  if (( ${#aArrayRef[@]} < aLimit )); then
    aArrayRef+=("${aValue}")
  fi
}

join_samples() {
  local -n aArrayRef="$1"
  local LJoined=""
  local LValue

  for LValue in "${aArrayRef[@]}"; do
    if [[ -n "${LJoined}" ]]; then
      LJoined+=" | "
    fi
    LJoined+="${LValue}"
  done

  printf '%s' "${LJoined}"
}

is_src_path() {
  [[ "$1" == src/* ]]
}

is_test_doc_path() {
  case "$1" in
    tests/*.md|tests/*/*.md|tests/*/*/*.md)
      return 0
      ;;
  esac

  return 1
}

is_test_script_path() {
  case "$1" in
    tests/*/BuildOrTest.sh|tests/*/BuildOrTest.bat|tests/*/buildOrTest.bat|tests/*/buildOrTest.sh|tests/*/*.bat|tests/*/*.sh|tests/*/*/*.bat|tests/*/*/*.sh)
      return 0
      ;;
  esac

  return 1
}

is_test_code_path() {
  case "$1" in
    tests/*/*.pas|tests/*/*.lpr|tests/*/*.lpi|tests/*/*/*.pas|tests/*/*/*.lpr|tests/*/*/*.lpi)
      return 0
      ;;
  esac

  return 1
}

is_ci_review_path() {
  [[ "$1" == .github/workflows/* ]]
}

is_simd_out_of_scope_path() {
  case "$1" in
    .github/workflows/simd-*|docs/fafafa.core.simd*|docs/plans/*simd*|tests/fafafa.core.simd*|src/fafafa.core.simd*)
      return 0
      ;;
  esac

  return 1
}

is_examples_build_review_path() {
  case "$1" in
    examples/*/BuildOrRun.sh|examples/*/BuildOrRun.bat|examples/*/*.pas|examples/*/*.lpr|examples/*/*.lpi|examples/*/*/*.pas|examples/*/*/*.lpr|examples/*/*/*.lpi)
      return 0
      ;;
  esac

  return 1
}

is_dangerous_delete_path() {
  local aStatus="$1"
  local aPath="$2"

  if [[ "${aStatus}" != "D" ]]; then
    return 1
  fi

  case "${aPath}" in
    .github/workflows/l0-*|docs/README.md|docs/INDEX.md|docs/TESTING.md|docs/audits/*|docs/legacy/l0/*|workers/worker1.md|tests/run_strict_l0_*|tests/check_strict_l0_docs_consistency.sh|tests/report_strict_l0_retained_refs_*|tests/update_strict_l0_current_state_docs.sh|tests/test_strict_l0_*|examples/*)
      return 0
      ;;
  esac

  return 1
}

is_review_skip_path() {
  local aRef="$1"
  local aPath="$2"

  case "${aRef}:${aPath}" in
    l0-mainline-closeout-20260411:tests/fafafa.core.fs.async/BuildOrTest.bat|\
    l0-mainline-closeout-20260411:tests/fafafa.core.fs.async/README.md|\
    l0-mainline-closeout-20260411:tests/fafafa.core.fs.async/buildOrTest.bat|\
    l0-mainline-closeout-20260411:tests/fafafa.core.fs.async/run_async_tests.lpr|\
    l0-mainline-closeout-20260411:tests/fafafa.core.fs.async/test_async_basic.pas|\
    l0-mainline-closeout-20260411:tests/fafafa.core.fs.async/test_simple.pas|\
    l0-mainline-closeout-20260411:tests/fafafa.core.socket.async/BuildOrTest.bat|\
    l0-mainline-closeout-20260411:tests/fafafa.core.socket.async/BuildOrTest.sh|\
    l0-mainline-closeout-20260411:tests/fafafa.core.socket.async/buildOrTest.bat|\
    l0-mainline-closeout-20260411:.github/workflows/l0-windows-native-evidence.yml|\
    l0-mainline-closeout-20260411:src/fafafa.core.mem.allocator.pas|\
    l0-mainline-closeout-20260411:src/fafafa.core.atomic.base.pas|\
    l0-mainline-closeout-20260411:src/fafafa.core.atomic.pas|\
    l0-mainline-closeout-20260411:src/fafafa.core.mem.allocator.callbackAllocator.pas|\
    l0-mainline-closeout-20260411:tests/lib_github_actions_workflow_runs.sh|\
    l0-mainline-closeout-20260411:tests/fafafa.core.fs/ArchivePerfResult.sh|\
    l0-mainline-closeout-20260411:tests/fafafa.core.fs/BuildOrRunPerf.sh|\
    l0-mainline-closeout-20260411:tests/fafafa.core.fs/BuildOrRunPerfAll.sh|\
    l0-mainline-closeout-20260411:tests/fafafa.core.fs/BuildOrRunResolvePerf.sh|\
    l0-mainline-closeout-20260411:tests/fafafa.core.fs/README-perf.md|\
    l0-mainline-closeout-20260411:tests/fafafa.core.atomic/README.md|\
    l0-mainline-closeout-20260411:tests/fafafa.core.atomic/Test_fafafa.core.atomic.compat.contract.pas|\
    l0-mainline-closeout-20260411:tests/fafafa.core.atomic/Test_fafafa.core.atomic.pas|\
    l0-mainline-closeout-20260411:tests/fafafa.core.endian/README.md|\
    l0-mainline-closeout-20260411:tests/fafafa.core.layout/README.md|\
    l0-mainline-closeout-20260411:tests/fafafa.core.mem.allocator.foundation/README.md|\
    l0-mainline-closeout-20260411:tests/fafafa.core.mem.allocator.foundation/test_allocator_foundation_runtime.pas|\
    l0-mainline-closeout-20260411:tests/fafafa.core.platform/README.md|\
    l0-mainline-closeout-20260411:tests/fafafa.core.span/README.md|\
    l0-mainline-closeout-20260411:examples/fafafa.core.env/BuildOrRun.sh|\
    l0-mainline-closeout-20260411:examples/fafafa.core.json/BuildOrRun.sh|\
    l0-mainline-closeout-20260411:examples/fafafa.core.platform/BuildOrRun.sh|\
    l0-mainline-closeout-20260411:examples/fafafa.core.sync.mutex/BuildOrRun.sh|\
    l0-main-rescue:tests/fafafa.core.fs.async/BuildOrTest.bat|\
    l0-main-rescue:tests/fafafa.core.fs.async/README.md|\
    l0-main-rescue:tests/fafafa.core.fs.async/buildOrTest.bat|\
    l0-main-rescue:tests/fafafa.core.fs.async/run_async_tests.lpr|\
    l0-main-rescue:tests/fafafa.core.fs.async/test_async_basic.pas|\
    l0-main-rescue:tests/fafafa.core.fs.async/test_simple.pas|\
    l0-main-rescue:tests/fafafa.core.socket.async/BuildOrTest.bat|\
    l0-main-rescue:tests/fafafa.core.socket.async/BuildOrTest.sh|\
    l0-main-rescue:tests/fafafa.core.socket.async/buildOrTest.bat|\
    l0-main-rescue:.github/workflows/l0-windows-native-evidence.yml|\
    l0-main-rescue:src/fafafa.core.atomic.base.pas|\
    l0-main-rescue:src/fafafa.core.atomic.pas|\
    l0-main-rescue:src/fafafa.core.mem.allocator.pas|\
    l0-main-rescue:src/fafafa.core.mem.allocator.callbackAllocator.pas|\
    l0-main-rescue:src/fafafa.core.result.pas|\
    l0-main-rescue:src/fafafa.core.span.pas|\
    l0-main-rescue:examples/fafafa.core.atomic/BuildOrRun.sh|\
    l0-main-rescue:examples/fafafa.core.base/BuildOrRun.sh|\
    l0-main-rescue:examples/fafafa.core.base/example_base.lpr|\
    l0-main-rescue:examples/fafafa.core.env/BuildOrRun.sh|\
    l0-main-rescue:examples/fafafa.core.json/BuildOrRun.sh|\
    l0-main-rescue:examples/fafafa.core.option/BuildOrRun.sh|\
    l0-main-rescue:examples/fafafa.core.platform/BuildOrRun.sh|\
    l0-main-rescue:examples/fafafa.core.result/BuildOrRun.sh|\
    l0-main-rescue:examples/fafafa.core.result/example_result_filters_and_try.lpr|\
    l0-main-rescue:examples/fafafa.core.sync.mutex/BuildOrRun.sh|\
    l0-main-rescue:tests/lib_github_actions_workflow_runs.sh|\
    l0-main-rescue:tests/fafafa.core.atomic/BuildOrTest.bat|\
    l0-main-rescue:tests/fafafa.core.atomic/README.md|\
    l0-main-rescue:tests/fafafa.core.atomic/Test_fafafa.core.atomic.base.pas|\
    l0-main-rescue:tests/fafafa.core.atomic/Test_fafafa.core.atomic.compat.contract.pas|\
    l0-main-rescue:tests/fafafa.core.atomic/Test_fafafa.core.atomic.pas|\
    l0-main-rescue:tests/fafafa.core.base/BuildOrTest.bat|\
    l0-main-rescue:tests/fafafa.core.base/README.md|\
    l0-main-rescue:tests/fafafa.core.base/fafafa.core.base.test.lpr|\
    l0-main-rescue:tests/fafafa.core.base/fafafa.core.base.testcase.pas|\
    l0-main-rescue:tests/fafafa.core.bits/BuildOrTest.bat|\
    l0-main-rescue:tests/fafafa.core.bits/README.md|\
    l0-main-rescue:tests/fafafa.core.bits/fafafa.core.bits.test.lpr|\
    l0-main-rescue:tests/fafafa.core.bits/fafafa.core.bits.testcase.pas|\
    l0-main-rescue:tests/fafafa.core.contracts/BuildOrTest.bat|\
    l0-main-rescue:tests/fafafa.core.contracts/README.md|\
    l0-main-rescue:tests/fafafa.core.contracts/fafafa.core.contracts.test.lpr|\
    l0-main-rescue:tests/fafafa.core.contracts/fafafa.core.contracts.testcase.pas|\
    l0-main-rescue:tests/fafafa.core.endian/BuildOrTest.bat|\
    l0-main-rescue:tests/fafafa.core.endian/README.md|\
    l0-main-rescue:tests/fafafa.core.endian/fafafa.core.endian.test.lpr|\
    l0-main-rescue:tests/fafafa.core.endian/fafafa.core.endian.testcase.pas|\
    l0-main-rescue:tests/fafafa.core.fs/ArchivePerfResult.sh|\
    l0-main-rescue:tests/fafafa.core.fs/BuildOrRunPerf.sh|\
    l0-main-rescue:tests/fafafa.core.fs/BuildOrRunPerfAll.sh|\
    l0-main-rescue:tests/fafafa.core.fs/BuildOrRunResolvePerf.sh|\
    l0-main-rescue:tests/fafafa.core.fs/README-perf.md|\
    l0-main-rescue:tests/fafafa.core.layout/BuildOrTest.bat|\
    l0-main-rescue:tests/fafafa.core.layout/README.md|\
    l0-main-rescue:tests/fafafa.core.layout/fafafa.core.layout.test.lpr|\
    l0-main-rescue:tests/fafafa.core.layout/fafafa.core.layout.testcase.pas|\
    l0-main-rescue:tests/fafafa.core.mem.allocator.foundation/BuildOrTest.sh|\
    l0-main-rescue:tests/fafafa.core.mem.allocator.foundation/README.md|\
    l0-main-rescue:tests/fafafa.core.mem.allocator.foundation/buildOrTest.bat|\
    l0-main-rescue:tests/fafafa.core.mem.allocator.foundation/fafafa.core.mem.allocator.foundation.test.lpi|\
    l0-main-rescue:tests/fafafa.core.mem.allocator.foundation/fafafa.core.mem.allocator.foundation.test.lpr|\
    l0-main-rescue:tests/fafafa.core.mem.allocator.foundation/test_allocator_foundation_runtime.pas|\
    l0-main-rescue:tests/fafafa.core.mem/BuildOrTest.bat|\
    l0-main-rescue:tests/fafafa.core.mem/BuildOrTest.sh|\
    l0-main-rescue:tests/fafafa.core.mem/README.md|\
    l0-main-rescue:tests/fafafa.core.mem/test_mem_allocator.pas|\
    l0-main-rescue:tests/fafafa.core.mem/tests_mem_allocator_only.lpi|\
    l0-main-rescue:tests/fafafa.core.mem/tests_mem_allocator_only.lpr|\
    l0-main-rescue:tests/fafafa.core.option/BuildOrTest.bat|\
    l0-main-rescue:tests/fafafa.core.option/README.md|\
    l0-main-rescue:tests/fafafa.core.option/buildOrTest.bat|\
    l0-main-rescue:tests/fafafa.core.option/fafafa.core.option.test.lpr|\
    l0-main-rescue:tests/fafafa.core.option/fafafa.core.option.testcase.pas|\
    l0-main-rescue:tests/fafafa.core.platform/BuildOrTest.bat|\
    l0-main-rescue:tests/fafafa.core.platform/README.md|\
    l0-main-rescue:tests/fafafa.core.platform/fafafa.core.platform.test.lpr|\
    l0-main-rescue:tests/fafafa.core.collections/vecdeque/Test_vecdeque_span.pas|\
    l0-main-rescue:tests/fafafa.core.result/BuildOrTest.bat|\
    l0-main-rescue:tests/fafafa.core.result/README.md|\
    l0-main-rescue:tests/fafafa.core.result/buildOrTest.bat|\
    l0-main-rescue:tests/fafafa.core.result/fafafa.core.result.test.lpr|\
    l0-main-rescue:tests/fafafa.core.result/fafafa.core.result.testcase.pas|\
    l0-main-rescue:tests/fafafa.core.result/test_basic_result.pas|\
    l0-main-rescue:tests/fafafa.core.result/test_option_basic.pas|\
    l0-main-rescue:tests/fafafa.core.result/test_option_init_debug.pas|\
    l0-main-rescue:tests/fafafa.core.result/tests_result.lpr|\
    l0-main-rescue:tests/fafafa.core.span/BuildOrTest.bat|\
    l0-main-rescue:tests/fafafa.core.span/README.md|\
    l0-main-rescue:tests/fafafa.core.span/fafafa.core.span.test.lpr|\
    l0-main-rescue:tests/fafafa.core.span/fafafa.core.span.testcase.pas|\
    l0-main-rescue:src/fafafa.core.time.tick.hardware.aarch64.pas|\
    l0-main-rescue:src/fafafa.core.time.tick.hardware.armv7a.pas|\
    l0-main-rescue:src/fafafa.core.time.tick.hardware.i386.pas|\
    l0-main-rescue:src/fafafa.core.time.tick.hardware.riscv32.pas|\
    l0-main-rescue:src/fafafa.core.time.tick.hardware.riscv64.pas)
      return 0
      ;;
  esac

  return 1
}

case "${1:-}" in
  --help|-h)
    print_usage
    exit 0
    ;;
  "")
    ;;
  *)
    echo "[FAIL] unknown argument: ${1}" >&2
    print_usage >&2
    exit 2
    ;;
esac

LHeadSha="$(git -C "${REPO_ROOT}" rev-parse HEAD)"
echo "[INFO] strict L0 retained refs source-review shortlist"
echo "[INFO] current_head=${LHeadSha}"

for LRef in "${RETAINED_REFS[@]}"; do
  LRefSha="$(git -C "${REPO_ROOT}" rev-parse "${LRef}")"
  LReviewCandidatePaths=0
  LReviewSkipPaths=0
  LSrcReviewPaths=0
  LTestCodeReviewPaths=0
  LTestScriptReviewPaths=0
  LTestDocReviewPaths=0
  LCiReviewPaths=0
  LExamplesBuildReviewPaths=0
  LSimdOutOfScopePaths=0
  LDangerousDeletePaths=0
  LRejectWholesaleAbsorb="no"

  LSampleReviewCandidatePaths=()
  LSampleReviewSkipPaths=()
  LSampleSrcReviewPaths=()
  LSampleTestCodeReviewPaths=()
  LSampleTestScriptReviewPaths=()
  LSampleTestDocReviewPaths=()
  LSampleCiReviewPaths=()
  LSampleExamplesBuildReviewPaths=()
  LSampleSimdOutOfScopePaths=()
  LSampleDangerousDeletePaths=()

  while IFS=$'\t' read -r LStatus LPath; do
    [[ -n "${LStatus}" ]] || continue
    [[ -n "${LPath}" ]] || continue

    if is_dangerous_delete_path "${LStatus}" "${LPath}"; then
      LDangerousDeletePaths=$((LDangerousDeletePaths + 1))
      LRejectWholesaleAbsorb="yes"
      append_sample LSampleDangerousDeletePaths "${LPath}" 3
      continue
    fi

    if is_simd_out_of_scope_path "${LPath}"; then
      LSimdOutOfScopePaths=$((LSimdOutOfScopePaths + 1))
      append_sample LSampleSimdOutOfScopePaths "${LPath}" 3
      continue
    fi

    if is_review_skip_path "${LRef}" "${LPath}"; then
      LReviewSkipPaths=$((LReviewSkipPaths + 1))
      append_sample LSampleReviewSkipPaths "${LPath}" 3
      continue
    fi

    if is_src_path "${LPath}"; then
      LReviewCandidatePaths=$((LReviewCandidatePaths + 1))
      LSrcReviewPaths=$((LSrcReviewPaths + 1))
      append_sample LSampleReviewCandidatePaths "${LPath}" 3
      append_sample LSampleSrcReviewPaths "${LPath}" 3
      continue
    fi

    if is_test_doc_path "${LPath}"; then
      LReviewCandidatePaths=$((LReviewCandidatePaths + 1))
      LTestDocReviewPaths=$((LTestDocReviewPaths + 1))
      append_sample LSampleReviewCandidatePaths "${LPath}" 3
      append_sample LSampleTestDocReviewPaths "${LPath}" 3
      continue
    fi

    if is_test_script_path "${LPath}"; then
      LReviewCandidatePaths=$((LReviewCandidatePaths + 1))
      LTestScriptReviewPaths=$((LTestScriptReviewPaths + 1))
      append_sample LSampleReviewCandidatePaths "${LPath}" 3
      append_sample LSampleTestScriptReviewPaths "${LPath}" 3
      continue
    fi

    if is_test_code_path "${LPath}"; then
      LReviewCandidatePaths=$((LReviewCandidatePaths + 1))
      LTestCodeReviewPaths=$((LTestCodeReviewPaths + 1))
      append_sample LSampleReviewCandidatePaths "${LPath}" 3
      append_sample LSampleTestCodeReviewPaths "${LPath}" 3
      continue
    fi

    if is_ci_review_path "${LPath}"; then
      LReviewCandidatePaths=$((LReviewCandidatePaths + 1))
      LCiReviewPaths=$((LCiReviewPaths + 1))
      append_sample LSampleReviewCandidatePaths "${LPath}" 3
      append_sample LSampleCiReviewPaths "${LPath}" 3
      continue
    fi

    if is_examples_build_review_path "${LPath}"; then
      LReviewCandidatePaths=$((LReviewCandidatePaths + 1))
      LExamplesBuildReviewPaths=$((LExamplesBuildReviewPaths + 1))
      append_sample LSampleReviewCandidatePaths "${LPath}" 3
      append_sample LSampleExamplesBuildReviewPaths "${LPath}" 3
      continue
    fi
  done < <(git -C "${REPO_ROOT}" diff --name-status "HEAD..${LRef}" || true)

  echo "== ${LRef} =="
  echo "ref_sha=${LRefSha}"
  echo "review_candidate_paths=${LReviewCandidatePaths}"
  echo "review_skip_paths=${LReviewSkipPaths}"
  echo "src_review_paths=${LSrcReviewPaths}"
  echo "test_code_review_paths=${LTestCodeReviewPaths}"
  echo "test_script_review_paths=${LTestScriptReviewPaths}"
  echo "test_doc_review_paths=${LTestDocReviewPaths}"
  echo "ci_review_paths=${LCiReviewPaths}"
  echo "examples_build_review_paths=${LExamplesBuildReviewPaths}"
  echo "simd_out_of_scope_paths=${LSimdOutOfScopePaths}"
  echo "dangerous_delete_paths=${LDangerousDeletePaths}"
  echo "reject_wholesale_absorb=${LRejectWholesaleAbsorb}"

  if (( ${#LSampleReviewCandidatePaths[@]} > 0 )); then
    echo "sample_review_candidate_paths=$(join_samples LSampleReviewCandidatePaths)"
  fi
  if (( ${#LSampleReviewSkipPaths[@]} > 0 )); then
    echo "sample_review_skip_paths=$(join_samples LSampleReviewSkipPaths)"
  fi
  if (( ${#LSampleSrcReviewPaths[@]} > 0 )); then
    echo "sample_src_review_paths=$(join_samples LSampleSrcReviewPaths)"
  fi
  if (( ${#LSampleTestCodeReviewPaths[@]} > 0 )); then
    echo "sample_test_code_review_paths=$(join_samples LSampleTestCodeReviewPaths)"
  fi
  if (( ${#LSampleTestScriptReviewPaths[@]} > 0 )); then
    echo "sample_test_script_review_paths=$(join_samples LSampleTestScriptReviewPaths)"
  fi
  if (( ${#LSampleTestDocReviewPaths[@]} > 0 )); then
    echo "sample_test_doc_review_paths=$(join_samples LSampleTestDocReviewPaths)"
  fi
  if (( ${#LSampleCiReviewPaths[@]} > 0 )); then
    echo "sample_ci_review_paths=$(join_samples LSampleCiReviewPaths)"
  fi
  if (( ${#LSampleExamplesBuildReviewPaths[@]} > 0 )); then
    echo "sample_examples_build_review_paths=$(join_samples LSampleExamplesBuildReviewPaths)"
  fi
  if (( ${#LSampleSimdOutOfScopePaths[@]} > 0 )); then
    echo "sample_simd_out_of_scope_paths=$(join_samples LSampleSimdOutOfScopePaths)"
  fi
  if (( ${#LSampleDangerousDeletePaths[@]} > 0 )); then
    echo "sample_dangerous_delete_paths=$(join_samples LSampleDangerousDeletePaths)"
  fi
done

echo "[PASS] strict L0 retained refs source-review shortlist completed"
