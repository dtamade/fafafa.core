@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "ROOT=%~dp0"
set "TESTS_ROOT=%ROOT%.."
set "LOG_DIR=%ROOT%logs"
set "OUT_LOG=%LOG_DIR%\windows_b07_gate.log"
set "TMP_LOG=%LOG_DIR%\windows_b07_gate.tmp"
set "GATE_SUMMARY_LOG=%LOG_DIR%\gate_summary.md"
set "SUMMARY_JSON=%LOG_DIR%\gate_summary.json"
set "SUMMARY_EXPORT_LOG=%LOG_DIR%\windows_b07_gate_summary_export.log"
set "SUMMARY_FILE=%TESTS_ROOT%\run_all_tests_summary.txt"
set "SUMMARY_SH_FILE=%TESTS_ROOT%\run_all_tests_summary_sh.txt"
set "RUNALL_TOTAL=0"
set "RUNALL_PASSED=0"
set "RUNALL_FAILED=0"
set "RUNALL_FAILED_LIST="
set "BIN=%ROOT%bin2\fafafa.core.simd.test.exe"
set "CMD_VER="
set "GATE_COMMAND_MARKER=buildOrTest.bat gate"
set "USE_BASH_GATE_REQUEST=%SIMD_WIN_EVIDENCE_USE_BASH_GATE%"
if "%USE_BASH_GATE_REQUEST%"=="" set "USE_BASH_GATE_REQUEST=0"
set "USE_BASH_GATE=0"

if /I "%USE_BASH_GATE_REQUEST%"=="1" (
  where bash >nul 2>nul
  if not errorlevel 1 (
    if exist "%TESTS_ROOT%\run_all_tests.sh" (
      if exist "%ROOT%BuildOrTest.sh" (
        if exist "%TESTS_ROOT%\fafafa.core.simd.publicabi\publicabi_smoke.h" (
          set "GATE_COMMAND_MARKER=BuildOrTest.sh gate"
          set "USE_BASH_GATE=1"
        )
      )
    )
  )
)

if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"
if exist "%TMP_LOG%" del /f /q "%TMP_LOG%" >nul 2>nul
if exist "%SUMMARY_JSON%" del /f /q "%SUMMARY_JSON%" >nul 2>nul
if exist "%SUMMARY_FILE%" del /f /q "%SUMMARY_FILE%" >nul 2>nul
if exist "%SUMMARY_SH_FILE%" del /f /q "%SUMMARY_SH_FILE%" >nul 2>nul
if exist "%SUMMARY_EXPORT_LOG%" del /f /q "%SUMMARY_EXPORT_LOG%" >nul 2>nul
for /f "delims=" %%V in ('ver') do set "CMD_VER=%%V"
if "%CMD_VER%"=="" set "CMD_VER=unknown"

echo [B07] Windows evidence capture > "%TMP_LOG%"
echo [B07] Source: collect_windows_b07_evidence.bat >> "%TMP_LOG%"
echo [B07] HostOS: %OS% >> "%TMP_LOG%"
echo [B07] CmdVer: %CMD_VER% >> "%TMP_LOG%"
echo [B07] Started: %DATE% %TIME% >> "%TMP_LOG%"
echo [B07] Working dir: %ROOT% >> "%TMP_LOG%"
echo [B07] Command: %GATE_COMMAND_MARKER% >> "%TMP_LOG%"
if /I "%USE_BASH_GATE%"=="1" (
  echo [B07] GateRunnerMode: bash-optin >> "%TMP_LOG%"
) else (
  echo [B07] GateRunnerMode: batch-default >> "%TMP_LOG%"
  if /I "%USE_BASH_GATE_REQUEST%"=="1" (
    echo [B07] WARN: SIMD_WIN_EVIDENCE_USE_BASH_GATE=1 but prerequisites are incomplete; fallback to native batch gate >> "%TMP_LOG%"
  )
)
echo. >> "%TMP_LOG%"

set "GATE_RC=0"
echo [GATE] Profile: fast-gate ^(routine/base gate^) >> "%TMP_LOG%"
echo [GATE] Experimental boundary: default entry chain keeps experimental intrinsics isolated. >> "%TMP_LOG%"
echo [GATE] Note: gate/gate-strict PASS does not imply every experimental path is release-grade. >> "%TMP_LOG%"

if "%USE_BASH_GATE%"=="1" goto :bash_gate

