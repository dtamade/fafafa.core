@echo off
setlocal enabledelayedexpansion

REM Force UTF-8 to avoid garbled output
chcp 65001 >nul

set "SCRIPT_DIR=%~dp0"
set "EXEC=%SCRIPT_DIR%bin\lockfree_tests.exe"
set "LOG_DIR=%SCRIPT_DIR%logs"
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

set "TS=%date:~0,4%-%date:~5,2%-%date:~8,2%_%time:~0,2%-%time:~3,2%-%time:~6,2%"
set "TS=%TS: =0%"
set "LOG_FILE=%LOG_DIR%\run_%TS%_nointeractive.log"

echo [RunOnly_nointeractive] Usage: This script runs tests non-interactively (UTF-8, 60s timeout) and writes logs to %LOG_FILE%.
echo [RunOnly_nointeractive] Killing previous lockfree_tests.exe if any...
2>nul taskkill /f /t /im lockfree_tests.exe

if not exist "%EXEC%" (
  echo [RunOnly_nointeractive] ERROR: Test executable not found: %EXEC%
  exit /b 1
)

echo [RunOnly_nointeractive] Running with timeout 60s: %EXEC% --all --format=plain --progress

REM Use PowerShell Start-Process and poll for completion (60s watchdog)
set "PS_CMD=Start-Process -FilePath '%EXEC%' -ArgumentList '--all --format=plain --progress' -NoNewWindow -PassThru"
for /f "usebackq tokens=*" %%P in (`powershell -NoProfile -Command "%PS_CMD%"`) do set PID=%%P

set /a SECS=0
:WAIT_LOOP
if %SECS% GEQ 60 goto TIMEOUT
REM Check if process is still running
tasklist /FI "IMAGENAME eq lockfree_tests.exe" | find /I "lockfree_tests.exe" >nul
if errorlevel 1 goto DONE
set /a SECS+=1
timeout /t 1 >nul
goto WAIT_LOOP

:TIMEOUT
echo [RunOnly_nointeractive] TIMEOUT after 60 seconds. Killing process...
2>nul taskkill /f /t /im lockfree_tests.exe
set RC=1
goto OUTPUT

:DONE
set RC=0

:OUTPUT
REM Dump output by re-running tests into the log to ensure UTF-8 output captured
"%EXEC%" --all --format=plain --progress 1>"%LOG_FILE%" 2>&1
echo [RunOnly_nointeractive] ExitCode=%RC%
echo [RunOnly_nointeractive] Log: %LOG_FILE%
type "%LOG_FILE%"

exit /b %RC%

