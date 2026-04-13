#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
RETAINED_REFS=(
  "l0-mainline-closeout-20260411"
  "l0-sidecar-handoff-20260409"
  "l0-main-rescue"
  "l0-main-tail-cleanup-20260408-final"
)

print_usage() {
  cat <<'EOF'
Usage:
  bash tests/report_strict_l0_retained_refs_inventory.sh
  bash tests/report_strict_l0_retained_refs_inventory.sh --details

This script inventories the unique history still carried by the retained
strict L0 refs and buckets the touched paths for absorption planning.
In --details mode it also splits example/build drift into example sources,
build scripts, generated outputs, and splits code/tests drift into src paths,
real test sources, runtime records, control files, CI workflows, and test
artifacts. It also prints docs absorbability buckets and next_focus= to make
the next absorb wave explicit.
EOF
}

append_sample() {
  local -n aArrayRef="$1"
  local aValue="$2"
  local aMax="$3"

  if (( ${#aArrayRef[@]} < aMax )); then
    aArrayRef+=("${aValue}")
  fi
}

join_samples() {
  local -n aArrayRef="$1"
  local LJoined=""
  local LItem

  for LItem in "${aArrayRef[@]}"; do
    if [[ -n "${LJoined}" ]]; then
      LJoined="${LJoined} | "
    fi
    LJoined="${LJoined}${LItem}"
  done

  printf '%s' "${LJoined}"
}

is_archive_docs_path() {
  local aPath="$1"
  local LBaseName
  LBaseName="$(basename "${aPath}")"

  case "${aPath}" in
    archive/*|docs/benchmarks/reports/*|docs/collections/reports/*|docs/reports/*)
      return 0
      ;;
  esac

  case "${LBaseName}" in
    *_REPORT.md|*completion-report.md|*performance-report.md|*test-report.md|*test-summary.md|\
    *final-status.md|*final-verification.md|*development-status.md|*ultimate-completion.md|\
    *cleanup-success.md|*integration-summary.md|*IMPLEMENTATION_SUMMARY.md|test_report_*|\
    COMPILATION_FIX_REPORT.md|STATUS_*.md)
      return 0
      ;;
  esac

  return 1
}

is_build_script_path() {
  local aPath="$1"
  local LBaseName
  LBaseName="$(basename "${aPath}")"

  case "${LBaseName}" in
    BuildOrRun*.sh|BuildOrRun*.bat|BuildAndRun*.sh|BuildAndRun*.bat|BuildOrTest*.sh|BuildOrTest*.bat|\
    build*.sh|build*.bat)
      return 0
      ;;
  esac

  return 1
}

is_generated_output_path() {
  local aPath="$1"

  case "${aPath}" in
    examples/*/bin/*|examples/*/lib/*)
      return 0
      ;;
  esac

  return 1
}

is_docs_root_entry_path() {
  local aPath="$1"

  case "${aPath}" in
    docs/README.md|docs/INDEX.md|docs/EXAMPLES.md)
      return 0
      ;;
  esac

  return 1
}

is_docs_module_path() {
  local aPath="$1"

  case "${aPath}" in
    docs/fafafa.core*.md)
      return 0
      ;;
  esac

  return 1
}

is_docs_topic_path() {
  local aPath="$1"

  case "${aPath}" in
    docs/topics/*)
      return 0
      ;;
  esac

  return 1
}

is_docs_guide_path() {
  local aPath="$1"

  case "${aPath}" in
    docs/collections/guides/*)
      return 0
      ;;
  esac

  return 1
}

is_docs_archive_pointer_path() {
  local aPath="$1"

  case "${aPath}" in
    docs/reports/README.md|docs/collections/reports/README.md|docs/benchmarks/reports/README.md)
      return 0
      ;;
  esac

  return 1
}

is_docs_collections_dated_path() {
  local aPath="$1"

  case "${aPath}" in
    docs/collections/plans/*|docs/collections/status/*|docs/collections/reviews/*)
      return 0
      ;;
  esac

  return 1
}

is_docs_legacy_path() {
  local aPath="$1"

  case "${aPath}" in
    docs/legacy/*)
      return 0
      ;;
  esac

  return 1
}

is_docs_report_topic_path() {
  local aPath="$1"

  case "${aPath}" in
    docs/reports/*)
      if is_docs_archive_pointer_path "${aPath}"; then
        return 1
      fi
      return 0
      ;;
  esac

  return 1
}

is_docs_absorb_candidate_path() {
  local aPath="$1"

  if is_docs_archive_pointer_path "${aPath}" || is_docs_collections_dated_path "${aPath}" || is_docs_legacy_path "${aPath}"; then
    return 0
  fi

  return 1
}

is_src_path() {
  local aPath="$1"

  case "${aPath}" in
    src/*)
      return 0
      ;;
  esac

  return 1
}

is_ci_workflow_path() {
  local aPath="$1"

  case "${aPath}" in
    .github/*)
      return 0
      ;;
  esac

  return 1
}

is_test_control_path() {
  local aPath="$1"
  local LBaseName

  LBaseName="$(basename "${aPath}")"

  if [[ "${aPath}" == tests/* && "${LBaseName}" == ".gitignore" ]]; then
    return 0
  fi

  return 1
}

is_test_runtime_record_path() {
  local aPath="$1"
  local LBaseName

  LBaseName="$(basename "${aPath}")"

  if is_test_control_path "${aPath}"; then
    return 1
  fi

  case "${aPath}" in
    tests/*/performance-data/*)
      return 0
      ;;
  esac

  case "${LBaseName}" in
    last-run.txt|latest.txt|perf_*.txt)
      return 0
      ;;
  esac

  return 1
}

is_test_code_path() {
  local aPath="$1"
  local LBaseName

  LBaseName="$(basename "${aPath}")"

  case "${LBaseName}" in
    *.pas|*.lpr|*.lpi|*.inc|*.lfm|*.res)
      return 0
      ;;
  esac

  return 1
}

is_test_script_path() {
  local aPath="$1"
  local LBaseName

  LBaseName="$(basename "${aPath}")"

  case "${LBaseName}" in
    *.sh|*.bat)
      return 0
      ;;
  esac

  return 1
}

is_test_doc_path() {
  local aPath="$1"
  local LBaseName

  LBaseName="$(basename "${aPath}")"

  case "${LBaseName}" in
    *.md)
      return 0
      ;;
  esac

  return 1
}

is_test_output_artifact_path() {
  local aPath="$1"
  local LBaseName

  LBaseName="$(basename "${aPath}")"

  case "${aPath}" in
    tests/_run_all_logs_*/*|tests/*/bin/*|tests/*/lib/*|tests/*/logs/*)
      return 0
      ;;
  esac

  case "${LBaseName}" in
    *_output.txt|build_log.txt|fpcdebug.txt|*.log|*heaptrc*)
      return 0
      ;;
  esac

  return 1
}

is_test_binary_artifact_path() {
  local aPath="$1"
  local LBaseName

  LBaseName="$(basename "${aPath}")"

  if [[ "${aPath}" == tests/* && "${LBaseName}" != *.* ]]; then
    return 0
  fi

  return 1
}

is_test_artifact_path() {
  local aPath="$1"
  if is_test_runtime_record_path "${aPath}" || is_test_control_path "${aPath}"; then
    return 1
  fi

  if is_test_output_artifact_path "${aPath}" || is_test_binary_artifact_path "${aPath}"; then
    return 0
  fi

  return 1
}

is_test_source_path() {
  local aPath="$1"

  case "${aPath}" in
    tests/*)
      if is_test_artifact_path "${aPath}" || is_test_runtime_record_path "${aPath}" || is_test_control_path "${aPath}"; then
        return 1
      fi
      if is_test_code_path "${aPath}" || is_test_script_path "${aPath}" || is_test_doc_path "${aPath}"; then
        return 0
      fi
      return 1
      ;;
  esac

  return 1
}

classify_path() {
  local aPath="$1"

  if is_archive_docs_path "${aPath}"; then
    echo "archive_docs"
    return 0
  fi

  case "${aPath}" in
    src/*|tests/*|.github/*)
      echo "code_or_tests"
      return 0
      ;;
    examples/*|*/BuildOrRun.sh|*/BuildOrRun.bat|*/BuildOrTest.sh|*/BuildOrTest.bat)
      echo "examples_or_build"
      return 0
      ;;
    docs/*)
      echo "docs_current_entry"
      return 0
      ;;
    *)
      echo "other"
      return 0
      ;;
  esac
}

LDetailsMode=0

case "${1:-}" in
  --details)
    LDetailsMode=1
    ;;
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
echo "[INFO] strict L0 retained refs inventory"
echo "[INFO] current_head=${LHeadSha}"

for LRef in "${RETAINED_REFS[@]}"; do
  LCherryOutput="$(git -C "${REPO_ROOT}" cherry -v HEAD "${LRef}" || true)"
  mapfile -t LUniqueCommits < <(printf '%s\n' "${LCherryOutput}" | awk '/^\+/ {print $2}')

  declare -A LSeenPaths=()
  LSampleUniqueCommits=()
  LSampleArchiveDocsPaths=()
  LSampleDocsCurrentEntryPaths=()
  LSampleDocsRootEntryPaths=()
  LSampleDocsModulePaths=()
  LSampleDocsTopicPaths=()
  LSampleDocsGuidePaths=()
  LSampleDocsArchivePointerPaths=()
  LSampleDocsCollectionsDatedPaths=()
  LSampleDocsLegacyPaths=()
  LSampleDocsReportTopicPaths=()
  LSampleDocsAbsorbCandidatePaths=()
  LSampleCodeOrTestsPaths=()
  LSampleSrcPaths=()
  LSampleTestSourcePaths=()
  LSampleTestCodePaths=()
  LSampleTestScriptPaths=()
  LSampleTestDocPaths=()
  LSampleTestRuntimeRecordPaths=()
  LSampleTestControlPaths=()
  LSampleCiWorkflowPaths=()
  LSampleExamplesOrBuildPaths=()
  LSampleExampleSourcePaths=()
  LSampleBuildScriptPaths=()
  LSampleGeneratedOutputPaths=()
  LSampleTestArtifactPaths=()
  LSampleTestOutputArtifactPaths=()
  LSampleTestBinaryArtifactPaths=()
  LSampleOtherPaths=()
  LArchiveDocsPaths=0
  LDocsCurrentEntryPaths=0
  LDocsRootEntryPaths=0
  LDocsModulePaths=0
  LDocsTopicPaths=0
  LDocsGuidePaths=0
  LDocsArchivePointerPaths=0
  LDocsCollectionsDatedPaths=0
  LDocsLegacyPaths=0
  LDocsReportTopicPaths=0
  LDocsAbsorbCandidatePaths=0
  LCodeOrTestsPaths=0
  LSrcPaths=0
  LTestSourcePaths=0
  LTestCodePaths=0
  LTestScriptPaths=0
  LTestDocPaths=0
  LTestRuntimeRecordPaths=0
  LTestControlPaths=0
  LCiWorkflowPaths=0
  LExamplesOrBuildPaths=0
  LExampleSourcePaths=0
  LBuildScriptPaths=0
  LGeneratedOutputPaths=0
  LTestArtifactPaths=0
  LTestOutputArtifactPaths=0
  LTestBinaryArtifactPaths=0
  LOtherPaths=0

  while IFS= read -r LCherryLine; do
    [[ "${LCherryLine}" == +* ]] || continue
    LCommitSha="$(printf '%s\n' "${LCherryLine}" | awk '{print $2}')"
    [[ -n "${LCommitSha}" ]] || continue
    LCommitSubject="${LCherryLine#* ${LCommitSha} }"
    append_sample LSampleUniqueCommits "${LCommitSha} ${LCommitSubject}" 3
  done <<< "${LCherryOutput}"

  for LCommitSha in "${LUniqueCommits[@]}"; do
    [[ -n "${LCommitSha}" ]] || continue
    while IFS= read -r LPath; do
      [[ -n "${LPath}" ]] || continue
      if [[ -n "${LSeenPaths[${LPath}]:-}" ]]; then
        continue
      fi
      LSeenPaths["${LPath}"]=1

      if [[ "${LPath}" == docs/* ]]; then
        if is_docs_root_entry_path "${LPath}"; then
          LDocsRootEntryPaths=$((LDocsRootEntryPaths + 1))
          append_sample LSampleDocsRootEntryPaths "${LPath}" 3
        elif is_docs_module_path "${LPath}"; then
          LDocsModulePaths=$((LDocsModulePaths + 1))
          append_sample LSampleDocsModulePaths "${LPath}" 3
        elif is_docs_topic_path "${LPath}"; then
          LDocsTopicPaths=$((LDocsTopicPaths + 1))
          append_sample LSampleDocsTopicPaths "${LPath}" 3
        elif is_docs_guide_path "${LPath}"; then
          LDocsGuidePaths=$((LDocsGuidePaths + 1))
          append_sample LSampleDocsGuidePaths "${LPath}" 3
        elif is_docs_archive_pointer_path "${LPath}"; then
          LDocsArchivePointerPaths=$((LDocsArchivePointerPaths + 1))
          append_sample LSampleDocsArchivePointerPaths "${LPath}" 3
        elif is_docs_collections_dated_path "${LPath}"; then
          LDocsCollectionsDatedPaths=$((LDocsCollectionsDatedPaths + 1))
          append_sample LSampleDocsCollectionsDatedPaths "${LPath}" 3
        elif is_docs_legacy_path "${LPath}"; then
          LDocsLegacyPaths=$((LDocsLegacyPaths + 1))
          append_sample LSampleDocsLegacyPaths "${LPath}" 3
        elif is_docs_report_topic_path "${LPath}"; then
          LDocsReportTopicPaths=$((LDocsReportTopicPaths + 1))
          append_sample LSampleDocsReportTopicPaths "${LPath}" 3
        fi

        if is_docs_absorb_candidate_path "${LPath}"; then
          LDocsAbsorbCandidatePaths=$((LDocsAbsorbCandidatePaths + 1))
          append_sample LSampleDocsAbsorbCandidatePaths "${LPath}" 3
        fi
      fi

      case "$(classify_path "${LPath}")" in
        archive_docs)
          LArchiveDocsPaths=$((LArchiveDocsPaths + 1))
          append_sample LSampleArchiveDocsPaths "${LPath}" 3
          ;;
        docs_current_entry)
          LDocsCurrentEntryPaths=$((LDocsCurrentEntryPaths + 1))
          append_sample LSampleDocsCurrentEntryPaths "${LPath}" 3
          ;;
        code_or_tests)
          LCodeOrTestsPaths=$((LCodeOrTestsPaths + 1))
          append_sample LSampleCodeOrTestsPaths "${LPath}" 3
          if is_src_path "${LPath}"; then
            LSrcPaths=$((LSrcPaths + 1))
            append_sample LSampleSrcPaths "${LPath}" 3
          elif is_ci_workflow_path "${LPath}"; then
            LCiWorkflowPaths=$((LCiWorkflowPaths + 1))
            append_sample LSampleCiWorkflowPaths "${LPath}" 3
          elif is_test_runtime_record_path "${LPath}"; then
            LTestRuntimeRecordPaths=$((LTestRuntimeRecordPaths + 1))
            append_sample LSampleTestRuntimeRecordPaths "${LPath}" 3
          elif is_test_control_path "${LPath}"; then
            LTestControlPaths=$((LTestControlPaths + 1))
            append_sample LSampleTestControlPaths "${LPath}" 3
          elif is_test_artifact_path "${LPath}"; then
            LTestArtifactPaths=$((LTestArtifactPaths + 1))
            append_sample LSampleTestArtifactPaths "${LPath}" 3
            if is_test_output_artifact_path "${LPath}"; then
              LTestOutputArtifactPaths=$((LTestOutputArtifactPaths + 1))
              append_sample LSampleTestOutputArtifactPaths "${LPath}" 3
            elif is_test_binary_artifact_path "${LPath}"; then
              LTestBinaryArtifactPaths=$((LTestBinaryArtifactPaths + 1))
              append_sample LSampleTestBinaryArtifactPaths "${LPath}" 3
            fi
          elif is_test_source_path "${LPath}"; then
            LTestSourcePaths=$((LTestSourcePaths + 1))
            append_sample LSampleTestSourcePaths "${LPath}" 3
            if is_test_code_path "${LPath}"; then
              LTestCodePaths=$((LTestCodePaths + 1))
              append_sample LSampleTestCodePaths "${LPath}" 3
            elif is_test_script_path "${LPath}"; then
              LTestScriptPaths=$((LTestScriptPaths + 1))
              append_sample LSampleTestScriptPaths "${LPath}" 3
            elif is_test_doc_path "${LPath}"; then
              LTestDocPaths=$((LTestDocPaths + 1))
              append_sample LSampleTestDocPaths "${LPath}" 3
            fi
          fi
          ;;
        examples_or_build)
          LExamplesOrBuildPaths=$((LExamplesOrBuildPaths + 1))
          append_sample LSampleExamplesOrBuildPaths "${LPath}" 3
          if is_build_script_path "${LPath}"; then
            LBuildScriptPaths=$((LBuildScriptPaths + 1))
            append_sample LSampleBuildScriptPaths "${LPath}" 3
          elif is_generated_output_path "${LPath}"; then
            LGeneratedOutputPaths=$((LGeneratedOutputPaths + 1))
            append_sample LSampleGeneratedOutputPaths "${LPath}" 3
          else
            LExampleSourcePaths=$((LExampleSourcePaths + 1))
            append_sample LSampleExampleSourcePaths "${LPath}" 3
          fi
          ;;
        *)
          LOtherPaths=$((LOtherPaths + 1))
          append_sample LSampleOtherPaths "${LPath}" 3
          ;;
      esac
    done < <(git -C "${REPO_ROOT}" show --name-only --format= "${LCommitSha}")
  done

  if [[ "${#LUniqueCommits[@]}" == "0" ]]; then
    LRecommendation="no-unique-commits"
  elif [[ "${LArchiveDocsPaths}" != "0" ]]; then
    LRecommendation="absorb-archive-first"
  elif [[ "${LCodeOrTestsPaths}" != "0" || "${LExamplesOrBuildPaths}" != "0" ]]; then
    LRecommendation="review-code-before-absorb"
  else
    LRecommendation="review-current-docs-before-absorb"
  fi

  if [[ "${#LUniqueCommits[@]}" == "0" ]]; then
    LNextFocus="none"
  elif [[ "${LTestRuntimeRecordPaths}" != "0" || "${LTestControlPaths}" != "0" || "${LTestArtifactPaths}" != "0" ]]; then
    LNextFocus="test-hygiene-first"
  elif [[ "${LArchiveDocsPaths}" != "0" ]]; then
    LNextFocus="archive-docs-first"
  elif [[ "${LSrcPaths}" != "0" || "${LTestSourcePaths}" != "0" || "${LCiWorkflowPaths}" != "0" || "${LExamplesOrBuildPaths}" != "0" ]]; then
    LNextFocus="source-review-first"
  else
    LNextFocus="current-docs-first"
  fi

  echo "== ${LRef} =="
  echo "unique_commit_count=${#LUniqueCommits[@]}"
  echo "archive_docs_paths=${LArchiveDocsPaths}"
  echo "docs_current_entry_paths=${LDocsCurrentEntryPaths}"
  echo "docs_root_entry_paths=${LDocsRootEntryPaths}"
  echo "docs_module_paths=${LDocsModulePaths}"
  echo "docs_topic_paths=${LDocsTopicPaths}"
  echo "docs_guide_paths=${LDocsGuidePaths}"
  echo "docs_archive_pointer_paths=${LDocsArchivePointerPaths}"
  echo "docs_collections_dated_paths=${LDocsCollectionsDatedPaths}"
  echo "docs_legacy_paths=${LDocsLegacyPaths}"
  echo "docs_report_topic_paths=${LDocsReportTopicPaths}"
  echo "docs_absorb_candidate_paths=${LDocsAbsorbCandidatePaths}"
  echo "code_or_tests_paths=${LCodeOrTestsPaths}"
  echo "src_paths=${LSrcPaths}"
  echo "test_source_paths=${LTestSourcePaths}"
  echo "test_code_paths=${LTestCodePaths}"
  echo "test_script_paths=${LTestScriptPaths}"
  echo "test_doc_paths=${LTestDocPaths}"
  echo "test_runtime_record_paths=${LTestRuntimeRecordPaths}"
  echo "test_control_paths=${LTestControlPaths}"
  echo "ci_workflow_paths=${LCiWorkflowPaths}"
  echo "examples_or_build_paths=${LExamplesOrBuildPaths}"
  echo "example_source_paths=${LExampleSourcePaths}"
  echo "build_script_paths=${LBuildScriptPaths}"
  echo "generated_output_paths=${LGeneratedOutputPaths}"
  echo "test_artifact_paths=${LTestArtifactPaths}"
  echo "test_output_artifact_paths=${LTestOutputArtifactPaths}"
  echo "test_binary_artifact_paths=${LTestBinaryArtifactPaths}"
  echo "other_paths=${LOtherPaths}"
  echo "recommendation=${LRecommendation}"
  echo "next_focus=${LNextFocus}"

  if [[ "${LDetailsMode}" == "1" ]]; then
    if (( ${#LSampleUniqueCommits[@]} > 0 )); then
      echo "sample_unique_commits=$(join_samples LSampleUniqueCommits)"
    fi
    if (( ${#LSampleArchiveDocsPaths[@]} > 0 )); then
      echo "sample_archive_docs_paths=$(join_samples LSampleArchiveDocsPaths)"
    fi
    if (( ${#LSampleDocsCurrentEntryPaths[@]} > 0 )); then
      echo "sample_docs_current_entry_paths=$(join_samples LSampleDocsCurrentEntryPaths)"
    fi
    if (( ${#LSampleDocsRootEntryPaths[@]} > 0 )); then
      echo "sample_docs_root_entry_paths=$(join_samples LSampleDocsRootEntryPaths)"
    fi
    if (( ${#LSampleDocsModulePaths[@]} > 0 )); then
      echo "sample_docs_module_paths=$(join_samples LSampleDocsModulePaths)"
    fi
    if (( ${#LSampleDocsTopicPaths[@]} > 0 )); then
      echo "sample_docs_topic_paths=$(join_samples LSampleDocsTopicPaths)"
    fi
    if (( ${#LSampleDocsGuidePaths[@]} > 0 )); then
      echo "sample_docs_guide_paths=$(join_samples LSampleDocsGuidePaths)"
    fi
    if (( ${#LSampleDocsArchivePointerPaths[@]} > 0 )); then
      echo "sample_docs_archive_pointer_paths=$(join_samples LSampleDocsArchivePointerPaths)"
    fi
    if (( ${#LSampleDocsCollectionsDatedPaths[@]} > 0 )); then
      echo "sample_docs_collections_dated_paths=$(join_samples LSampleDocsCollectionsDatedPaths)"
    fi
    if (( ${#LSampleDocsLegacyPaths[@]} > 0 )); then
      echo "sample_docs_legacy_paths=$(join_samples LSampleDocsLegacyPaths)"
    fi
    if (( ${#LSampleDocsReportTopicPaths[@]} > 0 )); then
      echo "sample_docs_report_topic_paths=$(join_samples LSampleDocsReportTopicPaths)"
    fi
    if (( ${#LSampleDocsAbsorbCandidatePaths[@]} > 0 )); then
      echo "sample_docs_absorb_candidate_paths=$(join_samples LSampleDocsAbsorbCandidatePaths)"
    fi
    if (( ${#LSampleCodeOrTestsPaths[@]} > 0 )); then
      echo "sample_code_or_tests_paths=$(join_samples LSampleCodeOrTestsPaths)"
    fi
    if (( ${#LSampleSrcPaths[@]} > 0 )); then
      echo "sample_src_paths=$(join_samples LSampleSrcPaths)"
    fi
    if (( ${#LSampleTestSourcePaths[@]} > 0 )); then
      echo "sample_test_source_paths=$(join_samples LSampleTestSourcePaths)"
    fi
    if (( ${#LSampleTestCodePaths[@]} > 0 )); then
      echo "sample_test_code_paths=$(join_samples LSampleTestCodePaths)"
    fi
    if (( ${#LSampleTestScriptPaths[@]} > 0 )); then
      echo "sample_test_script_paths=$(join_samples LSampleTestScriptPaths)"
    fi
    if (( ${#LSampleTestDocPaths[@]} > 0 )); then
      echo "sample_test_doc_paths=$(join_samples LSampleTestDocPaths)"
    fi
    if (( ${#LSampleTestRuntimeRecordPaths[@]} > 0 )); then
      echo "sample_test_runtime_record_paths=$(join_samples LSampleTestRuntimeRecordPaths)"
    fi
    if (( ${#LSampleTestControlPaths[@]} > 0 )); then
      echo "sample_test_control_paths=$(join_samples LSampleTestControlPaths)"
    fi
    if (( ${#LSampleCiWorkflowPaths[@]} > 0 )); then
      echo "sample_ci_workflow_paths=$(join_samples LSampleCiWorkflowPaths)"
    fi
    if (( ${#LSampleExamplesOrBuildPaths[@]} > 0 )); then
      echo "sample_examples_or_build_paths=$(join_samples LSampleExamplesOrBuildPaths)"
    fi
    if (( ${#LSampleExampleSourcePaths[@]} > 0 )); then
      echo "sample_example_source_paths=$(join_samples LSampleExampleSourcePaths)"
    fi
    if (( ${#LSampleBuildScriptPaths[@]} > 0 )); then
      echo "sample_build_script_paths=$(join_samples LSampleBuildScriptPaths)"
    fi
    if (( ${#LSampleGeneratedOutputPaths[@]} > 0 )); then
      echo "sample_generated_output_paths=$(join_samples LSampleGeneratedOutputPaths)"
    fi
    if (( ${#LSampleTestArtifactPaths[@]} > 0 )); then
      echo "sample_test_artifact_paths=$(join_samples LSampleTestArtifactPaths)"
    fi
    if (( ${#LSampleTestOutputArtifactPaths[@]} > 0 )); then
      echo "sample_test_output_artifact_paths=$(join_samples LSampleTestOutputArtifactPaths)"
    fi
    if (( ${#LSampleTestBinaryArtifactPaths[@]} > 0 )); then
      echo "sample_test_binary_artifact_paths=$(join_samples LSampleTestBinaryArtifactPaths)"
    fi
    if (( ${#LSampleOtherPaths[@]} > 0 )); then
      echo "sample_other_paths=$(join_samples LSampleOtherPaths)"
    fi
  fi
done

echo "[PASS] strict L0 retained refs inventory completed"
