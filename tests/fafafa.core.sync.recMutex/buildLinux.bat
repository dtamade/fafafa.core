@echo off
REM ===================================================================
REM fafafa.core.sync.recMutex Linux Cross-Compilation Script
REM ===================================================================
REM
REM Function: Cross-compile unit tests from Windows to Linux x86_64
REM
REM Usage:
REM   buildLinux.bat          - Build Debug version
REM   buildLinux.bat release  - Build Release version
REM   buildLinux.bat clean    - Clean build artifacts
REM
REM Output:
REM   bin/fafafa.core.sync.recMutex.test.linux - Linux executable
REM   lib/x86_64-linux/ - Linux build intermediate files
REM
REM ===================================================================

setlocal enabledelayedexpansion

REM Check parameters
set BUILD_MODE=Linux-x86_64
if "%1"=="release" (
    set BUILD_MODE=Release
    set TARGET_SUFFIX=.linux.release
) else if "%1"=="clean" (
    goto :clean
) else (
    set TARGET_SUFFIX=.linux
)

echo ====================================================================
echo fafafa.core.sync.recMutex Linux Cross-Compilation
echo ====================================================================
echo.
echo Build Mode: %BUILD_MODE%
echo Target Platform: Linux x86_64
echo Output File: bin/fafafa.core.sync.recMutex.test%TARGET_SUFFIX%
echo.

REM Check if lazbuild is available
where lazbuild >nul 2>&1
if errorlevel 1 (
    echo ERROR: lazbuild command not found
    echo Please ensure Lazarus is properly installed and added to PATH
    exit /b 1
)

REM Create output directories
if not exist "bin" mkdir bin
if not exist "lib" mkdir lib
if not exist "lib\x86_64-linux" mkdir lib\x86_64-linux

echo Starting cross-compilation...
echo.

REM Execute cross-compilation
lazbuild --build-mode=%BUILD_MODE% fafafa.core.sync.recMutex.test.lpi

if errorlevel 1 (
    echo.
    echo ====================================================================
    echo COMPILATION FAILED!
    echo ====================================================================
    exit /b 1
) else (
    echo.
    echo ====================================================================
    echo COMPILATION SUCCESSFUL!
    echo ====================================================================
    echo.

    REM Display generated file information
    if exist "bin\fafafa.core.sync.recMutex.test.linux" (
        echo Generated Linux executable:
        dir "bin\fafafa.core.sync.recMutex.test.linux" | findstr /v "Directory"
        echo.

        echo Linux executable generated: bin/fafafa.core.sync.recMutex.test.linux
        echo.
        echo Instructions for running on Linux:
        echo   1. Transfer the file to a Linux system
        echo   2. Make it executable: chmod +x fafafa.core.sync.recMutex.test.linux
        echo   3. Run tests: ./fafafa.core.sync.recMutex.test.linux --all --format=plain
        echo.
        echo File size:
        for %%F in ("bin\fafafa.core.sync.recMutex.test.linux") do echo   %%~zF bytes
    )
)

goto :end

:clean
echo ====================================================================
echo Cleaning Linux Cross-Compilation Artifacts
echo ====================================================================
echo.

REM Clean Linux-related build artifacts
if exist "bin\fafafa.core.sync.recMutex.test.linux" (
    del "bin\fafafa.core.sync.recMutex.test.linux"
    echo Deleted: bin\fafafa.core.sync.recMutex.test.linux
)

if exist "bin\fafafa.core.sync.recMutex.test.linux.release" (
    del "bin\fafafa.core.sync.recMutex.test.linux.release"
    echo Deleted: bin\fafafa.core.sync.recMutex.test.linux.release
)

if exist "lib\x86_64-linux" (
    rmdir /s /q "lib\x86_64-linux"
    echo Deleted: lib\x86_64-linux\
)

echo.
echo Cleanup completed!

:end
echo.
echo ====================================================================
endlocal
