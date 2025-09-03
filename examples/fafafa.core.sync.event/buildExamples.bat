@echo off
setlocal

REM Ensure running from the script directory
pushd %~dp0

echo ========================================
echo fafafa.core.sync.event Examples Build Script
echo ========================================

:: Create output directories
if not exist bin mkdir bin
if not exist lib mkdir lib

:: Check if lazbuild is available
where lazbuild >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: lazbuild command not found
    echo Please ensure Lazarus is properly installed and added to PATH
    exit /b 1
)

echo Building examples...

:: Build basic usage example
echo Building example_basic_usage...
lazbuild --build-mode=Release example_basic_usage.lpi
if %errorlevel% neq 0 (
    echo Failed to build example_basic_usage
    exit /b 1
)

:: Build producer-consumer example
echo Building example_producer_consumer...
lazbuild --build-mode=Release example_producer_consumer.lpi
if %errorlevel% neq 0 (
    echo Failed to build example_producer_consumer
    exit /b 1
)

:: Build thread coordination example
echo Building example_thread_coordination...
lazbuild --build-mode=Release example_thread_coordination.lpi
if %errorlevel% neq 0 (
    echo Failed to build example_thread_coordination
    exit /b 1
)

:: Build auto vs manual example
echo Building example_auto_vs_manual...
lazbuild --build-mode=Release example_auto_vs_manual.lpi
if %errorlevel% neq 0 (
    echo Failed to build example_auto_vs_manual
    exit /b 1
)

:: Build timeout handling example
echo Building example_timeout_handling...
lazbuild --build-mode=Release example_timeout_handling.lpi
if %errorlevel% neq 0 (
    echo Failed to build example_timeout_handling
    exit /b 1
)

echo.
echo All examples built successfully!
echo.
echo To run examples:
echo   bin\example_basic_usage.exe
echo   bin\example_producer_consumer.exe
echo   bin\example_thread_coordination.exe
echo   bin\example_auto_vs_manual.exe
echo   bin\example_timeout_handling.exe
echo.
echo Done!
