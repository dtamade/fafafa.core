#!/usr/bin/env bash
set -euo pipefail

# Root: this script lives under tests/
TESTS_ROOT="$(cd "$(dirname "$0")" && pwd)"
LOG_DIR="$TESTS_ROOT/_run_all_logs_sh"
SUMMARY_FILE="$TESTS_ROOT/run_all_tests_summary_sh.txt"
mkdir -p "$LOG_DIR"

# Filters: pass module names as args to run only those (space-separated)
# STOP_ON_FAIL=1 to stop on first failure
FILTER=("$@")

TOTAL=0
PASSED=0
FAILED=0
FAILED_LIST=()

should_run() {
  local mod="$1"
  if [ ${#FILTER[@]} -eq 0 ]; then return 0; fi
  for f in "${FILTER[@]}"; do
    if [[ "$f" == "$mod" ]]; then return 0; fi
  done
  return 1
}

run_one() {
  local script="$1"
  local dir
  dir="$(dirname "$script")"
  local mod
  mod="$(basename "$dir")"
  if ! should_run "$mod"; then return 0; fi
  local log_file="$LOG_DIR/$mod.log"

  {
    echo "========================================"
    echo "Module: $mod"
    echo "Script: $script"
    echo "Started: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "========================================"
  } >"$log_file"

  TOTAL=$((TOTAL+1))
  ( set -e; cd "$dir"; bash -lc "'$script'" ) >>"$log_file" 2>&1 || true
  local rc
  rc=$?

  if [ $rc -eq 0 ]; then
    PASSED=$((PASSED+1))
    echo "[PASS] $mod (rc=$rc)"
  else
    FAILED=$((FAILED+1))
    echo "[FAIL] $mod (rc=$rc)"
    FAILED_LIST+=("$mod")
    if [ "${STOP_ON_FAIL:-0}" = "1" ]; then
      return 1
    fi
  fi
}

echo "Running module test scripts under: $TESTS_ROOT"
echo "Logs: $LOG_DIR"

declare -a scripts
# Prefer BuildOrTest.bat via wine/cmd if needed; but focus on sh runners here
while IFS= read -r -d '' f; do scripts+=("$f"); done < <(find "$TESTS_ROOT" -type f -name 'BuildOrTest.sh' -print0)
while IFS= read -r -d '' f; do scripts+=("$f"); done < <(find "$TESTS_ROOT" -type f -name 'BuildAndTest.sh' -print0)

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
} >"$SUMMARY_FILE"

cat "$SUMMARY_FILE"

if [ $FAILED -gt 0 ]; then exit 1; else exit 0; fi

