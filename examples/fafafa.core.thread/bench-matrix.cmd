@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION
set "SCRIPT_DIR=%~dp0"
pushd "%SCRIPT_DIR%" >nul

rem Build artifacts (compile examples and benchmark)
call "%SCRIPT_DIR%BuildOrRun.bat" >nul
if %ERRORLEVEL% NEQ 0 (
  echo Build failed in bench-matrix.cmd
  goto :END
)

rem Detect CPU logical processors (fallback=4)
set "CPU=%NUMBER_OF_PROCESSORS%"
if "%CPU%"=="" set "CPU=4"

rem Derive core counts
set /a CORE1=1
set /a COREN=%CPU%
set /a COREN2=COREN/2
if %COREN2% LSS 1 set /a COREN2=1

rem For cached-like: max = 2 * COREN2 (at least 2)
set /a MAXCACHED=COREN2*2
if %MAXCACHED% LSS 2 set /a MAXCACHED=2

rem Totals scale with core count (5000 per core)
set /a TOT1=CORE1*5000
set /a TOTN2=COREN2*5000
set /a TOTN=COREN*5000
set /a TOTCACHED=COREN2*5000*2
rem Derive bounded queue capacities (k = 1024 * cores)
set /a QCAPN2=COREN2*1024
if %QCAPN2% LSS 128 set /a QCAPN2=128
set /a QCAPN=COREN*1024
if %QCAPN% LSS 256 set /a QCAPN=256


rem Prepare output CSV file
set "CSV=bench.csv"
if exist "%CSV%" del /f /q "%CSV%" >nul 2>&1
(
  echo title,core,max,queue,total,time_ms,hit,miss,ret,drop
) > "%CSV%"

rem Ensure benchmark exe exists
set "BENCH_EXE=%SCRIPT_DIR%bin\benchmark_taskitem_pool.exe"
if not exist "%BENCH_EXE%" (
  echo Benchmark executable not found: %BENCH_EXE%
  goto :END
)

rem Set CSV mode for the benchmark program
set "FAFAFA_BENCH_CSV=1"

rem Run matrix: only queue=-1 (unbounded) to avoid rejection with rpAbort
call :RUN "fixed-1"        %CORE1%  %CORE1%  -1  %TOT1%      1  3  "%CSV%"
call :RUN "fixed-half"     %COREN2% %COREN2% -1  %TOTN2%     1  3  "%CSV%"
call :RUN "fixed-half-qK" %COREN2% %COREN2% %QCAPN2% %TOTN2% 1 3 "%CSV%"
call :RUN "fixed-all-qK"  %COREN%  %COREN%  %QCAPN%  %TOTN%  1 3 "%CSV%"

call :RUN "fixed-all"      %COREN%  %COREN%  -1  %TOTN%      1  3  "%CSV%"
call :RUN "cached-half-2x" %COREN2% %MAXCACHED% -1 %TOTCACHED% 1  3  "%CSV%"
call :RUN "fixed-half-q0-caller" %COREN2% %COREN2% 0 %TOTN2% 1 3 "%CSV%" caller
call :RUN "fixed-all-q0-caller"  %COREN%  %COREN%  0 %TOTN%  1 3 "%CSV%" caller
call :RUN "fixed-half-q0-discardOldest" %COREN2% %COREN2% 0 %TOTN2% 1 3 "%CSV%" discardOldest
call :RUN "fixed-all-q0-discardOldest"  %COREN%  %COREN%  0 %TOTN%  1 3 "%CSV%" discardOldest




rem Post-process to summary (derived metrics)
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%bench-summary.ps1" -InputCsv "%CSV%" -OutputCsv "bench_summary.csv" >nul 2>&1
if %ERRORLEVEL% EQU 0 (
  echo Done. Results written to %CSV% and bench_summary.csv
) else (
  echo Done. Results written to %CSV% (summary failed)
)
goto :END

:RUN
rem Args: title core max queue total prewarm repeat csv_path [policy]
set "TITLE=%~1"
set "CORE=%~2"
set "MAX=%~3"
set "QUEUE=%~4"
set "TOTAL=%~5"
set "PREWARM=%~6"
set "REPEAT=%~7"
set "OUTCSV=%~8"
set "POLICY=%~9"

echo [RUN] title=%TITLE% core=%CORE% max=%MAX% queue=%QUEUE% total=%TOTAL% (prewarm %PREWARM%, repeat %REPEAT%) policy=%POLICY%

if not "%POLICY%"=="" set "FAFAFA_BENCH_POLICY=%POLICY%"

for /L %%P in (1,1,%PREWARM%) do (
  "%BENCH_EXE%" %CORE% %MAX% %QUEUE% %TOTAL% >nul 2>&1
)
for /L %%R in (1,1,%REPEAT%) do (
  "%BENCH_EXE%" %CORE% %MAX% %QUEUE% %TOTAL% >> "%OUTCSV%"
)

if not "%POLICY%"=="" set "FAFAFA_BENCH_POLICY="

exit /b 0

:END
popd >nul
endlocal

