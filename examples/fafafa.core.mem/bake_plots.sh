#!/usr/bin/env bash
set -euo pipefail
BASE="$(cd "$(dirname "$0")" && pwd)"
CSV_DIR="$BASE/bench_out"
if [[ ! -d "$CSV_DIR" ]]; then
  echo "bench_out not found" >&2
  exit 1
fi
for E in 4 8 16; do
  INFILE="$CSV_DIR/mrb_bidir_bench_e${E}.csv"
  [[ -f "$INFILE" ]] || continue
  for C in 4096 65536 262144; do
    for M in 100000 500000; do
      gnuplot -e "infile='$INFILE';outfile='$CSV_DIR/plot_qps_vs_batch_e${E}_cap${C}_msg${M}.png';elem=${E};capacity=${C};msg=${M};metric_col=10" "$BASE/gnuplot_mrb_qps_vs_batch.plt"
      gnuplot -e "infile='$INFILE';outfile='$CSV_DIR/plot_qps_vs_capacity_e${E}_batch64_msg${M}.png';elem=${E};batch=64;msg=${M};metric_col=10" "$BASE/gnuplot_mrb_qps_vs_capacity.plt"
      gnuplot -e "infile='$INFILE';outfile='$CSV_DIR/plot_qps_vs_msg_e${E}_cap${C}_batch64.png';elem=${E};capacity=${C};batch=64;metric_col=10" "$BASE/gnuplot_mrb_qps_vs_msg.plt"
    done
  done
done

