@echo off
setlocal
set PROJ_DIR=%~dp0
pushd %PROJ_DIR%

set BIN=..\..\..\bin
set LIB=lib
if not exist %LIB% mkdir %LIB%
if not exist %BIN% mkdir %BIN%

set LPI=example_mpmc_bench.lpr

rem build
lazbuild --bm=Debug %LPI%
if errorlevel 1 goto :eof

rem run quick
set FAFAFA_BENCH_N=%FAFAFA_BENCH_N%
if "%FAFAFA_BENCH_N%"=="" set FAFAFA_BENCH_N=200000
set FAFAFA_BENCH_REPEAT=%FAFAFA_BENCH_REPEAT%
if "%FAFAFA_BENCH_REPEAT%"=="" set FAFAFA_BENCH_REPEAT=3

rem populate run_id and commit if not provided
for /f %%i in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss"') do set TS=%%i
if "%FAFAFA_BENCH_RUNID%"=="" set FAFAFA_BENCH_RUNID=%TS%
for /f %%i in ('git rev-parse --short=12 HEAD 2^>NUL') do set GIT_COMMIT=%%i
if "%GIT_COMMIT%"=="" set GIT_COMMIT=unknown

echo RunId=%FAFAFA_BENCH_RUNID%  Commit=%GIT_COMMIT%

"%BIN%\example_mpmc_bench.exe"

popd
endlocal

