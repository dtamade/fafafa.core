@echo off
setlocal enabledelayedexpansion

echo ========================================
echo fafafa.core.sync.sem Test Runner
echo ========================================

:: Set paths
set LAZBUILD=D:\devtools\lazarus\trunk\lazbuild.exe
set PROJECT_FILE=fafafa.core.sync.sem.test.lpi
set EXECUTABLE=bin\fafafa.core.sync.sem.test.exe

:: Check if lazbuild exists
if not exist "%LAZBUILD%" (
    echo Error: lazbuild not found at %LAZBUILD%
    echo Please check Lazarus installation path
    goto :error
)

:: Create output directories
if not exist bin mkdir bin
if not exist lib mkdir lib

:: Clean previous build
echo Cleaning previous build...
if exist bin\*.exe del /q bin\*.exe
if exist lib\x86_64-win64\*.compiled del /q lib\x86_64-win64\*.compiled

:: Build the test project
echo Building test project: %PROJECT_FILE%
"%LAZBUILD%" --verbose --build-mode=Debug %PROJECT_FILE%
set BUILD_RESULT=%errorlevel%

if %BUILD_RESULT% neq 0 (
    echo Build failed with error code: %BUILD_RESULT%
    goto :error
)

:: Check if executable was created
if not exist %EXECUTABLE% (
    echo Error: Executable not found: %EXECUTABLE%
    echo Build may have failed silently
    goto :error
)

echo Build successful!
echo Executable size: 
dir %EXECUTABLE% | find ".exe"

:: Run the tests
echo.
echo Running tests...
echo ========================================
%EXECUTABLE%
set TEST_RESULT=%errorlevel%

echo ========================================
if %TEST_RESULT% equ 0 (
    echo Tests completed successfully!
) else (
    echo Tests failed with exit code: %TEST_RESULT%
)

goto :end

:error
echo.
echo Build or test execution failed!
set errorlevel=1

:end
echo.
echo Press any key to exit...
pause >nul
