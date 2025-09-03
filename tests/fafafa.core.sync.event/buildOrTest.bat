@echo off
setlocal enabledelayedexpansion

echo ========================================
echo fafafa.core.sync.event Unit Test Build Script
echo ========================================

set PROJECT_NAME=fafafa.core.sync.event.test
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
        echo Running basic test suite...
        %EXECUTABLE% --suite=TTestCase_Event_Basic
        set basic_result=!errorlevel!
        echo Basic tests completed, exit code: !basic_result!

        if !basic_result! equ 0 (
            echo.
            echo Running advanced test suite...
            %EXECUTABLE% --suite=TTestCase_Event_Advanced
            set advanced_result=!errorlevel!
            echo Advanced tests completed, exit code: !advanced_result!
        )

        echo.
        echo All tests completed
    ) else (
        echo Error: Executable not found %EXECUTABLE%
        exit /b 1
    )
) else if "%1"=="quick" (
    echo.
    echo Running quick tests...
    if exist %EXECUTABLE% (
        %EXECUTABLE% --suite=TTestCase_Event_Basic
        echo.
        echo Quick tests completed, exit code: !errorlevel!
    ) else (
        echo Error: Executable not found %EXECUTABLE%
        exit /b 1
    )
) else (
    echo.
    echo To run tests, use:
    echo   buildOrTest.bat test   - Run full tests
    echo   buildOrTest.bat quick  - Run quick tests
)

echo.
echo Done!
