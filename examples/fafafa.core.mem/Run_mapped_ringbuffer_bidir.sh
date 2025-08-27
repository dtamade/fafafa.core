#!/usr/bin/env bash
set -euo pipefail
NAME="MRB_$(date +%H%M%S)_$RANDOM"
echo "Using shared name: $NAME"
DIR=$(cd "$(dirname "$0")" && pwd)
"$DIR/bin/example_mapped_ringbuffer_bidir" creator "$NAME" 65536 4 100000 32 0 &
sleep 1
"$DIR/bin/example_mapped_ringbuffer_bidir" opener  "$NAME" 0 0 100000 32 0 &
wait

