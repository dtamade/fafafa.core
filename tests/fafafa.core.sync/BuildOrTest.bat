@echo off
setlocal
set "SCRIPT_DIR=%~dp0"

echo ========================================
echo fafafa.core.sync Test Build Script
echo ========================================

set PROJECT_NAME=tests_sync
set "PROJECT_FILE=%SCRIPT_DIR%%PROJECT_NAME%.lpi"
set "OUTPUT_DIR=%SCRIPT_DIR%bin"
set "OUTPUT_FILE=%OUTPUT_DIR%\%PROJECT_NAME%.exe"

:: Check if lazbuild is available
where lazbuild >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: lazbuild command not found
    echo Please ensure Lazarus is properly installed and added to PATH
    exit /b 1
)

:: Create output directory
if not exist "%OUTPUT_DIR%" (
    mkdir "%OUTPUT_DIR%"
)

:: Clean previous build
if exist "%OUTPUT_FILE%" (
    del "%OUTPUT_FILE%"
)

echo.
echo Building test project...
echo Project file: %PROJECT_FILE%
echo Output file: %OUTPUT_FILE%
echo.

:: Build Debug version
lazbuild --build-mode=Debug "%PROJECT_FILE%"
if %errorlevel% neq 0 (
    echo.
    echo Build failed!
    exit /b 1
)

echo.
echo Build successful!

:: Check if we should run tests
if "%1"=="test" goto run_tests
if "%1"=="run" goto run_tests

echo.
echo Usage:
echo   "%~nx0"    - Build only
echo   "%~nx0" test  - Build and run tests
echo   "%~nx0" run   - Build and run tests
echo.
exit /b 0

:run_tests
echo.
echo ========================================
echo Running tests...
echo ========================================
echo.

if not exist "%OUTPUT_FILE%" (
    echo Error: Executable file not found %OUTPUT_FILE%
    exit /b 1
)

:: Run tests with flags and capture logs
:: 1) human-friendly log with progress
"%OUTPUT_FILE%" --all --progress -u > "%OUTPUT_DIR%\last-run.txt" 2>&1
set TEST_RESULT=%errorlevel%
:: 2) machine-readable XML report (always regenerate)
"%OUTPUT_FILE%" --all --format=xml > "%OUTPUT_DIR%\results.xml" 2>&1

:: Show quick console log tail
for /f "usebackq delims=" %%L in ("%OUTPUT_DIR%\last-run.txt") do set "LASTLINE=%%L"
if defined LASTLINE echo Last line: !LASTLINE!

echo.
echo ========================================
if %TEST_RESULT% equ 0 (
    echo All tests passed!
) else (
    echo Tests failed, exit code: %TEST_RESULT%
    echo See %OUTPUT_DIR%\last-run.txt and results.xml for details.
)
echo ========================================

:: Skip pause when running tests or in automation
if /i "%1"=="test" goto no_pause
if /i "%1"=="run" goto no_pause
pause
:no_pause
exit /b %TEST_RESULT%
