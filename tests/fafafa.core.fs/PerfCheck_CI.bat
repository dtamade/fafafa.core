@echo off
setlocal ENABLEDELAYEDEXPANSION

REM PerfCheck_CI.bat - Run FS perf and fail build on regression (if baseline exists)
REM Usage: tests\fafafa.core.fs\PerfCheck_CI.bat [perf args...]
REM Notes:
REM  - Uses ArchivePerfResult.bat /failOnLow to detect LOW vs baseline ranges
REM  - If baseline.txt is missing, exits 0 by default (set PERF_STRICT_REQUIRE_BASELINE=1 to fail)

set "SCRIPT_DIR=%~dp0"
set "PERF_DIR=%SCRIPT_DIR%performance-data"
set "BASELINE=%PERF_DIR%\baseline.txt"
set "ARCHIVER=%SCRIPT_DIR%ArchivePerfResult.bat"

if not exist "%PERF_DIR%" mkdir "%PERF_DIR%" >nul 2>&1

if not exist "%BASELINE%" (
  echo [INFO] Baseline not found: %BASELINE%
  if "%PERF_STRICT_REQUIRE_BASELINE%"=="1" (
    echo [FAIL] PERF_STRICT_REQUIRE_BASELINE=1 and baseline is missing. Exiting with error.
    exit /b 2
  ) else (
    echo [INFO] Skipping strict regression check because baseline is missing.
    call "%ARCHIVER%" %*
    exit /b %ERRORLEVEL%
  )
)

call "%ARCHIVER%" /failOnLow %*
set "EC=%ERRORLEVEL%"
echo [CI] Exit code: %EC%
exit /b %EC%

