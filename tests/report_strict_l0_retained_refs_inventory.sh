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
build scripts, generated outputs, and test artifacts.
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

is_test_artifact_path() {
  local aPath="$1"
  local LBaseName
  local LExt

  LBaseName="$(basename "${aPath}")"
  LExt="${LBaseName##*.}"

  case "${aPath}" in
    tests/_run_all_logs_*/*|tests/*/bin/*|tests/*/lib/*|tests/*/logs/*)
      return 0
      ;;
  esac

  case "${LBaseName}" in
    *_output.txt|build_log.txt|fpcdebug.txt|*.log)
      return 0
      ;;
  esac

  if [[ "${aPath}" == tests/* ]]; then
    case "${LExt}" in
      pas|lpr|lpi|md|sh|bat|res|txt|log)
        ;;
      *)
        if [[ "${LBaseName}" != *.* ]]; then
          return 0
        fi
        ;;
    esac
  fi

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
  LSampleCodeOrTestsPaths=()
  LSampleExamplesOrBuildPaths=()
  LSampleExampleSourcePaths=()
  LSampleBuildScriptPaths=()
  LSampleGeneratedOutputPaths=()
  LSampleTestArtifactPaths=()
  LSampleOtherPaths=()
  LArchiveDocsPaths=0
  LDocsCurrentEntryPaths=0
  LCodeOrTestsPaths=0
  LExamplesOrBuildPaths=0
  LExampleSourcePaths=0
  LBuildScriptPaths=0
  LGeneratedOutputPaths=0
  LTestArtifactPaths=0
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
          if is_test_artifact_path "${LPath}"; then
            LTestArtifactPaths=$((LTestArtifactPaths + 1))
            append_sample LSampleTestArtifactPaths "${LPath}" 3
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

  echo "== ${LRef} =="
  echo "unique_commit_count=${#LUniqueCommits[@]}"
  echo "archive_docs_paths=${LArchiveDocsPaths}"
  echo "docs_current_entry_paths=${LDocsCurrentEntryPaths}"
  echo "code_or_tests_paths=${LCodeOrTestsPaths}"
  echo "examples_or_build_paths=${LExamplesOrBuildPaths}"
  echo "example_source_paths=${LExampleSourcePaths}"
  echo "build_script_paths=${LBuildScriptPaths}"
  echo "generated_output_paths=${LGeneratedOutputPaths}"
  echo "test_artifact_paths=${LTestArtifactPaths}"
  echo "other_paths=${LOtherPaths}"
  echo "recommendation=${LRecommendation}"

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
    if (( ${#LSampleCodeOrTestsPaths[@]} > 0 )); then
      echo "sample_code_or_tests_paths=$(join_samples LSampleCodeOrTestsPaths)"
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
    if (( ${#LSampleOtherPaths[@]} > 0 )); then
      echo "sample_other_paths=$(join_samples LSampleOtherPaths)"
    fi
  fi
done

echo "[PASS] strict L0 retained refs inventory completed"
