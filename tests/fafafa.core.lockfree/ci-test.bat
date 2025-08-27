@echo off
:: Simple CI/CD test script for fafafa.core.lockfree
:: Usage: ci-test-simple.bat [benchmark]

setlocal

set "SCRIPT_DIR=%~dp0"
set "ROOT_DIR=%SCRIPT_DIR%..\.."
set "SRC_DIR=%ROOT_DIR%\src"
set "BIN_DIR=%ROOT_DIR%\bin"
set "TOOLS_DIR=%ROOT_DIR%\tools"
set "LAZBUILD=%TOOLS_DIR%\lazbuild.bat"

echo fafafa.core.lockfree CI/CD Test
echo ================================
echo.

:: Check lazbuild tool
if not exist "%LAZBUILD%" (
    echo ERROR: lazbuild tool not found at %LAZBUILD%
    exit /b 1
)

:: Clean environment
echo [1/5] Cleaning build environment...
if exist "%BIN_DIR%\tests_lockfree.exe" del "%BIN_DIR%\tests_lockfree.exe"
if exist "%BIN_DIR%\benchmark_lockfree.exe" del "%BIN_DIR%\benchmark_lockfree.exe"
if exist "%BIN_DIR%\aba_test.exe" del "%BIN_DIR%\aba_test.exe"

:: Compile basic tests using lazbuild
echo [2/5] Compiling basic functionality tests...
call "%LAZBUILD%" --build-mode=Release "%SCRIPT_DIR%tests_lockfree.lpi" >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Basic test compilation failed
    exit /b 1
)

:: Compile ABA test using lazbuild
echo [3/5] Compiling ABA verification test...
call "%LAZBUILD%" --build-mode=Release "%ROOT_DIR%\play\fafafa.core.lockfree\aba_test.lpi" >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: ABA test compilation failed
    exit /b 1
)

:: Run basic tests
echo [4/5] Running functionality tests...
echo y | "%BIN_DIR%\tests_lockfree.exe" >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Functionality tests failed
    exit /b 1
)

:: Run ABA test
echo [5/5] Running ABA verification test...
echo y | "%BIN_DIR%\aba_test.exe" >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: ABA verification test failed
    exit /b 1
)

:: Optional benchmark test
if "%1"=="benchmark" (
    echo [BONUS] Compiling and running benchmark test...
    call "%LAZBUILD%" --build-mode=Release "%SCRIPT_DIR%benchmark_lockfree.lpi" >nul 2>&1
    if %ERRORLEVEL% NEQ 0 (
        echo WARNING: Benchmark compilation failed
    ) else (
        echo y | "%BIN_DIR%\benchmark_lockfree.exe" >nul 2>&1
        if %ERRORLEVEL% NEQ 0 (
            echo WARNING: Benchmark test failed
        ) else (
            echo SUCCESS: Benchmark test completed
        )
    )
)

echo.
echo SUCCESS: All CI/CD tests passed!
echo.
echo Test Summary:
echo - Basic functionality tests: PASSED
echo - ABA verification test: PASSED
if "%1"=="benchmark" (
    echo - Performance benchmark: COMPLETED
)
echo.

exit /b 0
