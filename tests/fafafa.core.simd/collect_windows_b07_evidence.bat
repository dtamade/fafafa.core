@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "ROOT=%~dp0"
set "TESTS_ROOT=%ROOT%.."
set "LOG_DIR=%ROOT%logs"
set "OUT_LOG=%LOG_DIR%\windows_b07_gate.log"
set "SUMMARY_JSON=%LOG_DIR%\gate_summary.json"
set "SUMMARY_EXPORT_LOG=%LOG_DIR%\windows_b07_gate_summary_export.log"
set "SUMMARY_FILE=%TESTS_ROOT%\run_all_tests_summary.txt"
set "CMD_VER="
set "GATE_MODE=%SIMD_WIN_EVIDENCE_GATE_MODE%"
if "%GATE_MODE%"=="" set "GATE_MODE=sh"
set "GATE_COMMAND_MARKER=buildOrTest.bat gate"
if /I "%GATE_MODE%"=="sh" set "GATE_COMMAND_MARKER=BuildOrTest.sh gate"

if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"
for /f "delims=" %%V in ('ver') do set "CMD_VER=%%V"
if "%CMD_VER%"=="" set "CMD_VER=unknown"

echo [B07] Windows evidence capture > "%OUT_LOG%"
echo [B07] Source: collect_windows_b07_evidence.bat >> "%OUT_LOG%"
echo [B07] HostOS: %OS% >> "%OUT_LOG%"
echo [B07] CmdVer: %CMD_VER% >> "%OUT_LOG%"
echo [B07] Started: %DATE% %TIME% >> "%OUT_LOG%"
echo [B07] Working dir: %ROOT% >> "%OUT_LOG%"
echo [B07] Command: %GATE_COMMAND_MARKER% >> "%OUT_LOG%"
echo. >> "%OUT_LOG%"

if /I "%GATE_MODE%"=="sh" (
  where bash >nul 2>nul
  if errorlevel 1 (
    echo [B07] Missing bash for sh gate mode >> "%OUT_LOG%"
    exit /b 2
  )
  pushd "%ROOT%"
  bash "./BuildOrTest.sh" gate >> "%OUT_LOG%" 2>&1
  set "GATE_RC=%ERRORLEVEL%"
  popd
  set "SUMMARY_FILE=%TESTS_ROOT%\run_all_tests_summary_sh.txt"
) else (
  call "%ROOT%buildOrTest.bat" gate >> "%OUT_LOG%" 2>&1
  set "GATE_RC=%ERRORLEVEL%"
)

if exist "%SUMMARY_JSON%" del /f /q "%SUMMARY_JSON%" >nul 2>nul
if /I "%GATE_MODE%"=="sh" (
  pushd "%ROOT%"
  set "SIMD_GATE_SUMMARY_JSON=1"
  bash "./BuildOrTest.sh" gate-summary > "%SUMMARY_EXPORT_LOG%" 2>&1
  set "SUMMARY_RC=%ERRORLEVEL%"
  popd
) else (
  set "SIMD_GATE_SUMMARY_JSON=1"
  call "%ROOT%buildOrTest.bat" gate-summary > "%SUMMARY_EXPORT_LOG%" 2>&1
  set "SUMMARY_RC=%ERRORLEVEL%"
)
if exist "%SUMMARY_JSON%" (
  echo [B07] GateSummaryJson: %SUMMARY_JSON% >> "%OUT_LOG%"
) else (
  echo [B07] GateSummaryJson: missing >> "%OUT_LOG%"
)
echo [B07] GateSummaryExportRc: %SUMMARY_RC% >> "%OUT_LOG%"

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
