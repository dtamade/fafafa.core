@echo off
setlocal EnableDelayedExpansion

REM Root of the tests directory (this script is placed under tests\)
set "TESTS_ROOT=%~dp0"
for %%D in ("%TESTS_ROOT%..") do set "REPO_ROOT=%%~fD"
set "HYGIENE_CHECKER=%TESTS_ROOT%check_repo_hygiene.bat"
set "LOG_DIR=%TESTS_ROOT%_run_all_logs"
set "SUMMARY_FILE=%TESTS_ROOT%run_all_tests_summary.txt"
set "DISCOVERY_FILE=%LOG_DIR%\run_all_discovery.txt"
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
  if exist "%~dp1buildOrTest.bat" goto :eof
)

set "DIR=%~dp1"
set "REL_DIR=!DIR:%TESTS_ROOT%=!"
if "!REL_DIR:~-1!"=="\" set "REL_DIR=!REL_DIR:~0,-1!"
set "MOD_FULL=!REL_DIR:\=.!"
for %%D in ("%~dp1.") do set "MOD_LEAF=%%~nD"
call set "__RUN_ALREADY=%%RUN_SEEN_!MOD_FULL!%%"
if defined __RUN_ALREADY goto :eof
set "RUN_SEEN_!MOD_FULL!=1"
set "__RUN_ALREADY="

call :should_run "!MOD_FULL!" "!MOD_LEAF!"
if errorlevel 1 goto :eof
set "LOG_FILE=%LOG_DIR%\!MOD_FULL!.log"
set "MODULE_SIMD_OUTPUT_ROOT="
if defined SIMD_OUTPUT_ROOT if /I "!MOD_FULL:~0,16!"=="fafafa.core.simd" set "MODULE_SIMD_OUTPUT_ROOT=%SIMD_OUTPUT_ROOT%\run_all\!MOD_FULL!"

echo.>"%LOG_FILE%"
echo ========================================>>"%LOG_FILE%"
echo Module: !MOD_FULL!>>"%LOG_FILE%"
echo Basename: !MOD_LEAF!>>"%LOG_FILE%"
echo Script: %SCRIPT%>>"%LOG_FILE%"
echo Started: %DATE% %TIME%>>"%LOG_FILE%"
if defined MODULE_SIMD_OUTPUT_ROOT echo SIMD_OUTPUT_ROOT: !MODULE_SIMD_OUTPUT_ROOT!>>"%LOG_FILE%"
echo ========================================>>"%LOG_FILE%"

set /a TOTAL+=1
set "ACTION=%RUN_ACTION%"
if not defined ACTION set "ACTION=test"
pushd "%~dp1" >nul
set "PREV_SIMD_OUTPUT_ROOT=%SIMD_OUTPUT_ROOT%"
if defined MODULE_SIMD_OUTPUT_ROOT set "SIMD_OUTPUT_ROOT=!MODULE_SIMD_OUTPUT_ROOT!"
echo Action: !ACTION!>>"%LOG_FILE%"
call "%SCRIPT%" "!ACTION!" >>"%LOG_FILE%" 2>&1
set "RC=%ERRORLEVEL%"
set "SIMD_OUTPUT_ROOT=%PREV_SIMD_OUTPUT_ROOT%"
set "PREV_SIMD_OUTPUT_ROOT="
set "MODULE_SIMD_OUTPUT_ROOT="
set "ACTION="
popd >nul

if "%RC%"=="0" (
  set /a PASSED+=1
  echo [PASS] !MOD_FULL! ^(rc=%RC%^)
) else (
  set /a FAILED+=1
  echo [FAIL] !MOD_FULL! ^(rc=%RC%^)
  if defined FAILED_LIST (
    set "FAILED_LIST=%FAILED_LIST%,!MOD_FULL!"
  ) else (
    set "FAILED_LIST=!MOD_FULL!"
  )
  if "%STOP_ON_FAIL%"=="1" goto :finish
)

goto :eof

:is_generated_dir
set "CHECK_DIR=%~f1"
if "%CHECK_DIR%"=="" exit /b 1
set "CHECK_DIR_NORM=%CHECK_DIR%"
if not "%CHECK_DIR_NORM:~-1%"=="\" set "CHECK_DIR_NORM=%CHECK_DIR_NORM%\"
echo %CHECK_DIR_NORM% | findstr /I /C:"\_run_all_logs\" /C:"\run_all\" /C:"\bin\" /C:"\lib\" /C:"\logs\" /C:"\nonx86.optin\" /C:"\dispatch.preinit.smoke\" >nul 2>nul
if not errorlevel 1 exit /b 0
exit /b 1

:queue_script_if_present
if exist "%~1" >>"%DISCOVERY_FILE%" echo %~f1
exit /b 0

:collect_module_dir
set "DISCOVERY_DIR=%~f1"
if "%DISCOVERY_DIR%"=="" goto :eof
call :is_generated_dir "%DISCOVERY_DIR%"
if not errorlevel 1 goto :eof

if exist "%DISCOVERY_DIR%\BuildOrTest.bat" (
  call :queue_script_if_present "%DISCOVERY_DIR%\BuildOrTest.bat"
  goto :eof
)
if exist "%DISCOVERY_DIR%\buildOrTest.bat" (
  call :queue_script_if_present "%DISCOVERY_DIR%\buildOrTest.bat"
  goto :eof
)
if exist "%DISCOVERY_DIR%\BuildAndTest.bat" (
  call :queue_script_if_present "%DISCOVERY_DIR%\BuildAndTest.bat"
)
goto :eof

:main
echo Running module test scripts under: %TESTS_ROOT%
echo Logs: %LOG_DIR%
echo.
if not exist "%HYGIENE_CHECKER%" (
  echo [CHECK] Missing hygiene checker: %HYGIENE_CHECKER%
  exit /b 2
)

call "%HYGIENE_CHECKER%" "%REPO_ROOT%"
if errorlevel 1 exit /b %ERRORLEVEL%

if exist "%DISCOVERY_FILE%" del /q "%DISCOVERY_FILE%" >nul 2>&1
type nul > "%DISCOVERY_FILE%"

call :collect_module_dir "%TESTS_ROOT%"
for /f "delims=" %%D in ('dir /b /s /ad "%TESTS_ROOT%" 2^>nul') do call :collect_module_dir "%%~fD"

for /f "usebackq delims=" %%F in ("%DISCOVERY_FILE%") do call :run_one "%%F"

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
