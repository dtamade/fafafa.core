#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

# Build and run example_id
../../tools/lazbuild.bat example_id.lpi
"./bin/example_id" || true

# Build and run example_snowflake_config
../../tools/lazbuild.bat example_snowflake_config.lpi
# Prefer args over env; you can also export FA_SF_WORKER_ID/FA_SF_EPOCH_MS
./bin/example_snowflake_config --worker-id=2 --sf-epoch-ms=1288834974657 || true

