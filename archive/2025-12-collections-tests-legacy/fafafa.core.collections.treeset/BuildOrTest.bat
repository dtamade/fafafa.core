@echo off
setlocal

echo ========================================
echo fafafa.core.collections.treeset Test Build Script
echo ========================================
echo.

set "SCRIPT_DIR=%~dp0"
set "PROJECT_ROOT=%SCRIPT_DIR%..\..\"
set "TEST_DIR=%SCRIPT_DIR%"
set "BIN_DIR=%PROJECT_ROOT%bin"
set "PROJECT_FILE=%TEST_DIR%tests_treeset.lpi"
set "EXECUTABLE=%BIN_DIR%\tests_treeset.exe"

if "%~1"=="test" goto run_test
if "%~1"=="build" goto build_only
if "%~1"=="clean" goto clean_only
if "%~1"=="help" goto show_help
if "%~1"=="-h" goto show_help
if "%~1"=="--help" goto show_help
if "%~1"=="" goto build_and_test
goto unknown_command

:build_project
    if not exist "%BIN_DIR%" mkdir "%BIN_DIR%"
    
    echo     Project file: %PROJECT_FILE%
    echo     Output directory: %BIN_DIR%
    
    lazbuild --build-mode=Debug "%PROJECT_FILE%"
    if errorlevel 1 (
        echo Build failed!
        exit /b 1
    )

    echo Build successful
    if exist "%EXECUTABLE%" (
        echo     Executable: %EXECUTABLE%
        exit /b 0
    ) else (
        echo Warning: Build successful but executable not found
        exit /b 1
    )

:run_test
    if not exist "%EXECUTABLE%" (
        echo Executable not found, please build first
        echo     File path: %EXECUTABLE%
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

:build_only
    echo Building test project only...
    call :build_project
    exit /b %errorlevel%

:clean_only
    echo Cleaning build files...
    if exist "%TEST_DIR%lib" (
        rd /s /q "%TEST_DIR%lib"
        echo     Deleted: %TEST_DIR%lib
    )
    if exist "%EXECUTABLE%" (
        del /q "%EXECUTABLE%"
        echo     Deleted: %EXECUTABLE%
    )
    echo Clean completed
    exit /b 0

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

:build_and_test
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

:unknown_command
    echo Unknown command: %~1
    call :show_help
    exit /b 1
