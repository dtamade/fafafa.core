#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
README_FILE="${ROOT}/examples/fafafa.core.sync.mutex/README.md"

fail() {
  echo "[FAIL] $1" >&2
  exit 1
}

[[ -f "${README_FILE}" ]] || fail "missing sync.mutex README"

CURRENT_SECTION="$(
  awk '
    /^## Current entry$/ { in_section=1; next }
    /^## / && in_section { exit }
    in_section { print }
  ' "${README_FILE}"
)"

STANDALONE_SECTION="$(
  awk '
    /^## Standalone sources$/ { in_section=1; next }
    /^## / && in_section { exit }
    in_section { print }
  ' "${README_FILE}"
)"

rg -n '^## Current entry$' "${README_FILE}" >/dev/null \
  || fail "README no longer exposes a Current entry section"

printf '%s' "${CURRENT_SECTION}" | rg -n -F 'example_basic_usage.lpi' >/dev/null \
  || fail "README current entry no longer names example_basic_usage.lpi"

printf '%s' "${CURRENT_SECTION}" | rg -n -F 'example_advanced_patterns.lpi' >/dev/null \
  || fail "README current entry no longer names example_advanced_patterns.lpi"

printf '%s' "${CURRENT_SECTION}" | rg -n -F 'example_basic_usage.lpr' >/dev/null \
  || fail "README current entry no longer names example_basic_usage.lpr"

printf '%s' "${CURRENT_SECTION}" | rg -n -F 'example_advanced_patterns.lpr' >/dev/null \
  || fail "README current entry no longer names example_advanced_patterns.lpr"

if printf '%s' "${CURRENT_SECTION}" | rg -n -F 'example_performance_comparison.lpr' >/dev/null; then
  fail "README still treats example_performance_comparison.lpr as current-entry source"
fi

if printf '%s' "${CURRENT_SECTION}" | rg -n -F 'example_comprehensive.lpr' >/dev/null; then
  fail "README still treats example_comprehensive.lpr as current-entry source"
fi

rg -n '^## Standalone sources$' "${README_FILE}" >/dev/null \
  || fail "README no longer exposes a Standalone sources section"

printf '%s' "${STANDALONE_SECTION}" | rg -n -F 'example_performance_comparison.lpr' >/dev/null \
  || fail "README standalone sources no longer names example_performance_comparison.lpr"

printf '%s' "${STANDALONE_SECTION}" | rg -n -F 'example_comprehensive.lpr' >/dev/null \
  || fail "README standalone sources no longer names example_comprehensive.lpr"

if ! printf '%s' "${STANDALONE_SECTION}" | rg -n -F '不在 `BuildOrRun*` 默认链路里' >/dev/null; then
  fail "README standalone sources no longer explains they are outside the default BuildOrRun chain"
fi

if rg -n -F 'retained-refs triage 里当前最值得关注的 example source' "${README_FILE}" >/dev/null; then
  fail "README still advertises a fresh retained-refs sync.mutex example hotspot"
fi

echo "[PASS] sync.mutex README current-entry contract is aligned with today scripts"
