@echo off
setlocal enabledelayedexpansion

set "SCRIPT_DIR=%~dp0"
set "EXEC=%SCRIPT_DIR%bin\lockfree_tests.exe"
set "LOG_DIR=%SCRIPT_DIR%logs"
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

set "TS=%date:~0,4%-%date:~5,2%-%date:~8,2%_%time:~0,2%-%time:~3,2%-%time:~6,2%"
set "TS=%TS: =0%"
set "LOG_FILE=%LOG_DIR%\run_%TS%.log"

echo [RunOnly] Killing previous lockfree_tests.exe if any...
2>nul taskkill /f /im lockfree_tests.exe

if not exist "%EXEC%" (
  echo [RunOnly] ERROR: Test executable not found: %EXEC%
  exit /b 1
)

echo [RunOnly] Running: %EXEC% --all --format=plain --progress
"%EXEC%" --all --format=plain --progress 1>"%LOG_FILE%" 2>&1
set "RC=%ERRORLEVEL%"
echo [RunOnly] ExitCode=%RC%

type "%LOG_FILE%"

exit /b %RC%

