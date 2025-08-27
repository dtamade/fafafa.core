@echo off
setlocal enabledelayedexpansion

REM Summarize latest minimal standalone tests log
REM Usage: Summarize_Minimal.bat [log_file] [tail_lines]

set "SCRIPT_DIR=%~dp0"
set "LOG_DIR=%SCRIPT_DIR%logs"
set "LOG_FILE=%~1"
set "TAIL_LINES=%~2"

if "%LOG_FILE%"=="" set "LOG_FILE=%LOG_DIR%\latest_minimal.log"
if "%TAIL_LINES%"=="" set "TAIL_LINES=80"

if not exist "%LOG_FILE%" (
  echo [error] Log file not found: %LOG_FILE%
  echo        Please run: BuildOrTest.bat minimal
  exit /b 1
)

echo ---------------- SUMMARY (OK/ERROR/Fail) ----------------
findstr /I "OK ERROR FAIL passed" "%LOG_FILE%"

for %%K in (api tombstone resource alias map queue) do (
  echo ---------------- FINDSTR: %%K ----------------
  findstr /I "%%K" "%LOG_FILE%"
)

echo ---------------- TAIL (last %TAIL_LINES% lines) ----------------
powershell -NoProfile -Command "Get-Content -LiteralPath '%LOG_FILE%' -Tail %TAIL_LINES% | ForEach-Object { $_ }" 2>nul
if errorlevel 1 type "%LOG_FILE%"

exit /b 0

