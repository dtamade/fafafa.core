# Gnuplot template: plot QPS vs capacity for mappedRingBuffer benchmark
# Usage example:
#   gnuplot -e "infile='bench_out/mrb_bidir_bench_e4.csv';outfile='bench_out/plot_qps_vs_capacity_e4_batch64_msg100000.png';elem=4;batch=64;msg=100000;metric_col=10" gnuplot_mrb_qps_vs_capacity.plt
# metric_col: 9=qps_avg, 10=qps_median, 11=qps_std

if (!exists("infile")) infile='bench_out/mrb_bidir_bench_e4.csv'
if (!exists("outfile")) outfile='bench_out/plot_qps_vs_capacity.png'
if (!exists("elem")) elem=4
if (!exists("batch")) batch=64
if (!exists("msg")) msg=100000
if (!exists("metric_col")) metric_col=10

set datafile separator ","
set key left top
set grid
set term pngcairo size 1200,800 font ",12"
set output outfile
set title sprintf("QPS vs Capacity (elem=%d, batch=%d, msg=%d)", elem, batch, msg)
set xlabel "capacity"
set ylabel (metric_col==9 ? "QPS (avg)" : (metric_col==10 ? "QPS (median)" : "QPS (std approx)"))
set logscale x 2
set format x "%.0f"

col(n) = column(n)
flt() = (int(col(2))==elem && int(col(4))==batch && int(col(3))==msg) ? 1 : 0
x() = flt() ? col(1) : 1/0
y() = flt() ? col(metric_col) : 1/0

plot infile using (x()):(y()) with linespoints lw 2 pt 7 title sprintf("elem=%d,batch=%d,msg=%d", elem, batch, msg)

