@echo off
setlocal EnableDelayedExpansion

REM Root of the tests directory (this script is placed under tests\)
set "TESTS_ROOT=%~dp0"
set "LOG_DIR=%TESTS_ROOT%_run_all_logs"
set "SUMMARY_FILE=%TESTS_ROOT%run_all_tests_summary.txt"
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%" >nul 2>&1

REM Optional filters:
REM - Pass module names as arguments to run only those (e.g., fafafa.core.collections.arr fafafa.core.collections.base)
REM - Set STOP_ON_FAIL=1 to stop on first failure
set "FILTER=%*"

set TOTAL=0
set PASSED=0
set FAILED=0
set "FAILED_LIST="

REM Decide if a module should run based on FILTER args
:should_run
set "__MOD=%~1"
if "%FILTER%"=="" (
  exit /b 0
) else (
  set "__F= %FILTER% "
  set "__S=!__F: %__MOD% =!"
  if not "!__F!"=="!__S!" (
    exit /b 0
  ) else (
    exit /b 1
  )
)

REM Run a single script and capture logs/exit code
:run_one
set "SCRIPT=%~1"
for %%D in ("%~dp1.") do set "MOD=%%~nD"
call :should_run "%MOD%"
if errorlevel 1 goto :eof
set "LOG_FILE=%LOG_DIR%\%MOD%.log"

echo.>"%LOG_FILE%"
echo ========================================>>"%LOG_FILE%"
echo Module: %MOD%>>"%LOG_FILE%"
echo Script: %SCRIPT%>>"%LOG_FILE%"
echo Started: %DATE% %TIME%>>"%LOG_FILE%"
echo ========================================>>"%LOG_FILE%"

set /a TOTAL+=1
pushd "%~dp1" >nul
call "%SCRIPT%" >>"%LOG_FILE%" 2>&1
set "RC=%ERRORLEVEL%"
popd >nul

if "%RC%"=="0" (
  set /a PASSED+=1
  echo [PASS] %MOD% (rc=%RC%)
) else (
  set /a FAILED+=1
  echo [FAIL] %MOD% (rc=%RC%)
  if defined FAILED_LIST (
    set "FAILED_LIST=%FAILED_LIST%,%MOD%"
  ) else (
    set "FAILED_LIST=%MOD%"
  )
  if "%STOP_ON_FAIL%"=="1" goto :finish
)

goto :eof

:main
echo Running module test scripts under: %TESTS_ROOT%
echo Logs: %LOG_DIR%
echo.

for /R "%TESTS_ROOT%" %%F in (BuildOrTest.bat) do call :run_one "%%~fF"
for /R "%TESTS_ROOT%" %%F in (BuildAndTest.bat) do call :run_one "%%~fF"

:finish
echo.>"%SUMMARY_FILE%"
echo ========================================>>"%SUMMARY_FILE%"
echo Run-all summary (%DATE% %TIME%)>>"%SUMMARY_FILE%"
echo Logs dir: %LOG_DIR%>>"%SUMMARY_FILE%"
echo ========================================>>"%SUMMARY_FILE%"
echo Total:  %TOTAL%>>"%SUMMARY_FILE%"
echo Passed: %PASSED%>>"%SUMMARY_FILE%"
echo Failed: %FAILED%>>"%SUMMARY_FILE%"
if defined FAILED_LIST echo Failed modules: %FAILED_LIST%>>"%SUMMARY_FILE%"

type "%SUMMARY_FILE%"

if %FAILED% GTR 0 (
  echo Some modules failed. See logs under: %LOG_DIR%
  exit /b 1
) else (
  echo All modules passed.
  exit /b 0
)
