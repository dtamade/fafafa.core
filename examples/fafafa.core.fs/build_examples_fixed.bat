@echo off
cd /d "%~dp0"
echo === fafafa.core.fs Examples Build Script ===
echo Working directory: %CD%
echo.

REM Set paths (running from examples/fafafa.core.fs/ directory)
set PROJECT_ROOT=%~dp0..\..
set SRC_PATH=%PROJECT_ROOT%\src
set BIN_PATH=bin
set LIB_PATH=%~dp0lib

REM Different optimization levels for different types of examples
set REGULAR_FLAGS=-Mobjfpc -Fu"%SRC_PATH%" -FE"%BIN_PATH%" -FU"%LIB_PATH%" -gl -O2
set PERFORMANCE_FLAGS=-Mobjfpc -Fu"%SRC_PATH%" -FE"%BIN_PATH%" -FU"%LIB_PATH%" -gl -O3 -CX -XX

REM Ensure directories exist
if not exist "%BIN_PATH%" (
    echo Creating bin directory: %BIN_PATH%
    mkdir "%BIN_PATH%"
)

if not exist "%LIB_PATH%" (
    echo Creating lib directory: %LIB_PATH%
    mkdir "%LIB_PATH%"
)

echo Project Root: %PROJECT_ROOT%
echo Source: %SRC_PATH%
echo Executables: %BIN_PATH%
echo Intermediate: %LIB_PATH%
echo.

echo Building all fafafa.core.fs examples...
echo.

echo [1/4] Building example_fs_basic.exe (O2 optimization)...
fpc %REGULAR_FLAGS% -o"%BIN_PATH%\example_fs_basic.exe" "example_fs_basic.lpr"
if %ERRORLEVEL% EQU 0 (
    echo SUCCESS: example_fs_basic.exe
) else (
    echo FAILED: example_fs_basic.lpr
    set BUILD_FAILED=1
)

echo.
echo [2/4] Building example_fs_advanced.exe (O2 optimization)...
fpc %REGULAR_FLAGS% -o"%BIN_PATH%\example_fs_advanced.exe" "example_fs_advanced.lpr"
if %ERRORLEVEL% EQU 0 (
    echo SUCCESS: example_fs_advanced.exe
) else (
    echo FAILED: example_fs_advanced.lpr
    set BUILD_FAILED=1
)

echo.
echo [3/4] Building example_fs_performance.exe (O3 optimization)...
fpc %PERFORMANCE_FLAGS% -o"%BIN_PATH%\example_fs_performance.exe" "example_fs_performance.lpr"
if %ERRORLEVEL% EQU 0 (
    echo SUCCESS: example_fs_performance.exe (O3 optimized)
) else (
    echo FAILED: example_fs_performance.lpr
    set BUILD_FAILED=1
)

echo.
echo [4/4] Building example_fs_benchmark.exe (O3 optimization)...
fpc %PERFORMANCE_FLAGS% -o"%BIN_PATH%\example_fs_benchmark.exe" "example_fs_benchmark.lpr"
if %ERRORLEVEL% EQU 0 (
    echo SUCCESS: example_fs_benchmark.exe (O3 optimized)
) else (
    echo FAILED: example_fs_benchmark.lpr
    set BUILD_FAILED=1
)

echo.
echo === Build Complete ===
echo.

echo Generated files in %BIN_PATH%:
if exist "%BIN_PATH%\example_fs_basic.exe" echo   example_fs_basic.exe (O2 - regular)
if exist "%BIN_PATH%\example_fs_advanced.exe" echo   example_fs_advanced.exe (O2 - regular)
if exist "%BIN_PATH%\example_fs_performance.exe" echo   example_fs_performance.exe (O3 - performance)
if exist "%BIN_PATH%\example_fs_benchmark.exe" echo   example_fs_benchmark.exe (O3 - performance)

echo.
echo Optimization levels:
echo   O2: Basic and Advanced examples (regular functionality)
echo   O3: Performance and Benchmark examples (maximum optimization)

echo.
echo Usage:
echo   cd %BIN_PATH%
echo   example_fs_basic.exe
echo   example_fs_advanced.exe
echo   example_fs_performance.exe
echo   example_fs_benchmark.exe

if defined BUILD_FAILED (
    echo.
    echo Some examples failed to build. Check the output above.
    exit /b 1
) else (
    echo.
    echo All examples built successfully!
    exit /b 0
)
