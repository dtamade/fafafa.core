#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

LAZBUILD=${LAZBUILD:-lazbuild}
FPC=${FPC:-fpc}

function build_lpr() {
  local lpr="$1"
  if command -v "$LAZBUILD" >/dev/null 2>&1 && [[ -f "${lpr%.lpr}.lpi" ]]; then
    "$LAZBUILD" --build-mode=Release "$lpr"
  else
    "$FPC" -MObjFPC -Scghi -O2 -Xs -XX -CX -Sd -Si -Sg -vewnhibq -Fi. -Fu. -Fu../../src -FEbin "$lpr"
  fi
}

case "${1:-build}" in
  build)
    # 清理已有二进制
    for e in example_thread_channel example_thread_scheduler example_thread_best_practices example_thread_future_helpers example_thread_select_nonpolling example_thread_select_best_practices example_thread_select_bench example_thread_cancel_io_batch example_metrics_light example_thread_spawn_token example_thread_wait_or_cancel example_thread_channel_select_cancel example_thread_scheduler_cancel_timeout example_thread_channel_timeout_multi_select benchmark_taskitem_pool; do
      [[ -f "./bin/$e" ]] && rm -f "./bin/$e" || true
      [[ -f "./bin/$e.exe" ]] && rm -f "./bin/$e.exe" || true
    done

    # 构建
    build_lpr example_thread_channel.lpr
    build_lpr example_thread_scheduler.lpr
    build_lpr example_thread_best_practices.lpr
    build_lpr example_thread_future_helpers.lpr
    build_lpr example_thread_select_nonpolling.lpr
    build_lpr example_thread_select_best_practices.lpr
    build_lpr example_thread_select_bench.lpr
    build_lpr example_thread_cancel_io_batch.lpr
    build_lpr example_metrics_light.lpr
    build_lpr example_thread_spawn_token.lpr
    build_lpr example_thread_wait_or_cancel.lpr
    build_lpr example_thread_channel_select_cancel.lpr
    build_lpr example_thread_scheduler_cancel_timeout.lpr
    build_lpr example_thread_channel_timeout_multi_select.lpr
    ;;
  run)
    "$0" build
    # If a specific example name is provided, only run that one
    if [[ $# -ge 2 ]]; then
      target="$2"
      exe="./bin/$target"
      [[ -x "$exe" ]] || exe="./bin/$target.exe"
      if [[ -x "$exe" ]]; then
        "$exe"
      else
        echo "Example not found: $target (looked for ./bin/$target and ./bin/$target.exe)" >&2
        exit 1
      fi
      exit 0
    fi
    echo "Running examples..."
    ./bin/example_thread_channel || true
    ./bin/example_thread_scheduler || true
    ./bin/example_thread_best_practices || true
    ./bin/example_thread_future_helpers || true
    ./bin/example_thread_cancel_io_batch || true
    ./bin/example_metrics_light || true
    ./bin/example_thread_spawn_token || true
    ./bin/example_thread_wait_or_cancel || true
    ./bin/example_thread_channel_select_cancel || true
    ./bin/example_thread_scheduler_cancel_timeout || true
    ./bin/example_thread_select_best_practices || true
    ./bin/example_thread_channel_timeout_multi_select || true
    ;;
  *)
    echo "Usage: $0 [build|run [example_binary_name]]" >&2
    echo "  e.g. $0 run example_thread_wait_or_cancel" >&2
    exit 2
    ;;
fi

