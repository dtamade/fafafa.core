@echo off
setlocal enabledelayedexpansion

REM Summarize PadOn/PadOff benchmark log
REM Usage: Summarize_Benchmark_PadCompare.bat [log_file] [tail_lines]

set "SCRIPT_DIR=%~dp0"
set "LOG_DIR=%SCRIPT_DIR%logs"
set "LOG_FILE=%~1"
set "TAIL_LINES=%~2"

if "%LOG_FILE%"=="" set "LOG_FILE=%LOG_DIR%\latest.log"
if "%TAIL_LINES%"=="" set "TAIL_LINES=60"

if not exist "%LOG_FILE%" (
  echo [error] Log file not found: %LOG_FILE%
  echo        Please run: BuildAndTest.bat benchmark-compare
  exit /b 1
)

REM Try to extract some common key lines if present
for %%P in (ops/ms ns/op MicroBench MapEx name) do (
  echo ---------------- FINDSTR: %%P ----------------
  findstr /I "%%P" "%LOG_FILE%"
  echo.
)

REM Always show tail for context (requires PowerShell)
echo ---------------- TAIL (last %TAIL_LINES% lines) ----------------
powershell -NoProfile -Command "Get-Content -LiteralPath '%LOG_FILE%' -Tail %TAIL_LINES% | ForEach-Object { $_ }"
set "RC=%ERRORLEVEL%"
if not "%RC%"=="0" (
  echo [warn] PowerShell tail failed or unavailable. Showing full log instead.
  type "%LOG_FILE%"
)

exit /b 0

