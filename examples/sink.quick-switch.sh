#!/usr/bin/env bash
# Bash: Quick switch sinks for runner/benchmark/thread
# Usage:
#   ./examples/sink.quick-switch.sh runner console|json|junit [outfile]
#   ./examples/sink.quick-switch.sh bench   console|json       [outfile]
#   ./examples/sink.quick-switch.sh thread  # runs thread examples (BuildOrRun.sh run)
set -euo pipefail

TARGET=${1:-runner}
SINK=${2:-console}
OUTFILE=${3:-}

if [[ "$TARGET" == "runner" ]]; then
  if [[ "$SINK" == "console" ]]; then
    FAFAFA_TEST_USE_SINK_CONSOLE=1 ./tests/fafafa.core.test/bin/tests --summary-only
  elif [[ "$SINK" == "json" ]]; then
    FAFAFA_TEST_USE_SINK_JSON=1 ./tests/fafafa.core.test/bin/tests --json="${OUTFILE:-out/report.json}" --no-console
  elif [[ "$SINK" == "junit" ]]; then
    FAFAFA_TEST_USE_SINK_JUNIT=1 ./tests/fafafa.core.test/bin/tests --junit="${OUTFILE:-out/report.xml}" --no-console
  else
    echo "unsupported sink for runner: $SINK" >&2; exit 1
  fi
elif [[ "$TARGET" == "bench" ]]; then
  if [[ "$SINK" == "console" ]]; then
    FAFAFA_BENCH_USE_SINK_CONSOLE=1 ./tests/fafafa.core.benchmark/bin/tests_benchmark --report=console
  elif [[ "$SINK" == "json" ]]; then
    FAFAFA_BENCH_USE_SINK_JSON=1 ./tests/fafafa.core.benchmark/bin/tests_benchmark --report=json --outfile="${OUTFILE:-out/bench.json}"
  else
    echo "bench target supports console/json only" >&2; exit 1
  fi
elif [[ "$TARGET" == "thread" ]]; then
  # Linux/macOS thread examples runner wrapper
  pushd examples/fafafa.core.thread >/dev/null
  chmod +x BuildOrRun.sh || true
  ./BuildOrRun.sh run
  popd >/dev/null

else
  echo "unknown target: $TARGET" >&2; exit 1
fi

