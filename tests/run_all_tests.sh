#!/usr/bin/env bash
set -euo pipefail

# Root: this script lives under tests/
TESTS_ROOT="$(cd "$(dirname "$0")" && pwd)"
LOG_DIR="$TESTS_ROOT/_run_all_logs_sh"
SUMMARY_FILE="$TESTS_ROOT/run_all_tests_summary_sh.txt"
mkdir -p "$LOG_DIR"

# Filters: pass module names as args to run only those (space-separated)
# Module name rule: relative directory under tests/, with path separators replaced by dots.
# Examples:
#   tests/fafafa.core.json           -> fafafa.core.json
#   tests/fafafa.core.collections/vec -> fafafa.core.collections.vec
#
# Compatibility: also accepts basename filters (e.g. "vec") and group filters
# (e.g. "fafafa.core.collections" matches "fafafa.core.collections.vec").
# Prefix an argument with '=' to force exact-only match and skip prefix expansion.
# Example: '=fafafa.core.simd' matches only that module.
#
# STOP_ON_FAIL=1 to stop on first failure
FILTER=("$@")
FILTER_PROVIDED=0
if [ ${#FILTER[@]} -gt 0 ]; then FILTER_PROVIDED=1; fi

TOTAL=0
PASSED=0
FAILED=0
FAILED_LIST=()
SELECTED=0

should_run() {
  local module="$1"
  local basename="$2"
  if [ ${#FILTER[@]} -eq 0 ]; then return 0; fi

  for raw in "${FILTER[@]}"; do
    local exact_only=0
    if [[ -z "${raw}" ]]; then continue; fi
    local f="${raw//\//.}"
    f="${f//\\/.}"

    if [[ "$f" == =* ]]; then
      exact_only=1
      f="${f#=}"
    fi

    if [[ -z "$f" ]]; then continue; fi

    # Exact match
    if [[ "$f" == "$module" || "$f" == "$basename" ]]; then
      return 0
    fi

    if [[ "$exact_only" -eq 1 ]]; then
      continue
    fi

    # Group/prefix match: "a.b" selects "a.b.c"
    if [[ "$module" == "$f."* ]]; then
      return 0
    fi
  done

  return 1
}

run_one() {
  local script="$1"
  local dir
  dir="$(dirname "$script")"
  local rel_dir="${dir#"$TESTS_ROOT"/}"
  local module="${rel_dir//\//.}"
  local basename
  basename="$(basename "$dir")"

  if ! should_run "$module" "$basename"; then return 0; fi
  local log_file="$LOG_DIR/$module.log"

  {
    echo "========================================"
    echo "Module: $module"
    echo "Basename: $basename"
    echo "Script: $script"
    echo "Started: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "========================================"
  } >"$log_file"

  TOTAL=$((TOTAL+1))
  SELECTED=$((SELECTED+1))
  local rc=0
  local action="${RUN_ACTION:-test}"

  # Run module script from within its directory so relative paths work.
  # Capture failures without letting `set -e` abort the whole run.
  if ( cd "$dir"; bash "./$(basename "$script")" "$action" ) >>"$log_file" 2>&1; then
    rc=0
  else
    rc=$?
  fi

  if [ $rc -eq 0 ]; then
    PASSED=$((PASSED+1))
    echo "[PASS] $module (rc=$rc)"
  else
    FAILED=$((FAILED+1))
    echo "[FAIL] $module (rc=$rc)"
    FAILED_LIST+=("$module")
    if [ "${STOP_ON_FAIL:-0}" = "1" ]; then
      return 1
    fi
  fi
}

echo "Running module test scripts under: $TESTS_ROOT"
echo "Logs: $LOG_DIR"

declare -a scripts

# Collect unique module directories, then pick the preferred runner per directory.
# Preference: BuildOrTest.sh, fallback: BuildAndTest.sh (only when BuildOrTest.sh absent).
while IFS= read -r dir; do
  if [[ -f "$dir/BuildOrTest.sh" ]]; then
    scripts+=("$dir/BuildOrTest.sh")
  elif [[ -f "$dir/BuildAndTest.sh" ]]; then
    scripts+=("$dir/BuildAndTest.sh")
  fi
done < <(
  find "$TESTS_ROOT" -type f \( -name 'BuildOrTest.sh' -o -name 'BuildAndTest.sh' \) -print0 |
    xargs -0 -n1 dirname |
    sort -u
)

for s in "${scripts[@]}"; do
  run_one "$s" || break
done

{
  echo "========================================"
  echo "Run-all summary ($(date '+%Y-%m-%d %H:%M:%S'))"
  echo "Logs dir: $LOG_DIR"
  echo "========================================"
  echo "Total:  $TOTAL"
  echo "Passed: $PASSED"
  echo "Failed: $FAILED"
  if [ ${#FAILED_LIST[@]} -gt 0 ]; then
    echo -n "Failed modules: "; (IFS=","; echo "${FAILED_LIST[*]}")
  fi
  if [ "$FILTER_PROVIDED" = "1" ] && [ "$SELECTED" -eq 0 ]; then
    echo "Filter matched 0 modules."
    echo -n "Filter args: "; (IFS=" "; echo "${FILTER[*]}")
  fi
} >"$SUMMARY_FILE"

cat "$SUMMARY_FILE"

if [ "$FILTER_PROVIDED" = "1" ] && [ "$SELECTED" -eq 0 ]; then exit 2; fi
if [ $FAILED -gt 0 ]; then exit 1; else exit 0; fi
