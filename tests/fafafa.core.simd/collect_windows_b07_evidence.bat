@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "ROOT=%SIMD_SCRIPT_ROOT%"
if "%ROOT%"=="" set "ROOT=%~dp0"
if not "%ROOT%"=="" if not "%ROOT:~-1%"=="\" set "ROOT=%ROOT%\"
if not exist "%ROOT%buildOrTest.bat" set "ROOT=%CD%\tests\fafafa.core.simd\"
if not "%ROOT:~-1%"=="\" set "ROOT=%ROOT%\"
if "%ROOT:~-1%"=="\" set "ROOT=%ROOT:~0,-1%"
set "LOG_DIR=%ROOT%\logs"
set "LOG_PATH=%SIMD_WIN_EVIDENCE_LOG_FILE%"
if "%LOG_PATH%"=="" set "LOG_PATH=%LOG_DIR%\windows_b07_gate.log"
set "SELF=%ROOT%\buildOrTest.bat"
set "TMP_OUT=%LOG_DIR%\windows_b07_gate.capture.tmp"

if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

del /q "%TMP_OUT%" >nul 2>nul

set "STARTED="
for /f "usebackq delims=" %%I in (`powershell -NoProfile -Command "Get-Date -Format 'yyyy-MM-dd HH:mm:ss zzz'" 2^>nul`) do set "STARTED=%%I"
if not defined STARTED set "STARTED=%DATE% %TIME%"

set "CMD_VER="
for /f "usebackq delims=" %%I in (`cmd /c ver`) do set "CMD_VER=%%I"

(
  echo [B07] Windows evidence capture
  echo [B07] Source: collect_windows_b07_evidence.bat
  echo [B07] HostOS: %OS%
  if defined CMD_VER echo [B07] CmdVer: %CMD_VER%
  echo [B07] Started: %STARTED%
  echo [B07] Working dir: %CD%
  echo [B07] Command: buildOrTest.bat gate
  echo.
) > "%LOG_PATH%"

set "SIMD_SUPPRESS_BUILD_WARNINGS=1"
set /a TOTAL_VALUE=0
set /a PASSED_VALUE=0
set /a FAILED_VALUE=0
set "GATE_EXIT_CODE=0"

call :run_gate_step "Build + check SIMD module" check
if errorlevel 1 goto :gate_failed
call :run_gate_step "Interface completeness" interface-completeness
if errorlevel 1 goto :gate_failed
call :run_gate_step "Backend adapter sync Pascal smoke" adapter-sync-pascal
if errorlevel 1 goto :gate_failed

>> "%TMP_OUT%" echo [GATE] OK
set "GATE_EXIT_CODE=0"
goto :gate_done

:gate_failed
set "GATE_EXIT_CODE=1"

:gate_done
type "%TMP_OUT%" >> "%LOG_PATH%"
>> "%LOG_PATH%" echo.
>> "%LOG_PATH%" echo [B07] GATE_EXIT_CODE=%GATE_EXIT_CODE%
>> "%LOG_PATH%" echo.
>> "%LOG_PATH%" echo [B07] run_all summary snapshot
>> "%LOG_PATH%" echo [B07] Total: %TOTAL_VALUE%
>> "%LOG_PATH%" echo [B07] Passed: %PASSED_VALUE%
>> "%LOG_PATH%" echo [B07] Failed: %FAILED_VALUE%

type "%LOG_PATH%"
del /q "%TMP_OUT%" >nul 2>nul
exit /b %GATE_EXIT_CODE%

:run_gate_step
set /a TOTAL_VALUE+=1
set "STEP_TITLE=%~1"
shift
>> "%TMP_OUT%" echo [GATE] %TOTAL_VALUE%/3 %STEP_TITLE%
call "%SELF%" %* >> "%TMP_OUT%" 2>&1
set "STEP_RC=%ERRORLEVEL%"
if "%STEP_RC%"=="0" (
  set /a PASSED_VALUE+=1
) else (
  set /a FAILED_VALUE+=1
)
exit /b %STEP_RC%
