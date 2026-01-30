@echo off
setlocal
set EX_DIR=%~dp0
pushd "%EX_DIR%"

rem Build queue bench
lazbuild ..\..\benchmarks\fafafa.core.thread\queue_bench.lpr || goto :eof

rem Run matrix via PowerShell if available
where powershell >nul 2>nul && (
  powershell -ExecutionPolicy Bypass -File ..\..\benchmarks\fafafa.core.thread\run_matrix.ps1
) || (
  echo PowerShell not found. Please run the bash script manually: benchmarks/fafafa.core.thread/run_matrix.sh
)

popd
endlocal