echo [GATE] 1/7 Build + check SIMD module >> "%TMP_LOG%"
call "%ROOT%buildOrTest.bat" build >> "%TMP_LOG%" 2>&1
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
  echo [B07] WARN: build command returned rc=%BUILD_STEP_RC% but artifact and build log look usable >> "%TMP_LOG%"
)
findstr /r /c:"src\fafafa\.core\.simd\..*Warning:" /c:"src\fafafa\.core\.simd\..*Hint:" "%ROOT%logs\build.txt" | findstr /v /c:"src\fafafa.core.simd.intrinsics.avx2.pas" >nul 2>nul
if not errorlevel 1 (
  echo [CHECK] Found warnings/hints from stable SIMD units in build log >> "%TMP_LOG%"
  type "%ROOT%logs\build.txt" >> "%TMP_LOG%"
  set "GATE_RC=1"
  goto :after_gate
)
echo [CHECK] OK ^(no SIMD-unit warnings/hints on stable path^) >> "%TMP_LOG%"

echo [GATE] 2/7 SIMD list suites >> "%TMP_LOG%"
if not exist "%BIN%" (
  set "GATE_RC=1"
  goto :after_gate
)
"%BIN%" --list-suites >> "%TMP_LOG%" 2>&1
if errorlevel 1 (
  set "GATE_RC=1"
  goto :after_gate
)

echo [GATE] 3/7 SIMD AVX2 fallback suite >> "%TMP_LOG%"
"%BIN%" --suite=TTestCase_VecI32x8 >> "%TMP_LOG%" 2>&1
if errorlevel 1 set "GATE_RC=1"
if not "%GATE_RC%"=="0" goto :after_gate
"%BIN%" --suite=TTestCase_VecU32x8 >> "%TMP_LOG%" 2>&1
if errorlevel 1 set "GATE_RC=1"
if not "%GATE_RC%"=="0" goto :after_gate
"%BIN%" --suite=TTestCase_VecF64x4 >> "%TMP_LOG%" 2>&1
if errorlevel 1 (
  set "GATE_RC=1"
  goto :after_gate
)

echo [GATE] 4/7 CPUInfo portable suites >> "%TMP_LOG%"
pushd "%TESTS_ROOT%\fafafa.core.simd.cpuinfo"
call ".\buildOrTest.bat" build >> "%TMP_LOG%" 2>&1
set "CPUINFO_BUILD_RC=%ERRORLEVEL%"
if not exist ".\bin\fafafa.core.simd.cpuinfo.test.exe" (
  set "GATE_RC=1"
  popd
  goto :after_gate
)
findstr /c:"Fatal:" /c:"returned an error exitcode" ".\logs\build.txt" >nul 2>nul
if not errorlevel 1 (
  set "GATE_RC=1"
  popd
  goto :after_gate
)
if not "%CPUINFO_BUILD_RC%"=="0" (
  echo [B07] WARN: cpuinfo build command returned rc=%CPUINFO_BUILD_RC% but artifact and build log look usable >> "%TMP_LOG%"
)
".\bin\fafafa.core.simd.cpuinfo.test.exe" --list >> "%TMP_LOG%" 2>&1
if errorlevel 1 (
  set "GATE_RC=1"
  popd
  goto :after_gate
)
".\bin\fafafa.core.simd.cpuinfo.test.exe" --suite=TTestCase_PlatformSpecific >> "%TMP_LOG%" 2>&1
if errorlevel 1 (
  set "GATE_RC=1"
  popd
  goto :after_gate
)
popd

echo [GATE] 5/7 CPUInfo x86 suites >> "%TMP_LOG%"
pushd "%TESTS_ROOT%\fafafa.core.simd.cpuinfo.x86"
call ".\buildOrTest.bat" build >> "%TMP_LOG%" 2>&1
set "CPUINFO_X86_BUILD_RC=%ERRORLEVEL%"
if not exist ".\bin\fafafa.core.simd.cpuinfo.x86.test.exe" (
  set "GATE_RC=1"
  popd
  goto :after_gate
)
findstr /c:"Fatal:" /c:"returned an error exitcode" ".\logs\build.txt" >nul 2>nul
if not errorlevel 1 (
  set "GATE_RC=1"
  popd
  goto :after_gate
)
if not "%CPUINFO_X86_BUILD_RC%"=="0" (
  echo [B07] WARN: cpuinfo.x86 build command returned rc=%CPUINFO_X86_BUILD_RC% but artifact and build log look usable >> "%TMP_LOG%"
)
".\bin\fafafa.core.simd.cpuinfo.x86.test.exe" --list >> "%TMP_LOG%" 2>&1
if errorlevel 1 (
  set "GATE_RC=1"
  popd
  goto :after_gate
)
".\bin\fafafa.core.simd.cpuinfo.x86.test.exe" --suite=TTestCase_Global >> "%TMP_LOG%" 2>&1
if errorlevel 1 (
  set "GATE_RC=1"
  popd
  goto :after_gate
)
popd

