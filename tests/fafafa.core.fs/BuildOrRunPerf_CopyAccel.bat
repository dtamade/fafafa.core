@echo off
setlocal ENABLEDELAYEDEXPANSION
REM CopyAccel Performance Placeholder Script
REM This skeleton does not perform heavy work. It documents how to run copy/move perf locally.

echo [CopyAccel Perf] Placeholder
echo.
echo Usage:
echo   1^) Enable accelerated path (default on):
echo      set FAFAFA_FS_COPYACCEL=1
echo   2^) Run existing perf bench (general):
echo      tests\fafafa.core.fs\BuildOrRunPerf.bat
echo   3^) Compare results under:
echo      tests\fafafa.core.fs\performance-data
echo.
echo Tips:
echo   - To disable acceleration for A/B comparison:
echo     set FAFAFA_FS_COPYACCEL=0
echo   - Prefer large single-file tests (1GB/4GB) and many small files (CopyTree) manually.

echo Done.
exit /b 0

