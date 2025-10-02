@echo off
setlocal

REM Ensure running from the script directory
pushd %~dp0

echo ========================================
echo fafafa.core.time.tick Examples Build Script
echo ========================================

if not exist bin mkdir bin
if not exist lib mkdir lib

where lazbuild >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: lazbuild command not found
    exit /b 1
)

echo Building example_basic_usage...
lazbuild --build-mode=Release example_basic_usage.lpi
if %errorlevel% neq 0 (
    echo Failed to build example_basic_usage
    exit /b 1
)

echo.
echo All examples built successfully!
echo Built outputs:
for /f "delims=" %%F in ('dir /b /s bin\*\example_basic_usage.exe 2^>nul') do echo   %%F
for /f "delims=" %%F in ('dir /b /s bin\*\example_basic_usage 2^>nul') do echo   %%F

