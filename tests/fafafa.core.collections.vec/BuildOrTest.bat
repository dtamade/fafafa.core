@echo off
setlocal ENABLEDELAYEDEXPANSION

REM Standard template disabled here to avoid cross-module builds that may block.
REM Using local fallback logic below to build and run only vec tests.
REM set "MODULE_NAME=vec"
REM set "PROJECT=%~dp0tests_vec.lpi"
REM set "TEST_EXE=%~dp0..\..\bin\tests_vec.exe"
REM set "LAZBUILD_ARGS=--build-mode=Debug"
REM call "%~dp0..\..\tools\test_template.bat" %*
REM exit /b %ERRORLEVEL%
echo ========================================
echo fafafa.core.collections.vec Test Build Script
echo ========================================
echo.

set PROJECT_ROOT=%~dp0..\..
set TEST_DIR=%~dp0
set BIN_DIR=%PROJECT_ROOT%\bin
set PROJECT_FILE=%TEST_DIR%tests_vec.lpi
set EXECUTABLE=%BIN_DIR%\tests_vec.exe

if "%1"=="test" goto run_test
if "%1"=="build" goto build_only
if "%1"=="clean" goto clean_only

echo Building test project using tools\test_template.bat ...
set "MODULE_NAME=vec"
set "PROJECT=%~dp0tests_vec.lpi"
set "TEST_EXE=%~dp0..\..\bin\tests_vec.exe"
set "LAZBUILD_ARGS=--build-mode=Debug"
call "%~dp0..\..\tools\test_template.bat" build
if errorlevel 1 (
    echo Build failed!
    exit /b 1
)

echo.
echo Running tests via template...
call "%~dp0..\..\tools\test_template.bat" test
exit /b %ERRORLEVEL%

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
