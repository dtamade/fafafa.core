#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
SIDECAR_REF="l0-sidecar-handoff-20260409"
TAIL_REF="l0-main-tail-cleanup-20260408-final"

print_usage() {
  cat <<'EOF'
Usage:
  bash tests/report_strict_l0_retained_refs_sidecar_tail_overlap.sh

This script compares the post-merge retained refs `sidecar` and `tail`
pairwise. It reports their shared merge-base, exclusive commits, exclusive
path buckets, and whether either ref is currently safe to delete.
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

is_docs_path() {
  [[ "$1" == docs/* ]]
}

is_worker_path() {
  [[ "$1" == workers/* ]]
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

is_test_runner_path() {
  case "$1" in
    tests/*/*.bat|tests/*/*.sh|tests/*/*/*.bat|tests/*/*/*.sh)
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

is_example_runner_path() {
  case "$1" in
    examples/*/*.bat|examples/*/*.sh|examples/*/*/*.bat|examples/*/*/*.sh)
      return 0
      ;;
  esac

  return 1
}

is_example_source_path() {
  case "$1" in
    examples/*/*.pas|examples/*/*.lpr|examples/*/*.lpi|examples/*/*/*.pas|examples/*/*/*.lpr|examples/*/*/*.lpi)
      return 0
      ;;
  esac

  return 1
}

print_exclusive_report() {
  local aBaseRef="$1"
  local aExclusiveRef="$2"
  local aPrefix="$3"

  local LCherryOutput
  local LSafeDelete="no"
  local LExclusiveCommitCount=0
  local LDocsPaths=0
  local LSrcPaths=0
  local LTestCodePaths=0
  local LTestRunnerPaths=0
  local LTestDocPaths=0
  local LExampleSourcePaths=0
  local LExampleRunnerPaths=0
  local LWorkerPaths=0
  local LOtherPaths=0
  local LLine
  local LCommitSha
  local LPath

  local LExclusiveCommitLines=()
  local LSampleExclusiveCommits=()
  local LSampleDocsPaths=()
  local LSampleSrcPaths=()
  local LSampleTestCodePaths=()
  local LSampleTestRunnerPaths=()
  local LSampleTestDocPaths=()
  local LSampleExampleSourcePaths=()
  local LSampleExampleRunnerPaths=()
  local LSampleWorkerPaths=()
  local LSampleOtherPaths=()

  mapfile -t LExclusiveCommitLines < <(git -C "${REPO_ROOT}" cherry -v "${aBaseRef}" "${aExclusiveRef}" || true)

  for LLine in "${LExclusiveCommitLines[@]}"; do
    [[ "${LLine}" == +* ]] || continue
    LCommitSha="$(awk '{print $2}' <<<"${LLine}")"
    [[ -n "${LCommitSha}" ]] || continue

    LExclusiveCommitCount=$((LExclusiveCommitCount + 1))
    append_sample LSampleExclusiveCommits "${LLine#+ }" 3

    while IFS= read -r LPath; do
      [[ -n "${LPath}" ]] || continue

      if is_docs_path "${LPath}"; then
        LDocsPaths=$((LDocsPaths + 1))
        append_sample LSampleDocsPaths "${LPath}" 3
        continue
      fi

      if is_worker_path "${LPath}"; then
        LWorkerPaths=$((LWorkerPaths + 1))
        append_sample LSampleWorkerPaths "${LPath}" 3
        continue
      fi

      if is_src_path "${LPath}"; then
        LSrcPaths=$((LSrcPaths + 1))
        append_sample LSampleSrcPaths "${LPath}" 3
        continue
      fi

      if is_test_doc_path "${LPath}"; then
        LTestDocPaths=$((LTestDocPaths + 1))
        append_sample LSampleTestDocPaths "${LPath}" 3
        continue
      fi

      if is_test_code_path "${LPath}"; then
        LTestCodePaths=$((LTestCodePaths + 1))
        append_sample LSampleTestCodePaths "${LPath}" 3
        continue
      fi

      if is_test_runner_path "${LPath}"; then
        LTestRunnerPaths=$((LTestRunnerPaths + 1))
        append_sample LSampleTestRunnerPaths "${LPath}" 3
        continue
      fi

      if is_example_source_path "${LPath}"; then
        LExampleSourcePaths=$((LExampleSourcePaths + 1))
        append_sample LSampleExampleSourcePaths "${LPath}" 3
        continue
      fi

      if is_example_runner_path "${LPath}"; then
        LExampleRunnerPaths=$((LExampleRunnerPaths + 1))
        append_sample LSampleExampleRunnerPaths "${LPath}" 3
        continue
      fi

      LOtherPaths=$((LOtherPaths + 1))
      append_sample LSampleOtherPaths "${LPath}" 3
    done < <(git -C "${REPO_ROOT}" show --name-only --format= "${LCommitSha}")
  done

  if (( ${LExclusiveCommitCount} == 0 )); then
    LSafeDelete="yes"
  fi

  echo "${aPrefix}_only_commit_count=${LExclusiveCommitCount}"
  echo "${aPrefix}_safe_delete_now=${LSafeDelete}"
  echo "${aPrefix}_only_docs_paths=${LDocsPaths}"
  echo "${aPrefix}_only_src_paths=${LSrcPaths}"
  echo "${aPrefix}_only_test_code_paths=${LTestCodePaths}"
  echo "${aPrefix}_only_test_runner_paths=${LTestRunnerPaths}"
  echo "${aPrefix}_only_test_doc_paths=${LTestDocPaths}"
  echo "${aPrefix}_only_example_source_paths=${LExampleSourcePaths}"
  echo "${aPrefix}_only_example_runner_paths=${LExampleRunnerPaths}"
  echo "${aPrefix}_only_worker_paths=${LWorkerPaths}"
  echo "${aPrefix}_only_other_paths=${LOtherPaths}"

  if (( ${#LSampleExclusiveCommits[@]} > 0 )); then
    echo "sample_${aPrefix}_only_commits=$(join_samples LSampleExclusiveCommits)"
  fi
  if (( ${#LSampleDocsPaths[@]} > 0 )); then
    echo "sample_${aPrefix}_only_docs_paths=$(join_samples LSampleDocsPaths)"
  fi
  if (( ${#LSampleSrcPaths[@]} > 0 )); then
    echo "sample_${aPrefix}_only_src_paths=$(join_samples LSampleSrcPaths)"
  fi
  if (( ${#LSampleTestCodePaths[@]} > 0 )); then
    echo "sample_${aPrefix}_only_test_code_paths=$(join_samples LSampleTestCodePaths)"
  fi
  if (( ${#LSampleTestRunnerPaths[@]} > 0 )); then
    echo "sample_${aPrefix}_only_test_runner_paths=$(join_samples LSampleTestRunnerPaths)"
  fi
  if (( ${#LSampleTestDocPaths[@]} > 0 )); then
    echo "sample_${aPrefix}_only_test_doc_paths=$(join_samples LSampleTestDocPaths)"
  fi
  if (( ${#LSampleExampleSourcePaths[@]} > 0 )); then
    echo "sample_${aPrefix}_only_example_source_paths=$(join_samples LSampleExampleSourcePaths)"
  fi
  if (( ${#LSampleExampleRunnerPaths[@]} > 0 )); then
    echo "sample_${aPrefix}_only_example_runner_paths=$(join_samples LSampleExampleRunnerPaths)"
  fi
  if (( ${#LSampleWorkerPaths[@]} > 0 )); then
    echo "sample_${aPrefix}_only_worker_paths=$(join_samples LSampleWorkerPaths)"
  fi
  if (( ${#LSampleOtherPaths[@]} > 0 )); then
    echo "sample_${aPrefix}_only_other_paths=$(join_samples LSampleOtherPaths)"
  fi
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
LSidecarSha="$(git -C "${REPO_ROOT}" rev-parse "${SIDECAR_REF}")"
LTailSha="$(git -C "${REPO_ROOT}" rev-parse "${TAIL_REF}")"
LMergeBase="$(git -C "${REPO_ROOT}" merge-base "${SIDECAR_REF}" "${TAIL_REF}")"

LSidecarOnlyOutput="$(print_exclusive_report "${TAIL_REF}" "${SIDECAR_REF}" "sidecar")"
LTailOnlyOutput="$(print_exclusive_report "${SIDECAR_REF}" "${TAIL_REF}" "tail")"

LSidecarOnlyCount="$(awk -F= '/^sidecar_only_commit_count=/{print $2}' <<<"${LSidecarOnlyOutput}")"
LTailOnlyCount="$(awk -F= '/^tail_only_commit_count=/{print $2}' <<<"${LTailOnlyOutput}")"

LPairwiseDecision="keep-both"
LPairwiseCleanupReadiness="review-exclusive-batches-first"
if [[ "${LSidecarOnlyCount}" == "0" && "${LTailOnlyCount}" == "0" ]]; then
  LPairwiseDecision="pairwise-duplicate"
  LPairwiseCleanupReadiness="candidate-consolidate"
elif [[ "${LSidecarOnlyCount}" == "0" ]]; then
  LPairwiseDecision="candidate-drop-sidecar-after-head-check"
elif [[ "${LTailOnlyCount}" == "0" ]]; then
  LPairwiseDecision="candidate-drop-tail-after-head-check"
fi

echo "[INFO] strict L0 retained refs sidecar-tail overlap"
echo "[INFO] current_head=${LHeadSha}"
echo "[INFO] sidecar_ref=${SIDECAR_REF}"
echo "[INFO] tail_ref=${TAIL_REF}"
echo "sidecar_ref_sha=${LSidecarSha}"
echo "tail_ref_sha=${LTailSha}"
echo "sidecar_tail_merge_base=${LMergeBase}"
printf '%s\n' "${LSidecarOnlyOutput}"
printf '%s\n' "${LTailOnlyOutput}"
echo "pairwise_decision=${LPairwiseDecision}"
echo "pairwise_cleanup_readiness=${LPairwiseCleanupReadiness}"
echo "[PASS] strict L0 retained refs sidecar-tail overlap completed"
