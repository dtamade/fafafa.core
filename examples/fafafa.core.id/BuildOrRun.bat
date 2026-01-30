@echo off
setlocal ENABLEDELAYEDEXPANSION
cd /d %~dp0
call ..\..\tools\lazbuild.bat example_id.lpi || exit /b 1
.\bin\example_id.exe
call ..\..\tools\lazbuild.bat example_snowflake_config.lpr || exit /b 1
.\bin\example_snowflake_config.exe --worker-id=2 --sf-epoch-ms=1288834974657
call ..\..\tools\lazbuild.bat example_bench_throughput.lpr || exit /b 1
.\bin\example_bench_throughput.exe


