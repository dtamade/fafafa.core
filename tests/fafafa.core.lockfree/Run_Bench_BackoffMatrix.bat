@echo off
setlocal ENABLEDELAYEDEXPANSION

REM Run lockfree microbench twice (Default vs Aggressive Backoff) and write CSV with timestamped filenames
set SCRIPT_DIR=%~dp0
pushd "%SCRIPT_DIR%"

REM --- Config (you can override via env before calling this script) ---
if "%FAFAFA_BENCH_N%"=="" set FAFAFA_BENCH_N=200000
if "%FAFAFA_BENCH_REPEAT%"=="" set FAFAFA_BENCH_REPEAT=5
if "%FAFAFA_BENCH_WARMUP%"=="" set FAFAFA_BENCH_WARMUP=1

REM Build timestamp like 20250818_153045 (locale independent)
for /f %%i in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss"') do set TS=%%i
set BASE=bench_lockfree_%TS%

REM Populate run id and commit if not provided
if "%FAFAFA_BENCH_RUNID%"=="" set FAFAFA_BENCH_RUNID=%TS%
for /f %%i in ('git rev-parse --short=12 HEAD 2^>NUL') do set GIT_COMMIT=%%i
if "%GIT_COMMIT%"=="" set GIT_COMMIT=unknown

echo RunId=%FAFAFA_BENCH_RUNID%  Commit=%GIT_COMMIT%

set FAFAFA_BENCH=1

REM --- Default Backoff ---
set FAFAFA_BENCH_BACKOFF=
set FAFAFA_BENCH_OUT=%BASE%_default.csv
call BuildOrRun_TestOnly.bat
if errorlevel 1 goto :eof

REM --- Aggressive Backoff ---
set FAFAFA_BENCH_BACKOFF=Aggressive
set FAFAFA_BENCH_OUT=%BASE%_aggressive.csv
call BuildOrRun_TestOnly.bat
if errorlevel 1 goto :eof

echo.
echo Generated CSV:
echo   %BASE%_default.csv
echo   %BASE%_aggressive.csv

REM --- Optional: auto-merge compare (configurable via env) ---
set "AUTO_COMPARE=%AUTO_COMPARE%"
if "%AUTO_COMPARE%"=="" set AUTO_COMPARE=1
if "%AUTO_COMPARE%"=="0" goto :skip_compare

set "COMPARE_MODEL=%COMPARE_MODEL%"
if "%COMPARE_MODEL%"=="" set COMPARE_MODEL=MPMC
set "COMPARE_WAIT=%COMPARE_WAIT%"
if "%COMPARE_WAIT%"=="" set COMPARE_WAIT=bpSleep
set "COMPARE_NS_RATIO_MIN=%COMPARE_NS_RATIO_MIN%"
if "%COMPARE_NS_RATIO_MIN%"=="" set COMPARE_NS_RATIO_MIN=1.05
set "COMPARE_SORT=%COMPARE_SORT%"
if "%COMPARE_SORT%"=="" set COMPARE_SORT=ns_ratio

echo Auto-compare: model=%COMPARE_MODEL% wait=%COMPARE_WAIT% ns_ratio_min=%COMPARE_NS_RATIO_MIN% sort=%COMPARE_SORT%

set MERGE_PS=%SCRIPT_DIR%..\tools\merge_bench_backoff_csv.ps1
if exist "%MERGE_PS%" (
  set "COMPARE_OUT_PREFIX=%COMPARE_OUT_PREFIX%"
  set "COMPARE_OUT=%BASE%_compare_%COMPARE_MODEL%_%COMPARE_WAIT%_top.csv"
  if not "%COMPARE_OUT_PREFIX%"=="" set "COMPARE_OUT=%COMPARE_OUT_PREFIX%%COMPARE_OUT%"
  powershell -NoProfile -ExecutionPolicy Bypass -File "%MERGE_PS%" -DefaultCsv %BASE%_default.csv -AggressiveCsv %BASE%_aggressive.csv -Out "%COMPARE_OUT%" -Model %COMPARE_MODEL% -WaitPolicy %COMPARE_WAIT% -NsPerOpRatioMin %COMPARE_NS_RATIO_MIN% -Sort %COMPARE_SORT%
  if %ERRORLEVEL% EQU 0 (
    echo Generated compare: %COMPARE_OUT%
  ) else (
    echo Merge compare failed (ignored)
  )
) else (
  echo Merge script not found: %MERGE_PS%
)
:skip_compare

popd
endlocal

