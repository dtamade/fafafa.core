@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "ROOT=%~dp0"
set "TESTS_ROOT=%ROOT%.."
set "LOG_DIR=%ROOT%logs"
set "OUT_LOG=%LOG_DIR%\windows_b07_gate.log"
set "SUMMARY_FILE=%TESTS_ROOT%\run_all_tests_summary.txt"
set "CMD_VER="

if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"
for /f "delims=" %%V in ('ver') do set "CMD_VER=%%V"
if "%CMD_VER%"=="" set "CMD_VER=unknown"

echo [B07] Windows evidence capture > "%OUT_LOG%"
echo [B07] Source: collect_windows_b07_evidence.bat >> "%OUT_LOG%"
echo [B07] HostOS: %OS% >> "%OUT_LOG%"
echo [B07] CmdVer: %CMD_VER% >> "%OUT_LOG%"
echo [B07] Started: %DATE% %TIME% >> "%OUT_LOG%"
echo [B07] Working dir: %ROOT% >> "%OUT_LOG%"
echo [B07] Command: buildOrTest.bat gate >> "%OUT_LOG%"
echo. >> "%OUT_LOG%"

call "%ROOT%buildOrTest.bat" gate >> "%OUT_LOG%" 2>&1
set "GATE_RC=%ERRORLEVEL%"

echo. >> "%OUT_LOG%"
echo [B07] GATE_EXIT_CODE=%GATE_RC% >> "%OUT_LOG%"

if exist "%SUMMARY_FILE%" (
  echo. >> "%OUT_LOG%"
  echo [B07] run_all summary snapshot >> "%OUT_LOG%"
  type "%SUMMARY_FILE%" >> "%OUT_LOG%"
)

for /f "tokens=1,* delims=:" %%A in ('findstr /r /c:"^Total:" /c:"^Passed:" /c:"^Failed:" "%OUT_LOG%"') do (
  set "K=%%A"
  set "V=%%B"
  set "V=!V:~1!"
  echo [B07] %%A: !V!>> "%OUT_LOG%"
)

echo [B07] Evidence log: %OUT_LOG%
type "%OUT_LOG%"

exit /b %GATE_RC%
