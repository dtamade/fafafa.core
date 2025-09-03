@echo off
setlocal enabledelayedexpansion

echo ========================================
echo fafafa.core.time.tick Unit Test Build Script
echo ========================================
echo.

set PROJECT_NAME=fafafa.core.time.tick.test
set PROJECT_FILE=%PROJECT_NAME%.lpi
set BIN_DIR=bin
set LIB_DIR=lib

:: Check if lazbuild is available
where lazbuild >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo Error: lazbuild command not found
    echo Please ensure Lazarus is installed and lazbuild is in PATH
    pause
    exit /b 1
)

:: Create output directories
if not exist "%BIN_DIR%" mkdir "%BIN_DIR%"
if not exist "%LIB_DIR%" mkdir "%LIB_DIR%"

echo Building test project...
echo Project file: %PROJECT_FILE%
echo.

:: Build project
lazbuild --build-mode=Debug --verbose %PROJECT_FILE%
set BUILD_RESULT=%ERRORLEVEL%

echo.
if %BUILD_RESULT% EQU 0 (
    echo Build successful!
    echo.

    :: Check if executable exists
    if exist "%BIN_DIR%\%PROJECT_NAME%.exe" (
        echo Running tests...
        echo ========================================
        echo.

        :: Run tests
        "%BIN_DIR%\%PROJECT_NAME%.exe"
        set TEST_RESULT=!ERRORLEVEL!

        echo.
        echo ========================================
        if !TEST_RESULT! EQU 0 (
            echo All tests passed!
        ) else (
            echo Tests failed with exit code: !TEST_RESULT!
        )
    ) else (
        echo Executable not found: %BIN_DIR%\%PROJECT_NAME%.exe
        set TEST_RESULT=1
    )
) else (
    echo Build failed with exit code: %BUILD_RESULT%
    set TEST_RESULT=%BUILD_RESULT%
)

echo.
echo Press any key to exit...
pause >nul
exit /b %TEST_RESULT%
