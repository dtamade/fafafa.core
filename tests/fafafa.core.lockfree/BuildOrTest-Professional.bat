@echo off
:: Professional Build and Test Script for fafafa.core.lockfree
:: Uses unified tools/lazbuild.bat for consistent builds
:: Usage: BuildOrTest-Professional.bat [clean|build|test|benchmark|all]

setlocal enabledelayedexpansion

set "SCRIPT_DIR=%~dp0"
set "ROOT_DIR=%SCRIPT_DIR%..\.."
set "BIN_DIR=%ROOT_DIR%\bin"
set "TOOLS_DIR=%ROOT_DIR%\tools"
set "LAZBUILD=%TOOLS_DIR%\lazbuild.bat"

:: Parse command line arguments
set "ACTION=%1"
if "%ACTION%"=="" set "ACTION=all"

echo fafafa.core.lockfree Professional Build System
echo ===============================================
echo Using unified lazbuild tool: %LAZBUILD%
echo.

:: Check lazbuild tool
if not exist "%LAZBUILD%" (
    echo ERROR: Unified lazbuild tool not found at %LAZBUILD%
    echo Please ensure tools\lazbuild.bat is properly configured
    exit /b 1
)

:: Create output directory
if not exist "%BIN_DIR%" mkdir "%BIN_DIR%"

if "%ACTION%"=="clean" goto :CLEAN
if "%ACTION%"=="build" goto :BUILD
if "%ACTION%"=="test" goto :TEST
if "%ACTION%"=="benchmark" goto :BENCHMARK
if "%ACTION%"=="all" goto :ALL
goto :USAGE

:CLEAN
echo Cleaning build artifacts...
if exist "%BIN_DIR%\tests_lockfree.exe" del "%BIN_DIR%\tests_lockfree.exe"
if exist "%BIN_DIR%\lockfree_tests.exe" del "%BIN_DIR%\lockfree_tests.exe"
if exist "%BIN_DIR%\benchmark_lockfree.exe" del "%BIN_DIR%\benchmark_lockfree.exe"
if exist "%BIN_DIR%\example_lockfree.exe" del "%BIN_DIR%\example_lockfree.exe"
if exist "%BIN_DIR%\aba_test.exe" del "%BIN_DIR%\aba_test.exe"
if exist "%SCRIPT_DIR%lib" rmdir /s /q "%SCRIPT_DIR%lib"
if exist "%ROOT_DIR%\play\fafafa.core.lockfree\lib" rmdir /s /q "%ROOT_DIR%\play\fafafa.core.lockfree\lib"
if exist "%ROOT_DIR%\examples\fafafa.core.lockfree\lib" rmdir /s /q "%ROOT_DIR%\examples\fafafa.core.lockfree\lib"
echo Clean completed
goto :END

:BUILD
echo Building all projects using lazbuild...
echo.

echo [1/5] Building basic functionality tests...
call "%LAZBUILD%" --build-mode=Release "%SCRIPT_DIR%tests_lockfree.lpi"
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Basic test build failed
    exit /b 1
)

echo [2/5] Building unit tests...
call "%LAZBUILD%" --build-mode=Debug "%SCRIPT_DIR%fafafa.core.lockfree.tests.lpi"
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Unit test build failed
    exit /b 1
)

echo [3/5] Building ABA verification test...
call "%LAZBUILD%" --build-mode=Release "%ROOT_DIR%\play\fafafa.core.lockfree\aba_test.lpi"
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: ABA test build failed
    exit /b 1
)

echo [4/5] Building performance benchmark...
call "%LAZBUILD%" --build-mode=Release "%SCRIPT_DIR%benchmark_lockfree.lpi"
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Benchmark build failed
    exit /b 1
)

echo [5/5] Building example program...
call "%LAZBUILD%" --build-mode=Release "%ROOT_DIR%\examples\fafafa.core.lockfree\example_lockfree.lpi"
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Example program build failed
    exit /b 1
)

echo.
echo ✅ All builds completed successfully!
goto :END

:TEST
echo Running test suite...
echo.

:: Ensure tests are built
call :BUILD
if %ERRORLEVEL% NEQ 0 exit /b 1

echo [1/3] Running basic functionality tests...
echo y | "%BIN_DIR%\tests_lockfree.exe" >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Basic functionality tests failed
    exit /b 1
)
echo ✅ Basic functionality tests: PASSED

echo [2/3] Running ABA verification test...
echo y | "%BIN_DIR%\aba_test.exe" >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: ABA verification test failed
    exit /b 1
)
echo ✅ ABA verification test: PASSED

echo [3/3] Running example program test...
echo y | "%BIN_DIR%\example_lockfree.exe" >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Example program test failed
    exit /b 1
)
echo ✅ Example program test: PASSED

echo.
echo 🎉 All tests passed successfully!
goto :END

:BENCHMARK
echo Running performance benchmark...
echo.

:: Ensure benchmark is built
echo Building performance benchmark...
call "%LAZBUILD%" --build-mode=Release "%SCRIPT_DIR%benchmark_lockfree.lpi"
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Benchmark build failed
    exit /b 1
)

echo Running benchmark test...
echo y | "%BIN_DIR%\benchmark_lockfree.exe"
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Benchmark execution failed
    exit /b 1
)

echo.
echo ✅ Performance benchmark completed!
goto :END

:ALL
echo Running complete build and test cycle...
echo.

call :CLEAN
call :BUILD
if %ERRORLEVEL% NEQ 0 exit /b 1

call :TEST
if %ERRORLEVEL% NEQ 0 exit /b 1

echo.
echo 🎉 Complete build and test cycle completed successfully!
echo.
echo Generated executables:
echo   - %BIN_DIR%\tests_lockfree.exe        (Basic functionality tests)
echo   - %BIN_DIR%\lockfree_tests.exe        (Unit tests)
echo   - %BIN_DIR%\aba_test.exe              (ABA verification test)
echo   - %BIN_DIR%\benchmark_lockfree.exe    (Performance benchmark)
echo   - %BIN_DIR%\example_lockfree.exe      (Example program)
echo.
echo To run performance benchmark:
echo   BuildOrTest-Professional.bat benchmark
goto :END

:USAGE
echo Usage: BuildOrTest-Professional.bat [action]
echo.
echo Actions:
echo   clean      - Clean all build artifacts
echo   build      - Build all projects using lazbuild
echo   test       - Build and run all tests
echo   benchmark  - Build and run performance benchmark
echo   all        - Complete build and test cycle (default)
echo.
echo Examples:
echo   BuildOrTest-Professional.bat           # Complete cycle
echo   BuildOrTest-Professional.bat build     # Build only
echo   BuildOrTest-Professional.bat test      # Build and test
echo   BuildOrTest-Professional.bat benchmark # Performance test
echo   BuildOrTest-Professional.bat clean     # Clean artifacts
echo.
echo This script uses the unified tools\lazbuild.bat for consistent builds
goto :END

:END
echo.
echo Build system: Professional lazbuild-based
echo Timestamp: %DATE% %TIME%
