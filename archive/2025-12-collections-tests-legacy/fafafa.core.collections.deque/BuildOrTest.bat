@echo off
setlocal ENABLEDELAYEDEXPANSION

REM Use standard template with overrides
set "MODULE_NAME=deque"
set "PROJECT=%~dp0tests_deque.lpi"
set "TEST_EXE=%~dp0bin\tests_deque.exe"
call "%~dp0..\..\tools\test_template.bat" %*
exit /b %ERRORLEVEL%
echo ========================================
echo fafafa.core.collections.deque Test Build Script
echo ========================================
echo.

set PROJECT_ROOT=%~dp0..\..
set TEST_DIR=%~dp0
set BIN_DIR=%PROJECT_ROOT%\bin
set PROJECT_FILE=%TEST_DIR%tests_deque.lpi
set EXECUTABLE=%BIN_DIR%\tests_deque.exe

if "%1"=="test" goto run_test
if "%1"=="build" goto build_only
if "%1"=="clean" goto clean_only

echo Building test project...
call :build_project
if errorlevel 1 (
    echo Build failed!
    exit /b 1
)

echo.
echo Running tests...
call :run_test
exit /b %errorlevel%

:build_only
echo Building test project only...
call :build_project
exit /b %errorlevel%

:run_test
if not exist "%EXECUTABLE%" (
    echo Executable not found, please build first
    echo    File path: %EXECUTABLE%
    exit /b 1
)

echo Running tests: %EXECUTABLE%
cd /d "%PROJECT_ROOT%"
"%EXECUTABLE%" --all --format=plain --progress
if errorlevel 1 (
    echo.
    echo Tests failed!
    exit /b 1
) else (
    echo.
    echo All tests passed!
    exit /b 0
)

:clean_only
echo Cleaning build files...
if exist "%TEST_DIR%lib" (
    rmdir /s /q "%TEST_DIR%lib"
    echo    Deleted: %TEST_DIR%lib
)
if exist "%EXECUTABLE%" (
    del "%EXECUTABLE%"
    echo    Deleted: %EXECUTABLE%
)
echo Clean completed
exit /b 0

:build_project
if not exist "%BIN_DIR%" mkdir "%BIN_DIR%"

echo    Project file: %PROJECT_FILE%
echo    Output directory: %BIN_DIR%

..\..\tools\lazbuild.bat --build-mode=Debug "%PROJECT_FILE%"
if errorlevel 1 (
    echo Build failed!
    exit /b 1
)

echo Build successful
if exist "%EXECUTABLE%" (
    echo    Executable: %EXECUTABLE%
    exit /b 0
) else (
    echo Warning: Build successful but executable not found
    exit /b 1
)

:show_help
echo.
echo Usage: %~nx0 [command]
echo.
echo Commands:
echo   build    Build project only
echo   test     Run tests only (requires build first)
echo   clean    Clean build files
echo   (no args) Build and run tests
echo.
echo Examples:
echo   %~nx0           # Build and run tests
echo   %~nx0 build     # Build only
echo   %~nx0 test      # Run tests only
echo   %~nx0 clean     # Clean files
echo.
exit /b 0
