@echo off
:: Professional Build Script using unified tools/lazbuild.bat
:: Usage: BuildOrTest-Lazbuild.bat [clean|build|test|benchmark|all]

setlocal

set "SCRIPT_DIR=%~dp0"
set "ROOT_DIR=%SCRIPT_DIR%..\.."
set "BIN_DIR=%ROOT_DIR%\bin"
set "TOOLS_DIR=%ROOT_DIR%\tools"
set "LAZBUILD=%TOOLS_DIR%\lazbuild.bat"

set "ACTION=%1"
if "%ACTION%"=="" set "ACTION=all"

echo fafafa.core.lockfree Professional Build System
echo ===============================================
echo Using unified lazbuild: %LAZBUILD%
echo.

:: Check lazbuild tool
if not exist "%LAZBUILD%" (
    echo ERROR: Unified lazbuild tool not found
    echo Please ensure tools\lazbuild.bat is configured
    exit /b 1
)

:: Create output directory
if not exist "%BIN_DIR%" mkdir "%BIN_DIR%"

if "%ACTION%"=="clean" goto :CLEAN
if "%ACTION%"=="build" goto :BUILD
if "%ACTION%"=="test" goto :TEST
if "%ACTION%"=="benchmark" goto :BENCHMARK
if "%ACTION%"=="all" goto :ALL
if "%ACTION%"=="test-with-map-interface" goto :TEST_MAP

goto :USAGE

:CLEAN
echo Cleaning build artifacts...
if exist "%BIN_DIR%\tests_lockfree.exe" del "%BIN_DIR%\tests_lockfree.exe"
if exist "%BIN_DIR%\benchmark_lockfree.exe" del "%BIN_DIR%\benchmark_lockfree.exe"
if exist "%BIN_DIR%\aba_test.exe" del "%BIN_DIR%\aba_test.exe"
if exist "%BIN_DIR%\example_lockfree.exe" del "%BIN_DIR%\example_lockfree.exe"
if exist "%SCRIPT_DIR%lib" rmdir /s /q "%SCRIPT_DIR%lib"
echo Clean completed
goto :END

:BUILD
echo Building projects using lazbuild...
echo.

echo [1/5] Building basic tests...
call "%LAZBUILD%" --build-mode=Release "%SCRIPT_DIR%tests_lockfree.lpi"
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Basic test build failed
    exit /b 1
)

echo [2/5] Building ABA test...
call "%LAZBUILD%" --build-mode=Release "%ROOT_DIR%\play\fafafa.core.lockfree\aba_test.lpi"
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: ABA test build failed
    exit /b 1
)

echo [3/5] Building benchmark...
call "%LAZBUILD%" --build-mode=Release "%SCRIPT_DIR%benchmark_lockfree.lpi"
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Benchmark build failed
    exit /b 1
)

echo [4/5] Building example...
call "%LAZBUILD%" --build-mode=Release "%ROOT_DIR%\examples\fafafa.core.lockfree\example_lockfree.lpi"
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Example build failed
    exit /b 1
)

REM Build extra tests (no LPI)
call fpc -Fu"%ROOT_DIR%\src" -FE"%BIN_DIR%" "%SCRIPT_DIR%test_oa_hashmap_extras.lpr"
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: OA extra test build failed
    exit /b 1
)
call fpc -Fu"%ROOT_DIR%\src" -FE"%BIN_DIR%" "%SCRIPT_DIR%test_padding_smoke.lpr"
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Padding smoke test build failed
    exit /b 1
)

echo.
echo SUCCESS: All builds completed!
goto :END

:TEST
echo Running test suite...
echo.

call :BUILD
if %ERRORLEVEL% NEQ 0 exit /b 1

echo [1/3] Running basic tests...
echo y | "%BIN_DIR%\tests_lockfree.exe" >"%BIN_DIR%\_tests_lockfree.log" 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Basic tests failed
    type "%BIN_DIR%\_tests_lockfree.log"
    exit /b 1
)
echo SUCCESS: Basic tests PASSED

echo [2/3] Running ABA test...
rem Rebuild ABA test with CI mode to avoid interactive pause
set "IDE_OPTS= -dFAFAFA_CI_MODE"
call "%LAZBUILD%" --build-mode=Release "%ROOT_DIR%\play\fafafa.core.lockfree\aba_test.lpi"
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: ABA test build failed (CI mode)
    exit /b 1
)
set "IDE_OPTS="
"%BIN_DIR%\aba_test.exe" >"%BIN_DIR%\_aba_test.log" 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: ABA test failed
    type "%BIN_DIR%\_aba_test.log"
    exit /b 1
)
echo SUCCESS: ABA test PASSED

echo [3/3] Running example...
"%BIN_DIR%\example_lockfree.exe" >"%BIN_DIR%\_example_lockfree.log" 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Example failed
    type "%BIN_DIR%\_example_lockfree.log"
    exit /b 1
)
echo SUCCESS: Example PASSED


:TEST_MAP
REM Try define for project compile options via environment override
set "FPCOPT=-dFAFAFA_CORE_MAP_INTERFACE"

echo Running tests with MAP INTERFACE enabled...
set "IDE_OPTS= -dFAFAFA_CORE_MAP_INTERFACE"

call "%LAZBUILD%" --build-mode=MapInterface "%SCRIPT_DIR%fafafa.core.lockfree.tests.lpi"
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Build with MAP INTERFACE failed
    exit /b 1
)

"%SCRIPT_DIR%bin\lockfree_tests.exe" --all
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Tests with MAP INTERFACE failed
    exit /b 1
)

echo SUCCESS: Tests with MAP INTERFACE PASSED
goto :END

echo.
echo SUCCESS: All tests passed!
goto :END

:BENCHMARK
echo Running performance benchmark...
echo.

echo Building benchmark...
call "%LAZBUILD%" --build-mode=Release "%SCRIPT_DIR%benchmark_lockfree.lpi"
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Benchmark build failed
    exit /b 1
)

echo Running benchmark...
echo y | "%BIN_DIR%\benchmark_lockfree.exe"
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Benchmark failed
    exit /b 1
)

echo.
echo SUCCESS: Benchmark completed!
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
echo SUCCESS: Complete cycle finished!
echo.
echo Generated files:
echo   - %BIN_DIR%\tests_lockfree.exe
echo   - %BIN_DIR%\aba_test.exe
echo   - %BIN_DIR%\benchmark_lockfree.exe
echo   - %BIN_DIR%\example_lockfree.exe
echo.
echo Run benchmark: BuildOrTest-Lazbuild.bat benchmark
goto :END

:USAGE
echo Usage: BuildOrTest-Lazbuild.bat [action]
echo.
echo Actions:
echo   clean      - Clean build artifacts
echo   build      - Build all projects
echo   test       - Build and run tests
echo   benchmark  - Build and run benchmark
echo   all        - Complete cycle (default)
echo.
echo This script uses unified tools\lazbuild.bat
goto :END

:END
echo.
echo Build system: lazbuild-based
echo Completed: %DATE% %TIME%
