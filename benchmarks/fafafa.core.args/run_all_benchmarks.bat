@echo off
setlocal enabledelayedexpansion

REM fafafa.core.args 性能基准测试运行脚本 (Windows)

cd /d "%~dp0"

REM 创建结果目录
if not exist results mkdir results
if not exist bin mkdir bin

echo ========================================
echo fafafa.core.args Performance Benchmarks
echo ========================================
echo Started at: %date% %time%
echo.

REM 编译所有基准测试
echo 🔨 Compiling benchmarks...

set BENCHMARKS=args_parsing_benchmark args_options_benchmark args_memory_benchmark args_command_benchmark args_config_merge_benchmark

for %%b in (%BENCHMARKS%) do (
    echo   Compiling %%b...
    where lazbuild >nul 2>&1
    if !errorlevel! equ 0 (
        lazbuild --build-mode=Release --quiet "%%b.lpr" -o "bin\%%b.exe"
    ) else (
        fpc -O2 -S2 -MObjFPC -Fu..\..\src -FEbin -FUlib "%%b.lpr"
    )
    if !errorlevel! neq 0 (
        echo ❌ Failed to compile %%b
        exit /b 1
    )
)

echo ✅ All benchmarks compiled successfully
echo.

REM 运行基准测试
echo 🚀 Running benchmarks...

for /f "tokens=1-3 delims=/ " %%a in ('date /t') do set DATESTR=%%c%%a%%b
for /f "tokens=1-2 delims=: " %%a in ('time /t') do set TIMESTR=%%a%%b
set TIMESTAMP=%DATESTR%_%TIMESTR%
set RESULTS_FILE=results\benchmark_results_%TIMESTAMP%.txt

REM 创建结果文件头部
(
echo fafafa.core.args Performance Benchmark Results
echo ==============================================
echo Timestamp: %date% %time%
echo System: Windows
echo.
) > "%RESULTS_FILE%"

for %%b in (%BENCHMARKS%) do (
    echo 📊 Running %%b...
    (
    echo ----------------------------------------
    echo Running %%b
    echo ----------------------------------------
    ) >> "%RESULTS_FILE%"
    
    if exist "bin\%%b.exe" (
        "bin\%%b.exe" >> "%RESULTS_FILE%" 2>&1
    ) else (
        echo ❌ %%b.exe not found, skipping...
        echo ERROR: %%b.exe not found >> "%RESULTS_FILE%"
    )
    
    echo. >> "%RESULTS_FILE%"
)

echo.
echo ✅ All benchmarks completed!
echo 📄 Results saved to: %RESULTS_FILE%

REM 生成简要摘要
echo.
echo 📈 Performance Summary:
echo ======================

if exist "%RESULTS_FILE%" (
    echo Parsing Performance:
    findstr /C:"args/sec" /C:"parses/sec" "%RESULTS_FILE%" | findstr /N ".*" | findstr "^[1-5]:"
    
    echo.
    echo Query Performance:
    findstr /C:"ops/sec" /C:"queries/sec" "%RESULTS_FILE%" | findstr /N ".*" | findstr "^[1-3]:"
    
    echo.
    echo Command Routing:
    findstr /C:"routes/sec" "%RESULTS_FILE%" | findstr /N ".*" | findstr "^[1-3]:"
)

echo.
echo 🎯 Benchmark run completed at: %date% %time%
echo 📁 Check the results\ directory for detailed output

pause
