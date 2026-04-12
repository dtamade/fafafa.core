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

This script inventories the unique history still carried by the retained
strict L0 refs and buckets the touched paths for absorption planning.
EOF
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
echo "[INFO] strict L0 retained refs inventory"
echo "[INFO] current_head=${LHeadSha}"

for LRef in "${RETAINED_REFS[@]}"; do
  LCherryOutput="$(git -C "${REPO_ROOT}" cherry -v HEAD "${LRef}" || true)"
  mapfile -t LUniqueCommits < <(printf '%s\n' "${LCherryOutput}" | awk '/^\+/ {print $2}')

  declare -A LSeenPaths=()
  LArchiveDocsPaths=0
  LDocsCurrentEntryPaths=0
  LCodeOrTestsPaths=0
  LExamplesOrBuildPaths=0
  LOtherPaths=0

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
          ;;
        docs_current_entry)
          LDocsCurrentEntryPaths=$((LDocsCurrentEntryPaths + 1))
          ;;
        code_or_tests)
          LCodeOrTestsPaths=$((LCodeOrTestsPaths + 1))
          ;;
        examples_or_build)
          LExamplesOrBuildPaths=$((LExamplesOrBuildPaths + 1))
          ;;
        *)
          LOtherPaths=$((LOtherPaths + 1))
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
  echo "other_paths=${LOtherPaths}"
  echo "recommendation=${LRecommendation}"
done

echo "[PASS] strict L0 retained refs inventory completed"
