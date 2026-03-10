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
set "GATE_COMMAND_MARKER=buildOrTest.bat gate"

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

set "GATE_RC=0"
echo [GATE] Profile: fast-gate ^(routine/base gate^) >> "%OUT_LOG%"
echo [GATE] Experimental boundary: default entry chain keeps experimental intrinsics isolated. >> "%OUT_LOG%"
echo [GATE] Note: gate/gate-strict PASS does not imply every experimental path is release-grade. >> "%OUT_LOG%"

echo [GATE] 1/6 Build + check SIMD module >> "%OUT_LOG%"
call "%ROOT%buildOrTest.bat" build >> "%OUT_LOG%" 2>&1
if errorlevel 1 (
  set "GATE_RC=1"
  goto :after_gate
)
findstr /r /c:"src\fafafa\.core\.simd\..*Warning:" /c:"src\fafafa\.core\.simd\..*Hint:" "%ROOT%logs\build.txt" | findstr /v /c:"src\fafafa.core.simd.intrinsics.avx2.pas" >nul 2>nul
if not errorlevel 1 (
  echo [CHECK] Found warnings/hints from stable SIMD units in build log >> "%OUT_LOG%"
  type "%ROOT%logs\build.txt" >> "%OUT_LOG%"
  set "GATE_RC=1"
  goto :after_gate
)
echo [CHECK] OK ^(no SIMD-unit warnings/hints on stable path^) >> "%OUT_LOG%"

echo [GATE] 2/6 SIMD list suites >> "%OUT_LOG%"
call "%ROOT%buildOrTest.bat" test --list-suites >> "%OUT_LOG%" 2>&1
if errorlevel 1 (
  set "GATE_RC=1"
  goto :after_gate
)

echo [GATE] 3/6 SIMD AVX2 fallback suite >> "%OUT_LOG%"
call "%ROOT%buildOrTest.bat" test --suite=TTestCase_VecI32x8 >> "%OUT_LOG%" 2>&1
if errorlevel 1 set "GATE_RC=1"
if not "%GATE_RC%"=="0" goto :after_gate
call "%ROOT%buildOrTest.bat" test --suite=TTestCase_VecU32x8 >> "%OUT_LOG%" 2>&1
if errorlevel 1 set "GATE_RC=1"
if not "%GATE_RC%"=="0" goto :after_gate
call "%ROOT%buildOrTest.bat" test --suite=TTestCase_VecF64x4 >> "%OUT_LOG%" 2>&1
if errorlevel 1 (
  set "GATE_RC=1"
  goto :after_gate
)

echo [GATE] 4/6 CPUInfo portable suites >> "%OUT_LOG%"
call "%TESTS_ROOT%\fafafa.core.simd.cpuinfo\buildOrTest.bat" test --list-suites >> "%OUT_LOG%" 2>&1
if errorlevel 1 set "GATE_RC=1"
if not "%GATE_RC%"=="0" goto :after_gate
call "%TESTS_ROOT%\fafafa.core.simd.cpuinfo\buildOrTest.bat" test --suite=TTestCase_PlatformSpecific >> "%OUT_LOG%" 2>&1
if errorlevel 1 (
  set "GATE_RC=1"
  goto :after_gate
)

echo [GATE] 5/6 CPUInfo x86 suites >> "%OUT_LOG%"
call "%TESTS_ROOT%\fafafa.core.simd.cpuinfo.x86\buildOrTest.bat" test --list-suites >> "%OUT_LOG%" 2>&1
if errorlevel 1 set "GATE_RC=1"
if not "%GATE_RC%"=="0" goto :after_gate
call "%TESTS_ROOT%\fafafa.core.simd.cpuinfo.x86\buildOrTest.bat" test --suite=TTestCase_Global >> "%OUT_LOG%" 2>&1
if errorlevel 1 (
  set "GATE_RC=1"
  goto :after_gate
)

echo [GATE] 6/6 Filtered run_all chain >> "%OUT_LOG%"
set "STOP_ON_FAIL=1"
set "RUN_ACTION=check"
call "%TESTS_ROOT%\run_all_tests.bat" =fafafa.core.simd =fafafa.core.simd.cpuinfo =fafafa.core.simd.cpuinfo.x86 =fafafa.core.simd.intrinsics.sse =fafafa.core.simd.intrinsics.mmx >> "%OUT_LOG%" 2>&1
if errorlevel 1 (
  set "GATE_RC=1"
  goto :after_gate
)

echo [GATE] OK >> "%OUT_LOG%"

:after_gate

if exist "%SUMMARY_JSON%" del /f /q "%SUMMARY_JSON%" >nul 2>nul
set "SIMD_GATE_SUMMARY_JSON=1"
call "%ROOT%buildOrTest.bat" gate-summary > "%SUMMARY_EXPORT_LOG%" 2>&1
set "SUMMARY_RC=%ERRORLEVEL%"
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
