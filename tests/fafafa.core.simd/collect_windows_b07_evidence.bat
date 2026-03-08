@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "ROOT=%SIMD_SCRIPT_ROOT%"
if "%ROOT%"=="" set "ROOT=%~dp0"
if not "%ROOT%"=="" if not "%ROOT:~-1%"=="\" set "ROOT=%ROOT%\"
if "%ROOT:~-1%"=="\" set "ROOT=%ROOT:~0,-1%"
set "LOG_DIR=%ROOT%\logs"
set "LOG_PATH=%SIMD_WIN_EVIDENCE_LOG_FILE%"
if "%LOG_PATH%"=="" set "LOG_PATH=%LOG_DIR%\windows_b07_gate.log"
set "SELF=%ROOT%\buildOrTest.bat"
set "SUMMARY_FILE=%ROOT%\..\run_all_tests_summary.txt"
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

call "%SELF%" gate > "%TMP_OUT%" 2>&1
set "GATE_EXIT_CODE=%ERRORLEVEL%"

type "%TMP_OUT%" >> "%LOG_PATH%"
>> "%LOG_PATH%" echo.
>> "%LOG_PATH%" echo [B07] GATE_EXIT_CODE=%GATE_EXIT_CODE%
>> "%LOG_PATH%" echo.
>> "%LOG_PATH%" echo [B07] run_all summary snapshot

set "TOTAL_VALUE=0"
set "PASSED_VALUE=0"
set "FAILED_VALUE=0"
if exist "%SUMMARY_FILE%" (
  for /f "usebackq delims=" %%L in (`findstr /R /C:"^Total:[ ]*[0-9][0-9]*$" /C:"^Passed:[ ]*[0-9][0-9]*$" /C:"^Failed:[ ]*[0-9][0-9]*$" "%SUMMARY_FILE%"`) do (
    >> "%LOG_PATH%" echo %%L
  )
  for /f "tokens=1,* delims=:" %%A in ('findstr /R /C:"^Total:[ ]*[0-9][0-9]*$" /C:"^Passed:[ ]*[0-9][0-9]*$" /C:"^Failed:[ ]*[0-9][0-9]*$" "%SUMMARY_FILE%"') do (
    set "LINE_KEY=%%A"
    set "LINE_VALUE=%%B"
    call :trim_line LINE_VALUE
    if /I "!LINE_KEY!"=="Total" set "TOTAL_VALUE=!LINE_VALUE!"
    if /I "!LINE_KEY!"=="Passed" set "PASSED_VALUE=!LINE_VALUE!"
    if /I "!LINE_KEY!"=="Failed" set "FAILED_VALUE=!LINE_VALUE!"
  )
)

>> "%LOG_PATH%" echo [B07] Total: %TOTAL_VALUE%
>> "%LOG_PATH%" echo [B07] Passed: %PASSED_VALUE%
>> "%LOG_PATH%" echo [B07] Failed: %FAILED_VALUE%

type "%LOG_PATH%"
del /q "%TMP_OUT%" >nul 2>nul
exit /b %GATE_EXIT_CODE%

:trim_line
setlocal EnableDelayedExpansion
set "VALUE=!%~1!"
for /f "tokens=* delims= " %%Z in ("!VALUE!") do set "VALUE=%%Z"
endlocal & set "%~1=%VALUE%"
exit /b 0
