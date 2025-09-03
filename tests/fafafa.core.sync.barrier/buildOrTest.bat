@echo off
setlocal enabledelayedexpansion

REM ============================================================================
REM fafafa.core.sync.barrier Test Build Script
REM ============================================================================

set "PROJECT_NAME=fafafa.core.sync.barrier"
set "TEST_EXE=%PROJECT_NAME%.test.exe"
set "LPI_FILE=%PROJECT_NAME%.test.lpi"

echo.
echo ============================================================================
echo Building and running %PROJECT_NAME% tests
echo ============================================================================
echo.

REM Check if lazbuild is available
where lazbuild >nul 2>&1
if errorlevel 1 (
    echo Error: lazbuild command not found, please ensure Lazarus is properly installed and added to PATH
    exit /b 1
)

REM Clean previous builds
if exist "%TEST_EXE%" del "%TEST_EXE%"
if exist "lib" rmdir /s /q "lib" 2>nul
if exist "bin" rmdir /s /q "bin" 2>nul

echo Building test project...
lazbuild "%LPI_FILE%"
if errorlevel 1 (
    echo.
    echo Build failed!
    exit /b 1
)

echo.
echo Build successful! Running tests...
echo.

REM Run tests
if exist "%TEST_EXE%" (
    "%TEST_EXE%" --all --format=plain --progress
    set "TEST_RESULT=!errorlevel!"
    echo.
    if !TEST_RESULT! equ 0 (
        echo All tests passed!
    ) else (
        echo Tests failed with exit code: !TEST_RESULT!
    )
    exit /b !TEST_RESULT!
) else (
    echo Error: Test executable %TEST_EXE% not found
    exit /b 1
)