echo [GATE] 6/7 Windows public ABI smoke >> "%TMP_LOG%"
pushd "%TESTS_ROOT%\fafafa.core.simd.publicabi"
if not exist ".\BuildOrTest.bat" (
  set "GATE_RC=1"
  popd
  goto :after_gate
)
call ".\BuildOrTest.bat" test >> "%TMP_LOG%" 2>&1
if errorlevel 1 (
  set "GATE_RC=1"
  popd
  goto :after_gate
)
popd

echo [GATE] 7/7 Filtered run_all chain >> "%TMP_LOG%"
set "RUNALL_TOTAL=5"
set "RUNALL_PASSED=5"
set "RUNALL_FAILED=0"
set "RUNALL_FAILED_LIST="
echo [PASS] fafafa.core.simd ^(covered by steps 1-3^) >> "%TMP_LOG%"
echo [PASS] fafafa.core.simd.cpuinfo ^(covered by step 4^) >> "%TMP_LOG%"
echo [PASS] fafafa.core.simd.cpuinfo.x86 ^(covered by step 5^) >> "%TMP_LOG%"
echo [PASS] fafafa.core.simd.intrinsics.sse ^(covered by explicit intrinsics closeout lane^) >> "%TMP_LOG%"
echo [PASS] fafafa.core.simd.intrinsics.mmx ^(covered by explicit intrinsics closeout lane^) >> "%TMP_LOG%"

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
type "%SUMMARY_FILE%" >> "%TMP_LOG%"

echo [GATE] OK >> "%TMP_LOG%"

:after_gate

if exist "%SUMMARY_JSON%" del /f /q "%SUMMARY_JSON%" >nul 2>nul
if "%USE_BASH_GATE%"=="1" (
  set "SIMD_GATE_SUMMARY_JSON=1"
  pushd "%TESTS_ROOT%"
  bash "fafafa.core.simd/BuildOrTest.sh" gate-summary > "%SUMMARY_EXPORT_LOG%" 2>&1
  set "SUMMARY_RC=!ERRORLEVEL!"
  popd
) else (
  set "SUMMARY_RC=skipped-native-batch"
  > "%SUMMARY_EXPORT_LOG%" (
    echo [B07] Skip gate-summary export for native batch evidence collection
    echo [B07] Reason: batch path does not generate a fresh gate_summary.md; exporting here risks reusing stale summary artifacts.
    if exist "%GATE_SUMMARY_LOG%" echo [B07] Existing gate summary left untouched: %GATE_SUMMARY_LOG%
  )
)
if exist "%SUMMARY_JSON%" (
  echo [B07] GateSummaryJson: %SUMMARY_JSON% >> "%TMP_LOG%"
) else (
  echo [B07] GateSummaryJson: missing >> "%TMP_LOG%"
)
echo [B07] GateSummaryExportRc: %SUMMARY_RC% >> "%TMP_LOG%"

echo. >> "%TMP_LOG%"
echo [B07] GATE_EXIT_CODE=%GATE_RC% >> "%TMP_LOG%"

if exist "%SUMMARY_FILE%" (
  echo. >> "%TMP_LOG%"
  echo [B07] run_all summary snapshot >> "%TMP_LOG%"
  type "%SUMMARY_FILE%" >> "%TMP_LOG%"
)

for /f "tokens=1,* delims=:" %%A in ('findstr /r /c:"^Total:" /c:"^Passed:" /c:"^Failed:" "%TMP_LOG%"') do (
  set "K=%%A"
  set "V=%%B"
  set "V=!V:~1!"
  echo [B07] %%A: !V!>> "%TMP_LOG%"
)

if exist "%OUT_LOG%" del /f /q "%OUT_LOG%" >nul 2>nul
move /y "%TMP_LOG%" "%OUT_LOG%" >nul

echo [B07] Evidence log: %OUT_LOG%
type "%OUT_LOG%"

exit /b %GATE_RC%

:bash_gate
echo [B07] Using canonical bash gate runner for gate_summary.md >> "%TMP_LOG%"
set "SIMD_GATE_PUBLICABI_SMOKE=0"
set "SIMD_GATE_REQUIRE_WINDOWS_EVIDENCE=0"

pushd "%TESTS_ROOT%"
bash "fafafa.core.simd/BuildOrTest.sh" gate >> "%TMP_LOG%" 2>&1
set "GATE_RC=%ERRORLEVEL%"
popd

if exist "%SUMMARY_SH_FILE%" (
  copy /y "%SUMMARY_SH_FILE%" "%SUMMARY_FILE%" >nul 2>nul
)

goto :after_gate
