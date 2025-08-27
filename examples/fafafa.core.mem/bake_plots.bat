@echo off
setlocal
set BASE=%~dp0
set CSV_DIR=%BASE%bench_out
if not exist "%CSV_DIR%" (
  echo bench_out not found
  exit /b 1
)
for %%E in (4 8 16) do (
  set "INFILE=%CSV_DIR%\mrb_bidir_bench_e%%E.csv"
  if exist "!INFILE!" (
    for %%C in (4096 65536 262144) do (
      for %%M in (100000 500000) do (
        call gnuplot -e "infile='!INFILE!';outfile='%CSV_DIR%/plot_qps_vs_batch_e%%E_cap%%C_msg%%M.png';elem=%%E;capacity=%%C;msg=%%M;metric_col=10" "%BASE%gnuplot_mrb_qps_vs_batch.plt"
        call gnuplot -e "infile='!INFILE!';outfile='%CSV_DIR%/plot_qps_vs_capacity_e%%E_batch64_msg%%M.png';elem=%%E;batch=64;msg=%%M;metric_col=10" "%BASE%gnuplot_mrb_qps_vs_capacity.plt"
        call gnuplot -e "infile='!INFILE!';outfile='%CSV_DIR%/plot_qps_vs_msg_e%%E_cap%%C_batch64.png';elem=%%E;capacity=%%C;batch=64;metric_col=10" "%BASE%gnuplot_mrb_qps_vs_msg.plt"
      )
    )
  )
)
endlocal

