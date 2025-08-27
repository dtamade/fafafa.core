# Gnuplot template: plot QPS vs batch_size for mappedRingBuffer benchmark
# Usage example:
#   gnuplot -e "infile='bench_out/mrb_bidir_bench_e4.csv';outfile='bench_out/plot_qps_vs_batch_e4_cap65536_msg100000.png';elem=4;capacity=65536;msg=100000;metric_col=10" gnuplot_mrb_qps_vs_batch.plt
# metric_col: 9=qps_avg, 10=qps_median, 11=qps_std

if (!exists("infile")) infile='bench_out/mrb_bidir_bench_e4.csv'
if (!exists("outfile")) outfile='bench_out/plot_qps_vs_batch.png'
if (!exists("elem")) elem=4
if (!exists("capacity")) capacity=65536
if (!exists("msg")) msg=100000
if (!exists("metric_col")) metric_col=10

set datafile separator ","
set key left top
set grid
set term pngcairo size 1200,800 font ",12"
set output outfile
set title sprintf("QPS vs Batch (elem=%d, cap=%d, msg=%d)", elem, capacity, msg)
set xlabel "batch_size"
set ylabel (metric_col==9 ? "QPS (avg)" : (metric_col==10 ? "QPS (median)" : "QPS (std approx)"))

# Helper macros
col(n) = column(n)
flt() = (int(col(2))==elem && int(col(1))==capacity && int(col(3))==msg) ? 1 : 0
x() = flt() ? col(4) : 1/0
y() = flt() ? col(metric_col) : 1/0

plot infile using (x()):(y()) with linespoints lw 2 pt 7 title sprintf("cap=%d", capacity)

# Multi-capacity overlay (uncomment to compare different caps on same elem/msg)
# caps = "4096 65536 262144"
# plot for [cap in caps] infile using ( (int(col(2))==elem && int(col(1))==int(cap) && int(col(3))==msg) ? col(4) : 1/0 ) : \
#                               ( (int(col(2))==elem && int(col(1))==int(cap) && int(col(3))==msg) ? col(metric_col) : 1/0 ) \
#                               with linespoints lw 2 pt 7 title sprintf("cap=%s", cap)

