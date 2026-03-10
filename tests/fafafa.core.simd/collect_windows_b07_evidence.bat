@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "ROOT=%~dp0"
set "TESTS_ROOT=%ROOT%.."
set "LOG_DIR=%ROOT%logs"
set "OUT_LOG=%LOG_DIR%\windows_b07_gate.log"
set "SUMMARY_JSON=%LOG_DIR%\gate_summary.json"
set "SUMMARY_EXPORT_LOG=%LOG_DIR%\windows_b07_gate_summary_export.log"
set "SUMMARY_FILE=%TESTS_ROOT%\run_all_tests_summary.txt"
set "RUNALL_TOTAL=0"
set "RUNALL_PASSED=0"
set "RUNALL_FAILED=0"
set "RUNALL_FAILED_LIST="
set "BIN=%ROOT%bin2\fafafa.core.simd.test.exe"
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
set "BUILD_STEP_RC=%ERRORLEVEL%"
if not exist "%BIN%" (
  set "GATE_RC=1"
  goto :after_gate
)
findstr /c:"Fatal:" /c:"returned an error exitcode" "%ROOT%logs\build.txt" >nul 2>nul
if not errorlevel 1 (
  set "GATE_RC=1"
  goto :after_gate
)
if not "%BUILD_STEP_RC%"=="0" (
  echo [B07] WARN: build command returned rc=%BUILD_STEP_RC% but artifact and build log look usable >> "%OUT_LOG%"
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
if not exist "%BIN%" (
  set "GATE_RC=1"
  goto :after_gate
)
"%BIN%" --list-suites >> "%OUT_LOG%" 2>&1
if errorlevel 1 (
  set "GATE_RC=1"
  goto :after_gate
)

echo [GATE] 3/6 SIMD AVX2 fallback suite >> "%OUT_LOG%"
"%BIN%" --suite=TTestCase_VecI32x8 >> "%OUT_LOG%" 2>&1
if errorlevel 1 set "GATE_RC=1"
if not "%GATE_RC%"=="0" goto :after_gate
"%BIN%" --suite=TTestCase_VecU32x8 >> "%OUT_LOG%" 2>&1
if errorlevel 1 set "GATE_RC=1"
if not "%GATE_RC%"=="0" goto :after_gate
"%BIN%" --suite=TTestCase_VecF64x4 >> "%OUT_LOG%" 2>&1
if errorlevel 1 (
  set "GATE_RC=1"
  goto :after_gate
)

echo [GATE] 4/6 CPUInfo portable suites >> "%OUT_LOG%"
pushd "%TESTS_ROOT%\fafafa.core.simd.cpuinfo"
call ".\buildOrTest.bat" build >> "%OUT_LOG%" 2>&1
if errorlevel 1 set "GATE_RC=1"
if not "%GATE_RC%"=="0" (
  popd
  goto :after_gate
)
if not exist ".\bin\fafafa.core.simd.cpuinfo.test.exe" (
  set "GATE_RC=1"
  popd
  goto :after_gate
)
".\bin\fafafa.core.simd.cpuinfo.test.exe" --list >> "%OUT_LOG%" 2>&1
if errorlevel 1 (
  set "GATE_RC=1"
  popd
  goto :after_gate
)
".\bin\fafafa.core.simd.cpuinfo.test.exe" --suite=TTestCase_PlatformSpecific >> "%OUT_LOG%" 2>&1
if errorlevel 1 (
  set "GATE_RC=1"
  popd
  goto :after_gate
)
popd

echo [GATE] 5/6 CPUInfo x86 suites >> "%OUT_LOG%"
pushd "%TESTS_ROOT%\fafafa.core.simd.cpuinfo.x86"
call ".\buildOrTest.bat" build >> "%OUT_LOG%" 2>&1
if errorlevel 1 set "GATE_RC=1"
if not "%GATE_RC%"=="0" (
  popd
  goto :after_gate
)
if not exist ".\bin\fafafa.core.simd.cpuinfo.x86.test.exe" (
  set "GATE_RC=1"
  popd
  goto :after_gate
)
".\bin\fafafa.core.simd.cpuinfo.x86.test.exe" --list >> "%OUT_LOG%" 2>&1
if errorlevel 1 (
  set "GATE_RC=1"
  popd
  goto :after_gate
)
".\bin\fafafa.core.simd.cpuinfo.x86.test.exe" --suite=TTestCase_Global >> "%OUT_LOG%" 2>&1
if errorlevel 1 (
  set "GATE_RC=1"
  popd
  goto :after_gate
)
popd

echo [GATE] 6/6 Filtered run_all chain >> "%OUT_LOG%"
call :run_windows_evidence_step "fafafa.core.simd" "%ROOT%buildOrTest.bat" check >> "%OUT_LOG%" 2>&1
call :run_windows_evidence_step "fafafa.core.simd.cpuinfo" "%TESTS_ROOT%\fafafa.core.simd.cpuinfo\buildOrTest.bat" check >> "%OUT_LOG%" 2>&1
call :run_windows_evidence_step "fafafa.core.simd.cpuinfo.x86" "%TESTS_ROOT%\fafafa.core.simd.cpuinfo.x86\buildOrTest.bat" check >> "%OUT_LOG%" 2>&1
call :run_windows_evidence_step "fafafa.core.simd.intrinsics.sse" "%TESTS_ROOT%\fafafa.core.simd.intrinsics.sse\buildOrTest.bat" check >> "%OUT_LOG%" 2>&1
call :run_windows_evidence_step "fafafa.core.simd.intrinsics.mmx" "%TESTS_ROOT%\fafafa.core.simd.intrinsics.mmx\buildOrTest.bat" check >> "%OUT_LOG%" 2>&1

>"%SUMMARY_FILE%" (
  echo ========================================
  echo Run-all summary ^(%DATE% %TIME%^)
  echo Logs dir: %LOG_DIR%
  echo ========================================
  echo Total:  %RUNALL_TOTAL%
  echo Passed: %RUNALL_PASSED%
  echo Failed: %RUNALL_FAILED%
  if defined RUNALL_FAILED_LIST echo Failed modules: %RUNALL_FAILED_LIST%
)
type "%SUMMARY_FILE%" >> "%OUT_LOG%"
if not "%RUNALL_FAILED%"=="0" (
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

:run_windows_evidence_step
set "STEP_NAME=%~1"
set "STEP_SCRIPT=%~2"
set "STEP_ACTION=%~3"
set /a RUNALL_TOTAL+=1
call "%STEP_SCRIPT%" %STEP_ACTION%
if errorlevel 1 (
  set /a RUNALL_FAILED+=1
  echo [FAIL] %STEP_NAME% ^(rc=%ERRORLEVEL%^)
  if defined RUNALL_FAILED_LIST (
    set "RUNALL_FAILED_LIST=%RUNALL_FAILED_LIST%,%STEP_NAME%"
  ) else (
    set "RUNALL_FAILED_LIST=%STEP_NAME%"
  )
) else (
  set /a RUNALL_PASSED+=1
  echo [PASS] %STEP_NAME% ^(rc=0^)
)
exit /b 0
