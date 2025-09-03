@echo off
echo MMX Unit Test Build Script
echo ===========================

set PROJECT_NAME=fafafa.core.simd.intrinsics.mmx.test
set BIN_DIR=bin
set LIB_DIR=lib

if not exist "%BIN_DIR%" mkdir "%BIN_DIR%"
if not exist "%LIB_DIR%" mkdir "%LIB_DIR%"

echo Building %PROJECT_NAME%...
lazbuild --build-mode=Debug "%PROJECT_NAME%.lpi"

if %ERRORLEVEL% EQU 0 (
    echo.
    echo Build successful!
    echo.
    echo Running tests...
    echo ================
    "%BIN_DIR%\%PROJECT_NAME%.exe"

    if %ERRORLEVEL% EQU 0 (
        echo.
        echo All tests passed!
    ) else (
        echo.
        echo Tests failed!
        exit /b 1
    )
) else (
    echo.
    echo Build failed!
    pause
    exit /b 1
)

echo.
echo Test completed.
pause
