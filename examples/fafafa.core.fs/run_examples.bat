@echo off
cd /d "%~dp0"
echo ========================================
echo   fafafa.core.fs Examples Showcase
echo ========================================
echo.

REM Set paths
set PROJECT_ROOT=%~dp0..\..
set BIN_PATH=bin

echo Checking for examples in %BIN_PATH%...
echo.

if not exist "%BIN_PATH%\example_fs_basic.exe" (
    echo ERROR: Examples not found in bin directory.
    echo Please run build_examples_fixed.bat first.
    pause
    exit /b 1
)

echo === Running All fafafa.core.fs Examples ===
echo.

echo [1/4] Running Basic File Operations Demo...
echo ==========================================
"%BIN_PATH%\example_fs_basic.exe"
echo.
echo Press any key to continue to advanced demo...
pause >nul

echo.
echo [2/4] Running Advanced Features Demo...
echo =======================================
"%BIN_PATH%\example_fs_advanced.exe"
echo.
echo Press any key to continue to performance demo...
pause >nul

echo.
echo [3/4] Running Performance Comparison Demo...
echo ============================================
"%BIN_PATH%\example_fs_performance.exe"
echo.
echo Press any key to continue to benchmark demo...
pause >nul

echo.
echo [4/4] Running Benchmark Tests...
echo ================================
"%BIN_PATH%\example_fs_benchmark.exe"
echo.

echo ========================================
echo   All Examples Completed Successfully!
echo ========================================
echo.
echo The fafafa.core.fs module demonstrates:
echo   - Basic file operations (create, read, write, delete)
echo   - Advanced features (locking, permissions, links)
echo   - High performance file I/O
echo   - Comprehensive benchmarking
echo.
echo Thank you for exploring fafafa.core.fs!
echo.
pause
