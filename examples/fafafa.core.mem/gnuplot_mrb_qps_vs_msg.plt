# Gnuplot template: plot QPS vs msg_count for mappedRingBuffer benchmark
# Usage example:
#   gnuplot -e "infile='bench_out/mrb_bidir_bench_e4.csv';outfile='bench_out/plot_qps_vs_msg_e4_cap65536_batch64.png';elem=4;capacity=65536;batch=64;metric_col=10" gnuplot_mrb_qps_vs_msg.plt
# metric_col: 9=qps_avg, 10=qps_median, 11=qps_std

if (!exists("infile")) infile='bench_out/mrb_bidir_bench_e4.csv'
if (!exists("outfile")) outfile='bench_out/plot_qps_vs_msg.png'
if (!exists("elem")) elem=4
if (!exists("capacity")) capacity=65536
if (!exists("batch")) batch=64
if (!exists("metric_col")) metric_col=10

set datafile separator ","
set key left top
set grid
set term pngcairo size 1200,800 font ",12"
set output outfile
set title sprintf("QPS vs Message Count (elem=%d, cap=%d, batch=%d)", elem, capacity, batch)
set xlabel "msg_count"
set ylabel (metric_col==9 ? "QPS (avg)" : (metric_col==10 ? "QPS (median)" : "QPS (std approx)"))
set format x "%.0f"

col(n) = column(n)
flt() = (int(col(2))==elem && int(col(1))==capacity && int(col(4))==batch) ? 1 : 0
x() = flt() ? col(3) : 1/0
y() = flt() ? col(metric_col) : 1/0

plot infile using (x()):(y()) with linespoints lw 2 pt 7 title sprintf("elem=%d,cap=%d,batch=%d", elem, capacity, batch)

