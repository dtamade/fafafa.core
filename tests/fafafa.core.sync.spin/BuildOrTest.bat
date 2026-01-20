@echo off
setlocal enabledelayedexpansion

echo ========================================
echo fafafa.core.sync.spin Unit Test Build Script
echo ========================================

set PROJECT_NAME=fafafa.core.sync.spin.test
set PROJECT_FILE=%PROJECT_NAME%.lpi
set EXECUTABLE=bin\%PROJECT_NAME%.exe

:: Check if lazbuild is available
where lazbuild >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: lazbuild command not found, please ensure Lazarus is properly installed and added to PATH
    exit /b 1
)

:: Create output directories
if not exist bin mkdir bin
if not exist lib mkdir lib

:: Build project
echo Building project...
lazbuild --build-mode=Debug %PROJECT_FILE%
if %errorlevel% neq 0 (
    echo Build failed!
    exit /b 1
)

echo Build successful!

:: Check if tests should be run
if "%1"=="test" (
    echo.
    echo Running tests...
    if exist %EXECUTABLE% (
        %EXECUTABLE%
        echo.
        echo Tests completed, exit code: !errorlevel!
    ) else (
        echo Error: Executable not found %EXECUTABLE%
        exit /b 1
    )
) else (
    echo.
    echo To run tests, use: buildOrTest.bat test
)

echo.
echo Done!
