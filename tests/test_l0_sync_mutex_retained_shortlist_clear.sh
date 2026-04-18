#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_FILE="$(mktemp)"
trap 'rm -f "${LOG_FILE}"' EXIT

cd "${ROOT}"

if ! bash tests/report_strict_l0_retained_refs_source_review_shortlist.sh >"${LOG_FILE}" 2>&1; then
  echo "[FAIL] strict L0 retained refs source-review shortlist failed unexpectedly"
  cat "${LOG_FILE}"
  exit 1
fi

for ref_name in l0-mainline-closeout-20260411 l0-main-rescue; do
  if ! rg -n -U "== ${ref_name} ==\\n(?:.*\\n)*?review_candidate_paths=0" "${LOG_FILE}" >/dev/null; then
    echo "[FAIL] ${ref_name} still reports fresh source-review candidates"
    cat "${LOG_FILE}"
    exit 1
  fi
done

if rg -n '^sample_review_candidate_paths=.*example_performance_comparison\.lpr' "${LOG_FILE}" >/dev/null; then
  echo "[FAIL] sync.mutex performance example still appears in sample_review_candidate_paths"
  cat "${LOG_FILE}"
  exit 1
fi

if rg -n '^sample_examples_build_review_paths=.*example_performance_comparison\.lpr' "${LOG_FILE}" >/dev/null; then
  echo "[FAIL] sync.mutex performance example still appears in sample_examples_build_review_paths"
  cat "${LOG_FILE}"
  exit 1
fi

echo "[PASS] strict L0 retained refs source-review shortlist is clear of sync.mutex performance residue"
