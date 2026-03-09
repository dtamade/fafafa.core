@echo off
setlocal EnableDelayedExpansion

REM Root of the tests directory (this script is placed under tests\)
set "TESTS_ROOT=%~dp0"
set "LOG_DIR=%TESTS_ROOT%_run_all_logs"
set "SUMMARY_FILE=%TESTS_ROOT%run_all_tests_summary.txt"
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%" >nul 2>&1

REM Optional filters:
REM - Pass module names as arguments to run only those.
REM - Module name rule: relative directory under tests\, with path separators replaced by dots.
REM   Examples:
REM     tests\fafafa.core.json            -> fafafa.core.json
REM     tests\fafafa.core.collections\vec -> fafafa.core.collections.vec
REM - Compatibility: also accepts basename filters (e.g. "vec") and group filters
REM   (e.g. "fafafa.core.collections" matches "fafafa.core.collections.vec").
REM - Prefix filter with '=' for exact-only matching (no group/prefix expansion).
REM   Example: =fafafa.core.simd
REM - Set STOP_ON_FAIL=1 to stop on first failure
set "FILTER=%*"

set TOTAL=0
set PASSED=0
set FAILED=0
set "FAILED_LIST="

REM Force non-interactive behavior in module scripts (if they respect it)
set "FAFAFA_INTERACTIVE=0"

goto :main

REM String length helper: call :strlen "text" outVar
:strlen
setlocal EnableDelayedExpansion
set "s=%~1"
set /a len=0
:strlen_loop
if defined s (
  set "s=!s:~1!"
  set /a len+=1
  goto :strlen_loop
)
endlocal & set "%~2=%len%"
exit /b 0

REM Decide if a module should run based on FILTER args
:should_run
set "__MOD_FULL=%~1"
set "__MOD_LEAF=%~2"
if "%FILTER%"=="" exit /b 0

for %%F in (%FILTER%) do (
  set "__F_RAW=%%~F"
  set "__F_NORM=!__F_RAW:/=.!"
  set "__F_NORM=!__F_NORM:\=.!"
  set "__EXACT_ONLY="

  if "!__F_NORM:~0,1!"=="=" (
    set "__EXACT_ONLY=1"
    set "__F_NORM=!__F_NORM:~1!"
  )

  if "!__F_NORM!"=="" (
    REM skip empty exact filter such as "="
  ) else (
    REM Exact match (full or leaf)
    if /I "!__F_NORM!"=="!__MOD_FULL!" exit /b 0
    if /I "!__F_NORM!"=="!__MOD_LEAF!" exit /b 0

    if not defined __EXACT_ONLY (
      REM Group/prefix match: "a.b" selects "a.b.c"
      set "__PFX=!__F_NORM!."
      call :strlen "!__PFX!" __PFX_LEN
      call set "__START=%%__MOD_FULL:~0,%__PFX_LEN%%%"
      if /I "!__START!"=="!__PFX!" exit /b 0
    )
  )
)

exit /b 1

REM Run a single script and capture logs/exit code
:run_one
set "SCRIPT=%~1"

REM Skip BuildAndTest.bat when BuildOrTest.bat exists in the same module dir
if /I "%~nx1"=="BuildAndTest.bat" (
  if exist "%~dp1BuildOrTest.bat" goto :eof
)

set "DIR=%~dp1"
set "REL_DIR=!DIR:%TESTS_ROOT%=!"
if "!REL_DIR:~-1!"=="\" set "REL_DIR=!REL_DIR:~0,-1!"
set "MOD_FULL=!REL_DIR:\=.!"
for %%D in ("%~dp1.") do set "MOD_LEAF=%%~nD"

call :should_run "!MOD_FULL!" "!MOD_LEAF!"
if errorlevel 1 goto :eof
set "LOG_FILE=%LOG_DIR%\!MOD_FULL!.log"

echo.>"%LOG_FILE%"
echo ========================================>>"%LOG_FILE%"
echo Module: !MOD_FULL!>>"%LOG_FILE%"
echo Basename: !MOD_LEAF!>>"%LOG_FILE%"
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
  echo [PASS] !MOD_FULL! (rc=%RC%)
) else (
  set /a FAILED+=1
  echo [FAIL] !MOD_FULL! (rc=%RC%)
  if defined FAILED_LIST (
    set "FAILED_LIST=%FAILED_LIST%,!MOD_FULL!"
  ) else (
    set "FAILED_LIST=!MOD_FULL!"
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
if not "%FILTER%"=="" if "%TOTAL%"=="0" (
  echo Filter matched 0 modules.>>"%SUMMARY_FILE%"
  echo Filter args: %FILTER%>>"%SUMMARY_FILE%"
)

type "%SUMMARY_FILE%"

if not "%FILTER%"=="" if %TOTAL% EQU 0 (
  exit /b 2
)

if %FAILED% GTR 0 (
  echo Some modules failed. See logs under: %LOG_DIR%
  exit /b 1
) else (
  echo All modules passed.
  exit /b 0
)
