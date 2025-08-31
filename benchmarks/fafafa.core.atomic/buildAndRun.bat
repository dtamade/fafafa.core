@echo off
REM fafafa.core.atomic benchmark build and run script (Windows)

setlocal enabledelayedexpansion

echo === fafafa.core.atomic Benchmark Build Script ===
echo.

REM Set paths
set "BENCHMARK_DIR=%~dp0"
set "PROJECT_ROOT=%BENCHMARK_DIR%..\.."
set "SRC_DIR=%PROJECT_ROOT%\src"
set "UTILS_DIR=%BENCHMARK_DIR%utils"
set "RESULTS_DIR=%BENCHMARK_DIR%results"

REM Create results directory
if not exist "%RESULTS_DIR%" mkdir "%RESULTS_DIR%"

REM Set compiler parameters
set "FPC_PARAMS=-Mobjfpc -Sh -O2 -g -gl -Ci -Co -Cr -Ct"
set "FPC_UNITS=-Fu%SRC_DIR% -Fu%UTILS_DIR%"
set "FPC_OUTPUT=-FE%BENCHMARK_DIR% -FU%BENCHMARK_DIR%\lib"

REM Create lib directory
if not exist "%BENCHMARK_DIR%\lib" mkdir "%BENCHMARK_DIR%\lib"

echo Compiling basic atomic operations benchmark...
fpc %FPC_PARAMS% %FPC_UNITS% %FPC_OUTPUT% "%BENCHMARK_DIR%bench_atomic_basic.lpr"
if errorlevel 1 (
    echo Compilation failed!
    pause
    exit /b 1
)

echo Compilation successful!
echo.

echo Running basic atomic operations benchmark...
echo.
"%BENCHMARK_DIR%bench_atomic_basic.exe"

echo.
echo Benchmark completed!
echo Result files located at: %RESULTS_DIR%
echo.

REM Display result files
if exist "%RESULTS_DIR%\basic_atomic_results.json" (
    echo JSON result file:
    type "%RESULTS_DIR%\basic_atomic_results.json"
    echo.
)

if exist "%RESULTS_DIR%\basic_atomic_results.csv" (
    echo CSV result file:
    type "%RESULTS_DIR%\basic_atomic_results.csv"
    echo.
)

pause
