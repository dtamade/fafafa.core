@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "ACTION=%~1"
if "%ACTION%"=="" set "ACTION=test"
if not "%~1"=="" shift

set "NORMALIZED_TEST_ARGS="
:collect_args
if "%~1"=="" goto :args_done
if /I "%~1"=="--list" (
  set "NORMALIZED_TEST_ARGS=!NORMALIZED_TEST_ARGS! --list-suites"
) else (
  set "NORMALIZED_TEST_ARGS=!NORMALIZED_TEST_ARGS! %~1"
)
shift
goto :collect_args
:args_done

set "ROOT=%~dp0"
set "PROJ=%ROOT%fafafa.core.simd.test.lpi"
set "BIN_DIR=%ROOT%bin2"
set "LIB_DIR=%ROOT%lib2"
set "BIN=%BIN_DIR%\fafafa.core.simd.test.exe"
set "LOG_DIR=%ROOT%logs"
set "BUILD_LOG=%LOG_DIR%\build.txt"
set "TEST_LOG=%LOG_DIR%\test.txt"
set "GATE_SUMMARY_LOG=%LOG_DIR%\gate_summary.md"
set "GATE_SUMMARY_JSON_LOG=%LOG_DIR%\gate_summary.json"

if not exist "%BIN_DIR%" mkdir "%BIN_DIR%"
if not exist "%LIB_DIR%" mkdir "%LIB_DIR%"
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

set "LAZBUILD_EXE=%LAZBUILD%"
if "%LAZBUILD_EXE%"=="" set "LAZBUILD_EXE=%ProgramFiles%\Lazarus\lazbuild.exe"
if not exist "%LAZBUILD_EXE%" set "LAZBUILD_EXE=lazbuild"

set "MODE=%FAFAFA_BUILD_MODE%"
if "%MODE%"=="" set "MODE=Debug"

if /I "%ACTION%"=="clean" goto :clean
if /I "%ACTION%"=="build" goto :build
if /I "%ACTION%"=="check" goto :check
if /I "%ACTION%"=="test" goto :test
if /I "%ACTION%"=="test-concurrent-repeat" goto :test_concurrent_repeat
if /I "%ACTION%"=="debug" (
  set "MODE=Debug"
  goto :test
)
if /I "%ACTION%"=="release" (
  set "MODE=Release"
  goto :test
)
if /I "%ACTION%"=="gate" goto :gate
if /I "%ACTION%"=="gate-strict" goto :gate_strict
if /I "%ACTION%"=="interface-completeness" goto :interface_completeness
if /I "%ACTION%"=="adapter-sync-pascal" goto :adapter_sync_pascal
if /I "%ACTION%"=="adapter-sync" goto :adapter_sync
if /I "%ACTION%"=="parity-suites" goto :parity_suites
if /I "%ACTION%"=="gate-summary" goto :gate_summary
if /I "%ACTION%"=="gate-summary-sample" goto :gate_summary_sample
if /I "%ACTION%"=="gate-summary-rehearsal" goto :gate_summary_rehearsal
if /I "%ACTION%"=="gate-summary-inject" goto :gate_summary_inject
if /I "%ACTION%"=="gate-summary-rollback" goto :gate_summary_rollback
if /I "%ACTION%"=="gate-summary-backups" goto :gate_summary_backups
if /I "%ACTION%"=="perf-smoke" goto :perf_smoke
if /I "%ACTION%"=="nonx86-ieee754" goto :nonx86_ieee754
if /I "%ACTION%"=="backend-bench" goto :backend_bench
if /I "%ACTION%"=="qemu-nonx86-evidence" goto :qemu_nonx86_evidence
if /I "%ACTION%"=="qemu-arch-matrix-evidence" goto :qemu_arch_matrix_evidence
if /I "%ACTION%"=="qemu-nonx86-experimental-asm" goto :qemu_nonx86_experimental_asm
if /I "%ACTION%"=="riscvv-opcode-lane" goto :riscvv_opcode_lane
if /I "%ACTION%"=="qemu-experimental-report" goto :qemu_experimental_report
if /I "%ACTION%"=="qemu-experimental-baseline-check" goto :qemu_experimental_baseline_check
if /I "%ACTION%"=="coverage" goto :coverage
if /I "%ACTION%"=="wiring-sync" goto :wiring_sync
if /I "%ACTION%"=="experimental-intrinsics" goto :experimental_intrinsics
if /I "%ACTION%"=="experimental-intrinsics-tests" goto :experimental_intrinsics_tests
if /I "%ACTION%"=="evidence-win" goto :evidence_win
if /I "%ACTION%"=="verify-win-evidence" goto :verify_win_evidence
if /I "%ACTION%"=="evidence-win-verify" goto :evidence_win_verify

echo Usage: %~nx0 [clean^|build^|check^|test^|test-concurrent-repeat^|debug^|release^|gate^|gate-strict^|interface-completeness^|adapter-sync-pascal^|adapter-sync^|parity-suites^|gate-summary^|gate-summary-sample^|gate-summary-rehearsal^|gate-summary-inject^|gate-summary-rollback^|gate-summary-backups^|perf-smoke^|nonx86-ieee754^|backend-bench^|qemu-nonx86-evidence^|qemu-arch-matrix-evidence^|qemu-nonx86-experimental-asm^|qemu-experimental-report^|qemu-experimental-baseline-check^|coverage^|wiring-sync^|experimental-intrinsics^|experimental-intrinsics-tests^|evidence-win^|verify-win-evidence^|evidence-win-verify] [test-args...]
echo QEMU env: SIMD_QEMU_BUILD_POLICY=always^|if-missing^|skip ^(default: if-missing^)
exit /b 2

:clean
echo [CLEAN] Removing bin2, lib2, logs
if exist "%BIN_DIR%" rmdir /s /q "%BIN_DIR%"
if exist "%LIB_DIR%" rmdir /s /q "%LIB_DIR%"
if exist "%LOG_DIR%" rmdir /s /q "%LOG_DIR%"
exit /b 0

:build
echo [BUILD] Project: %PROJ% (mode=%MODE%)
echo. > "%BUILD_LOG%"
"%LAZBUILD_EXE%" --build-mode=%MODE% --build-all "%PROJ%" > "%BUILD_LOG%" 2>&1
if errorlevel 1 (
  echo [BUILD] FAILED (see %BUILD_LOG%)
  type "%BUILD_LOG%"
  exit /b 1
)
if not exist "%BIN%" (
  echo [BUILD] FAILED ^(binary missing after build: %BIN%^)
  type "%BUILD_LOG%"
  exit /b 1
)
echo [BUILD] OK
exit /b 0

:check
call :build
if errorlevel 1 exit /b 1
findstr /r /c:"src\\fafafa\.core\.simd\..*Warning:" /c:"src\\fafafa\.core\.simd\..*Hint:" "%BUILD_LOG%" >nul 2>nul
if not errorlevel 1 (
  echo [CHECK] Found warnings/hints from SIMD units in build log
  type "%BUILD_LOG%"
  exit /b 1
)
echo [CHECK] OK (no SIMD-unit warnings/hints)

if /I "%SIMD_CHECK_WIRING_SYNC%"=="1" (
  echo [CHECK] Optional wiring-sync enabled
  call "%~f0" wiring-sync
  if errorlevel 1 exit /b 1
) else (
  echo [CHECK] SKIP optional wiring-sync ^(set SIMD_CHECK_WIRING_SYNC=1 to enable^)
)

if /I "%SIMD_CHECK_EXPERIMENTAL%"=="0" (
  echo [CHECK] SKIP optional experimental isolation ^(set SIMD_CHECK_EXPERIMENTAL=1 to enable^)
) else (
  echo [CHECK] Experimental intrinsics isolation
  call "%~f0" experimental-intrinsics
  if errorlevel 1 exit /b 1
)

exit /b 0

:interface_completeness
set "INTERFACE_SCRIPT=%ROOT%check_interface_implementation_completeness.py"
if not exist "%INTERFACE_SCRIPT%" (
  echo [INTERFACE-CHECK] Missing checker: %INTERFACE_SCRIPT%
  exit /b 2
)
if "%SIMD_INTERFACE_COMPLETENESS_STRICT_LEVEL%"=="" set "SIMD_INTERFACE_COMPLETENESS_STRICT_LEVEL=p2"
if "%SIMD_INTERFACE_COMPLETENESS_JSON_FILE%"=="" set "SIMD_INTERFACE_COMPLETENESS_JSON_FILE=%LOG_DIR%\interface_completeness.json"
if "%SIMD_INTERFACE_COMPLETENESS_MD_FILE%"=="" set "SIMD_INTERFACE_COMPLETENESS_MD_FILE=%ROOT%docs\interface_implementation_completeness.md"

where py >nul 2>nul
if not errorlevel 1 (
  echo [INTERFACE-CHECK] Running: py -3 %INTERFACE_SCRIPT% --strict --strict-level "%SIMD_INTERFACE_COMPLETENESS_STRICT_LEVEL%" --json-file "%SIMD_INTERFACE_COMPLETENESS_JSON_FILE%" --md-file "%SIMD_INTERFACE_COMPLETENESS_MD_FILE%"
  py -3 "%INTERFACE_SCRIPT%" --strict --strict-level "%SIMD_INTERFACE_COMPLETENESS_STRICT_LEVEL%" --json-file "%SIMD_INTERFACE_COMPLETENESS_JSON_FILE%" --md-file "%SIMD_INTERFACE_COMPLETENESS_MD_FILE%"
  exit /b %ERRORLEVEL%
)

where python >nul 2>nul
if not errorlevel 1 (
  echo [INTERFACE-CHECK] Running: python %INTERFACE_SCRIPT% --strict --strict-level "%SIMD_INTERFACE_COMPLETENESS_STRICT_LEVEL%" --json-file "%SIMD_INTERFACE_COMPLETENESS_JSON_FILE%" --md-file "%SIMD_INTERFACE_COMPLETENESS_MD_FILE%"
  python "%INTERFACE_SCRIPT%" --strict --strict-level "%SIMD_INTERFACE_COMPLETENESS_STRICT_LEVEL%" --json-file "%SIMD_INTERFACE_COMPLETENESS_JSON_FILE%" --md-file "%SIMD_INTERFACE_COMPLETENESS_MD_FILE%"
  exit /b %ERRORLEVEL%
)

echo [INTERFACE-CHECK] SKIP (python runtime not found)
exit /b 0

:adapter_sync_pascal
echo [ADAPTER-SYNC-PASCAL] suite=TTestCase_DispatchAllSlots
call "%~f0" test --suite=TTestCase_DispatchAllSlots
if errorlevel 1 exit /b 1
exit /b 0

:adapter_sync
if /I "%SIMD_ADAPTER_SYNC_PASCAL_SMOKE%"=="0" (
  echo [ADAPTER-SYNC] SKIP Pascal smoke ^(SIMD_ADAPTER_SYNC_PASCAL_SMOKE=0^)
) else (
  call :adapter_sync_pascal
  if errorlevel 1 exit /b 1
)

set "ADAPTER_SYNC_SCRIPT=%ROOT%check_backend_adapter_sync.py"
if not exist "%ADAPTER_SYNC_SCRIPT%" (
  echo [ADAPTER-SYNC] Missing checker: %ADAPTER_SYNC_SCRIPT%
  exit /b 2
)

set "ADAPTER_SYNC_NO_STRICT="
if /I "%SIMD_ADAPTER_SYNC_STRICT%"=="0" set "ADAPTER_SYNC_NO_STRICT=--no-strict"

where py >nul 2>nul
if not errorlevel 1 (
  echo [ADAPTER-SYNC] Running: py -3 %ADAPTER_SYNC_SCRIPT% --summary-line %ADAPTER_SYNC_NO_STRICT%
  py -3 "%ADAPTER_SYNC_SCRIPT%" --summary-line %ADAPTER_SYNC_NO_STRICT%
  exit /b %ERRORLEVEL%
)

where python >nul 2>nul
if not errorlevel 1 (
  echo [ADAPTER-SYNC] Running: python %ADAPTER_SYNC_SCRIPT% --summary-line %ADAPTER_SYNC_NO_STRICT%
  python "%ADAPTER_SYNC_SCRIPT%" --summary-line %ADAPTER_SYNC_NO_STRICT%
  exit /b %ERRORLEVEL%
)

echo [ADAPTER-SYNC] SKIP (python runtime not found)
exit /b 0

:parity_suites
call "%~f0" test --suite=TTestCase_DispatchAllSlots
if errorlevel 1 exit /b 1
call "%~f0" test --suite=TTestCase_DispatchAPI
if errorlevel 1 exit /b 1
echo [PARITY] OK
exit /b 0

:coverage
set "COVERAGE_SCRIPT=%ROOT%check_intrinsics_coverage.py"
set "COVERAGE_ARGS="
if /I "%SIMD_COVERAGE_STRICT_EXTRA%"=="1" set "COVERAGE_ARGS=%COVERAGE_ARGS% --strict-extra"
if /I "%SIMD_COVERAGE_REQUIRE_AVX2%"=="1" set "COVERAGE_ARGS=%COVERAGE_ARGS% --require-avx2"
if /I "%SIMD_COVERAGE_REQUIRE_EXPERIMENTAL%"=="1" set "COVERAGE_ARGS=%COVERAGE_ARGS% --require-experimental"
if not exist "%COVERAGE_SCRIPT%" (
  echo [COVERAGE] Missing checker: %COVERAGE_SCRIPT%
  exit /b 2
)

where py >nul 2>nul
if not errorlevel 1 (
  echo [COVERAGE] Running: py -3 %COVERAGE_SCRIPT% %COVERAGE_ARGS%
  py -3 "%COVERAGE_SCRIPT%" %COVERAGE_ARGS%
  exit /b %ERRORLEVEL%
)

where python >nul 2>nul
if not errorlevel 1 (
  echo [COVERAGE] Running: python %COVERAGE_SCRIPT% %COVERAGE_ARGS%
  python "%COVERAGE_SCRIPT%" %COVERAGE_ARGS%
  exit /b %ERRORLEVEL%
)

echo [COVERAGE] SKIP (python runtime not found)
exit /b 0


:experimental_intrinsics
set "EXPERIMENTAL_SCRIPT=%ROOT%check_intrinsics_experimental_status.py"
if not exist "%EXPERIMENTAL_SCRIPT%" (
  echo [EXPERIMENTAL] Missing checker: %EXPERIMENTAL_SCRIPT%
  exit /b 2
)

where py >nul 2>nul
if not errorlevel 1 (
  echo [EXPERIMENTAL] Running: py -3 %EXPERIMENTAL_SCRIPT%
  py -3 "%EXPERIMENTAL_SCRIPT%"
  exit /b %ERRORLEVEL%
)

where python >nul 2>nul
if not errorlevel 1 (
  echo [EXPERIMENTAL] Running: python %EXPERIMENTAL_SCRIPT%
  python "%EXPERIMENTAL_SCRIPT%"
  exit /b %ERRORLEVEL%
)

echo [EXPERIMENTAL] SKIP (python runtime not found)
exit /b 0

:experimental_intrinsics_tests
set "EXPERIMENTAL_TESTS_RUNNER=%ROOT%..\fafafa.core.simd.intrinsics.experimental\BuildOrTest.sh"
if not exist "%EXPERIMENTAL_TESTS_RUNNER%" (
  echo [EXPERIMENTAL-TESTS] Missing runner: %EXPERIMENTAL_TESTS_RUNNER%
  exit /b 2
)
where bash >nul 2>nul
if errorlevel 1 (
  echo [EXPERIMENTAL-TESTS] SKIP (bash not found)
  exit /b 0
)
echo [EXPERIMENTAL-TESTS] Running: bash %EXPERIMENTAL_TESTS_RUNNER% test-all
bash "%EXPERIMENTAL_TESTS_RUNNER%" test-all
exit /b %ERRORLEVEL%


:wiring_sync
set "WIRING_SYNC_SCRIPT=%ROOT%check_nonx86_wiring_sync.py"
set "WIRING_SYNC_ARGS="
if /I "%SIMD_WIRING_SYNC_STRICT_EXTRA%"=="1" set "WIRING_SYNC_ARGS=--strict-extra"
if not exist "%WIRING_SYNC_SCRIPT%" (
  echo [WIRING-SYNC] Missing checker: %WIRING_SYNC_SCRIPT%
  exit /b 2
)

where py >nul 2>nul
if not errorlevel 1 (
  echo [WIRING-SYNC] Running: py -3 %WIRING_SYNC_SCRIPT% %WIRING_SYNC_ARGS%
  py -3 "%WIRING_SYNC_SCRIPT%" %WIRING_SYNC_ARGS%
  exit /b %ERRORLEVEL%
)

where python >nul 2>nul
if not errorlevel 1 (
  echo [WIRING-SYNC] Running: python %WIRING_SYNC_SCRIPT% %WIRING_SYNC_ARGS%
  python "%WIRING_SYNC_SCRIPT%" %WIRING_SYNC_ARGS%
  exit /b %ERRORLEVEL%
)

echo [WIRING-SYNC] SKIP (python runtime not found)
exit /b 0

:check_heap_leaks
findstr /r /c:"^[1-9][0-9]* unfreed memory blocks" "%TEST_LOG%" >nul 2>nul
if not errorlevel 1 (
  echo [LEAK] FAILED: heaptrc reports unfreed blocks
  type "%TEST_LOG%"
  exit /b 1
)
echo [LEAK] OK
exit /b 0

:test
call :build
if errorlevel 1 exit /b 1

if not exist "%BIN%" (
  echo [TEST] Missing binary: %BIN%
  exit /b 2
)

echo [TEST] Running: %BIN%%NORMALIZED_TEST_ARGS%
echo. > "%TEST_LOG%"
"%BIN%" %NORMALIZED_TEST_ARGS% > "%TEST_LOG%" 2>&1
if errorlevel 1 (
  echo [TEST] FAILED (see %TEST_LOG%)
  type "%TEST_LOG%"
  exit /b 1
)
findstr /b /c:"Invalid option" "%TEST_LOG%" >nul 2>nul
if not errorlevel 1 (
  echo [TEST] FAILED: unsupported test argument (see %TEST_LOG%)
  type "%TEST_LOG%"
  exit /b 2
)
echo [TEST] OK

call :check_heap_leaks
exit /b %ERRORLEVEL%

:test_concurrent_repeat
set "REPEAT_ROUNDS="
for /f "tokens=1" %%R in ("%NORMALIZED_TEST_ARGS%") do set "REPEAT_ROUNDS=%%R"
if "%REPEAT_ROUNDS%"=="" set "REPEAT_ROUNDS=%SIMD_CONCURRENT_REPEAT_ROUNDS%"
if "%REPEAT_ROUNDS%"=="" set "REPEAT_ROUNDS=10"

echo(%REPEAT_ROUNDS%| findstr /r "^[1-9][0-9]*$" >nul
if errorlevel 1 (
  echo [REPEAT] Invalid rounds: %REPEAT_ROUNDS% ^(expect positive integer^)
  exit /b 2
)

call :build
if errorlevel 1 exit /b 1

for /L %%I in (1,1,%REPEAT_ROUNDS%) do (
  echo [REPEAT] %%I/%REPEAT_ROUNDS% suite=TTestCase_SimdConcurrent
  echo. > "%TEST_LOG%"
  "%BIN%" --suite=TTestCase_SimdConcurrent > "%TEST_LOG%" 2>&1
  if errorlevel 1 (
    echo [TEST] FAILED (see %TEST_LOG%)
    type "%TEST_LOG%"
    exit /b 1
  )
  findstr /b /c:"Invalid option" "%TEST_LOG%" >nul 2>nul
  if not errorlevel 1 (
    echo [TEST] FAILED: unsupported test argument (see %TEST_LOG%)
    type "%TEST_LOG%"
    exit /b 2
  )
  call :check_heap_leaks
  if errorlevel 1 exit /b 1
  copy /y "%TEST_LOG%" "%LOG_DIR%\repeat.TTestCase_SimdConcurrent.%%I.txt" >nul
)

echo [REPEAT] OK suite=TTestCase_SimdConcurrent rounds=%REPEAT_ROUNDS%
exit /b 0

:nonx86_ieee754
call "%~f0" test --suite=TTestCase_NonX86IEEE754
exit /b %ERRORLEVEL%

:backend_bench
set "BENCH_SCRIPT=%ROOT%run_backend_benchmarks.sh"
if not exist "%BENCH_SCRIPT%" (
  echo [BENCH] Missing benchmark script: %BENCH_SCRIPT%
  exit /b 2
)

where bash >nul 2>nul
if errorlevel 1 (
  echo [BENCH] SKIP ^(bash not found^)
  exit /b 0
)

echo [BENCH] Running: bash %BENCH_SCRIPT%
bash "%BENCH_SCRIPT%" %NORMALIZED_TEST_ARGS%
exit /b %ERRORLEVEL%

:qemu_nonx86_evidence
set "QEMU_SCRIPT=%ROOT%docker\run_multiarch_qemu.sh"
if not exist "%QEMU_SCRIPT%" (
  echo [QEMU] Missing script: %QEMU_SCRIPT%
  exit /b 2
)

where bash >nul 2>nul
if errorlevel 1 (
  echo [QEMU] SKIP ^(bash not found^)
  exit /b 0
)

set "QEMU_BUILD_POLICY=%SIMD_QEMU_BUILD_POLICY%"
if "!QEMU_BUILD_POLICY!"=="" set "QEMU_BUILD_POLICY=if-missing"
echo [QEMU] Build policy: !QEMU_BUILD_POLICY! ^(always^|if-missing^|skip^)
echo [QEMU] Running: bash %QEMU_SCRIPT% nonx86-evidence %NORMALIZED_TEST_ARGS%
bash "%QEMU_SCRIPT%" nonx86-evidence %NORMALIZED_TEST_ARGS%
exit /b %ERRORLEVEL%

:qemu_arch_matrix_evidence
set "QEMU_SCRIPT=%ROOT%docker\run_multiarch_qemu.sh"
if not exist "%QEMU_SCRIPT%" (
  echo [QEMU] Missing script: %QEMU_SCRIPT%
  exit /b 2
)

where bash >nul 2>nul
if errorlevel 1 (
  echo [QEMU] SKIP ^(bash not found^)
  exit /b 0
)

set "QEMU_BUILD_POLICY=%SIMD_QEMU_BUILD_POLICY%"
if "!QEMU_BUILD_POLICY!"=="" set "QEMU_BUILD_POLICY=if-missing"
echo [QEMU] Build policy: !QEMU_BUILD_POLICY! ^(always^|if-missing^|skip^)
echo [QEMU] Running: bash %QEMU_SCRIPT% arch-matrix-evidence %NORMALIZED_TEST_ARGS%
bash "%QEMU_SCRIPT%" arch-matrix-evidence %NORMALIZED_TEST_ARGS%
exit /b %ERRORLEVEL%

:qemu_nonx86_experimental_asm
set "QEMU_SCRIPT=%ROOT%docker\run_multiarch_qemu.sh"
if not exist "%QEMU_SCRIPT%" (
  echo [QEMU] Missing script: %QEMU_SCRIPT%
  exit /b 2
)

where bash >nul 2>nul
if errorlevel 1 (
  echo [QEMU] SKIP ^(bash not found^)
  exit /b 0
)

set "QEMU_BUILD_POLICY=%SIMD_QEMU_BUILD_POLICY%"
if "!QEMU_BUILD_POLICY!"=="" set "QEMU_BUILD_POLICY=if-missing"
echo [QEMU] Build policy: !QEMU_BUILD_POLICY! ^(always^|if-missing^|skip^)
if "%SIMD_QEMU_EXPERIMENTAL_DEFINE%"=="" set "SIMD_QEMU_EXPERIMENTAL_DEFINE=-dFAFAFA_SIMD_EXPERIMENTAL_BACKEND_ASM"
echo [QEMU] Experimental asm env:
echo [QEMU]   SIMD_QEMU_ENABLE_BACKEND_ASM=%SIMD_QEMU_ENABLE_BACKEND_ASM%
echo [QEMU]   SIMD_QEMU_BACKEND_ASM_PROBE_MODE=%SIMD_QEMU_BACKEND_ASM_PROBE_MODE%
echo [QEMU]   SIMD_QEMU_EXPERIMENTAL_ARM64_COMPILER_DEFINE=%SIMD_QEMU_EXPERIMENTAL_ARM64_COMPILER_DEFINE%
echo [QEMU]   SIMD_QEMU_EXPERIMENTAL_RISCV64_COMPILER_DEFINE=%SIMD_QEMU_EXPERIMENTAL_RISCV64_COMPILER_DEFINE%
echo [QEMU]   SIMD_QEMU_EXPERIMENTAL_RISCV64_OPCODE_DEFINE=%SIMD_QEMU_EXPERIMENTAL_RISCV64_OPCODE_DEFINE%
echo [QEMU] Running: bash %QEMU_SCRIPT% nonx86-experimental-asm %NORMALIZED_TEST_ARGS%
bash "%QEMU_SCRIPT%" nonx86-experimental-asm %NORMALIZED_TEST_ARGS%
exit /b %ERRORLEVEL%

:qemu_experimental_report
set "QEMU_EXP_REPORT_SCRIPT=%ROOT%report_qemu_experimental_blockers.py"
if not exist "%QEMU_EXP_REPORT_SCRIPT%" (
  echo [QEMU-EXPERIMENTAL-REPORT] Missing script: %QEMU_EXP_REPORT_SCRIPT%
  exit /b 2
)

where py >nul 2>nul
if not errorlevel 1 (
  echo [QEMU-EXPERIMENTAL-REPORT] Running: py -3 %QEMU_EXP_REPORT_SCRIPT% --latest %NORMALIZED_TEST_ARGS%
  py -3 "%QEMU_EXP_REPORT_SCRIPT%" --latest %NORMALIZED_TEST_ARGS%
  exit /b %ERRORLEVEL%
)

where python >nul 2>nul
if not errorlevel 1 (
  echo [QEMU-EXPERIMENTAL-REPORT] Running: python %QEMU_EXP_REPORT_SCRIPT% --latest %NORMALIZED_TEST_ARGS%
  python "%QEMU_EXP_REPORT_SCRIPT%" --latest %NORMALIZED_TEST_ARGS%
  exit /b %ERRORLEVEL%
)

echo [QEMU-EXPERIMENTAL-REPORT] SKIP ^(python runtime not found^)
exit /b 0

:qemu_experimental_baseline_check
set "QEMU_EXP_BASELINE_SCRIPT=%ROOT%check_experimental_failure_baseline.py"
if not exist "%QEMU_EXP_BASELINE_SCRIPT%" (
  echo [QEMU-EXPERIMENTAL-BASELINE] Missing script: %QEMU_EXP_BASELINE_SCRIPT%
  exit /b 2
)

where py >nul 2>nul
if not errorlevel 1 (
  echo [QEMU-EXPERIMENTAL-BASELINE] Running: py -3 %QEMU_EXP_BASELINE_SCRIPT% --latest %NORMALIZED_TEST_ARGS%
  py -3 "%QEMU_EXP_BASELINE_SCRIPT%" --latest %NORMALIZED_TEST_ARGS%
  exit /b %ERRORLEVEL%
)

where python >nul 2>nul
if not errorlevel 1 (
  echo [QEMU-EXPERIMENTAL-BASELINE] Running: python %QEMU_EXP_BASELINE_SCRIPT% --latest %NORMALIZED_TEST_ARGS%
  python "%QEMU_EXP_BASELINE_SCRIPT%" --latest %NORMALIZED_TEST_ARGS%
  exit /b %ERRORLEVEL%
)

echo [QEMU-EXPERIMENTAL-BASELINE] SKIP ^(python runtime not found^)
exit /b 0

:riscvv_opcode_lane
set "RVV_LANE_SCRIPT=%ROOT%docker\run_riscvv_opcode_lane.sh"
if not exist "%RVV_LANE_SCRIPT%" (
  echo [RVV-LANE] Missing script: %RVV_LANE_SCRIPT%
  exit /b 2
)

where bash >nul 2>nul
if errorlevel 1 (
  echo [RVV-LANE] SKIP ^(bash not found^)
  exit /b 0
)

echo [RVV-LANE] Running: bash %RVV_LANE_SCRIPT% %NORMALIZED_TEST_ARGS%
bash "%RVV_LANE_SCRIPT%" %NORMALIZED_TEST_ARGS%
exit /b %ERRORLEVEL%

:perf_smoke
call :build
if errorlevel 1 exit /b 1

if not exist "%BIN%" (
  echo [PERF] Missing binary: %BIN%
  exit /b 2
)

echo [PERF] Running: %BIN% --bench-only
echo. > "%TEST_LOG%"
"%BIN%" --bench-only > "%TEST_LOG%" 2>&1
if errorlevel 1 (
  echo [PERF] FAILED (see %TEST_LOG%)
  type "%TEST_LOG%"
  exit /b 1
)

findstr /b /c:"Invalid option" "%TEST_LOG%" >nul 2>nul
if not errorlevel 1 (
  echo [PERF] FAILED: unsupported bench argument (see %TEST_LOG%)
  type "%TEST_LOG%"
  exit /b 2
)

call :check_heap_leaks
if errorlevel 1 exit /b 1

findstr /c:"=== SIMD Benchmark (" "%TEST_LOG%" >nul 2>nul
if errorlevel 1 (
  echo [PERF] FAILED: benchmark header not found in %TEST_LOG%
  type "%TEST_LOG%"
  exit /b 1
)

findstr /c:"/Scalar)" "%TEST_LOG%" >nul 2>nul
if not errorlevel 1 (
  echo [PERF] SKIP ^(active backend is Scalar^)
  exit /b 0
)

echo [PERF] OK
exit /b 0

:gate_strict
set "SIMD_GATE_INTERFACE_COMPLETENESS=1"
set "SIMD_GATE_ADAPTER_SYNC_PASCAL=1"
set "SIMD_GATE_ADAPTER_SYNC=1"
set "SIMD_GATE_PARITY_SUITES=1"
set "SIMD_GATE_WIRING_SYNC=1"
set "SIMD_WIRING_SYNC_STRICT_EXTRA=1"
set "SIMD_GATE_COVERAGE=1"
set "SIMD_COVERAGE_STRICT_EXTRA=1"
set "SIMD_COVERAGE_REQUIRE_AVX2=1"
set "SIMD_COVERAGE_REQUIRE_EXPERIMENTAL=1"
set "SIMD_GATE_PERF_SMOKE=1"
set "SIMD_GATE_EXPERIMENTAL=1"
set "SIMD_GATE_EXPERIMENTAL_TESTS=1"
set "SIMD_GATE_NONX86_IEEE754=1"
set "SIMD_GATE_QEMU_NONX86_EVIDENCE=0"
set "SIMD_GATE_QEMU_ARCH_MATRIX_EVIDENCE=1"
if "%SIMD_GATE_CONCURRENT_REPEAT%"=="" set "SIMD_GATE_CONCURRENT_REPEAT=10"
call "%~f0" gate
exit /b %ERRORLEVEL%

:gate
set "SELF=%~f0"
set "TESTS_ROOT=%ROOT%.."

echo [GATE] 1/6 Build + check SIMD module
call "%SELF%" check
if errorlevel 1 exit /b 1

if /I "%SIMD_GATE_INTERFACE_COMPLETENESS%"=="1" (
  echo [GATE] Optional interface completeness check
  call "%SELF%" interface-completeness
  if errorlevel 1 exit /b 1
) else (
  echo [GATE] SKIP optional interface completeness ^(set SIMD_GATE_INTERFACE_COMPLETENESS=1 to enable^)
)

if /I "%SIMD_GATE_ADAPTER_SYNC_PASCAL%"=="1" (
  echo [GATE] Optional backend adapter sync Pascal smoke
  call "%SELF%" adapter-sync-pascal
  if errorlevel 1 exit /b 1
  set "SIMD_ADAPTER_SYNC_PASCAL_SMOKE=0"
) else (
  echo [GATE] SKIP optional backend adapter sync Pascal smoke ^(set SIMD_GATE_ADAPTER_SYNC_PASCAL=1 to enable^)
)

if /I "%SIMD_GATE_ADAPTER_SYNC%"=="1" (
  echo [GATE] Optional backend adapter sync
  call "%SELF%" adapter-sync
  if errorlevel 1 exit /b 1
) else (
  echo [GATE] SKIP optional backend adapter sync ^(set SIMD_GATE_ADAPTER_SYNC=1 to enable^)
)

echo [GATE] 2/6 SIMD list suites
call "%SELF%" test --list-suites
if errorlevel 1 exit /b 1

echo [GATE] 3/6 SIMD AVX2 fallback suite
call "%SELF%" test --suite=TTestCase_AVX2IntrinsicsFallback
if errorlevel 1 exit /b 1

if /I "%SIMD_GATE_PARITY_SUITES%"=="0" (
  echo [GATE] SKIP optional cross-backend parity suites ^(set SIMD_GATE_PARITY_SUITES=1 to enable^)
) else (
  echo [GATE] Optional cross-backend parity suites
  call "%SELF%" test --suite=TTestCase_DispatchAllSlots
  if errorlevel 1 exit /b 1
  call "%SELF%" test --suite=TTestCase_DispatchAPI
  if errorlevel 1 exit /b 1
)

if /I "%SIMD_GATE_NONX86_IEEE754%"=="0" (
  echo [GATE] SKIP optional non-x86 IEEE754 suite ^(set SIMD_GATE_NONX86_IEEE754=1 to enable^)
) else (
  echo [GATE] Optional non-x86 IEEE754 suite
  call "%SELF%" nonx86-ieee754
  if errorlevel 1 exit /b 1
)

echo [GATE] 4/6 CPUInfo portable suites
call "%TESTS_ROOT%\fafafa.core.simd.cpuinfo\buildOrTest.bat" test --list-suites
if errorlevel 1 exit /b 1
call "%TESTS_ROOT%\fafafa.core.simd.cpuinfo\buildOrTest.bat" test --suite=TTestCase_PlatformSpecific
if errorlevel 1 exit /b 1

echo [GATE] 5/6 CPUInfo x86 suites
call "%TESTS_ROOT%\fafafa.core.simd.cpuinfo.x86\buildOrTest.bat" test --list-suites
if errorlevel 1 exit /b 1
call "%TESTS_ROOT%\fafafa.core.simd.cpuinfo.x86\buildOrTest.bat" test --suite=TTestCase_Global
if errorlevel 1 exit /b 1

echo [GATE] 6/6 Filtered run_all chain
set "STOP_ON_FAIL=1"
call "%TESTS_ROOT%\run_all_tests.bat" =fafafa.core.simd =fafafa.core.simd.cpuinfo =fafafa.core.simd.cpuinfo.x86 =fafafa.core.simd.intrinsics.sse =fafafa.core.simd.intrinsics.mmx
if errorlevel 1 exit /b 1

if /I "%SIMD_GATE_CONCURRENT_REPEAT%"=="0" (
  echo [GATE] SKIP optional concurrent repeat ^(set SIMD_GATE_CONCURRENT_REPEAT=10 to enable^)
) else (
  echo [GATE] Optional concurrent repeat ^(%SIMD_GATE_CONCURRENT_REPEAT% rounds^)
  call "%SELF%" test-concurrent-repeat %SIMD_GATE_CONCURRENT_REPEAT%
  if errorlevel 1 exit /b 1
)

if /I "%SIMD_GATE_COVERAGE%"=="1" (
  echo [GATE] Optional intrinsics coverage
  call "%SELF%" coverage
  if errorlevel 1 exit /b 1
)

if /I "%SIMD_GATE_PERF_SMOKE%"=="1" (
  echo [GATE] Optional perf smoke
  call "%SELF%" perf-smoke
  if errorlevel 1 exit /b 1
) else (
  echo [GATE] SKIP optional perf smoke ^(set SIMD_GATE_PERF_SMOKE=1 to enable^)
)

if /I "%SIMD_GATE_EXPERIMENTAL%"=="0" (
  echo [GATE] SKIP optional experimental isolation ^(set SIMD_GATE_EXPERIMENTAL=1 to enable^)
) else (
  echo [GATE] Optional experimental intrinsics isolation
  call "%SELF%" experimental-intrinsics
  if errorlevel 1 exit /b 1
)

if /I "%SIMD_GATE_EXPERIMENTAL_TESTS%"=="0" (
  echo [GATE] SKIP optional experimental tests ^(set SIMD_GATE_EXPERIMENTAL_TESTS=1 to enable^)
) else (
  echo [GATE] Optional experimental intrinsics tests
  call "%SELF%" experimental-intrinsics-tests
  if errorlevel 1 exit /b 1
)

if /I "%SIMD_GATE_WIRING_SYNC%"=="1" (
  echo [GATE] Optional wiring-sync enabled
  call "%SELF%" wiring-sync
  if errorlevel 1 exit /b 1
) else (
  echo [GATE] SKIP optional wiring-sync ^(set SIMD_GATE_WIRING_SYNC=1 to enable^)
)

if /I "%SIMD_GATE_QEMU_NONX86_EVIDENCE%"=="1" (
  echo [GATE] Optional qemu non-x86 evidence
  call "%SELF%" qemu-nonx86-evidence
  if errorlevel 1 exit /b 1
) else (
  echo [GATE] SKIP optional qemu non-x86 evidence ^(set SIMD_GATE_QEMU_NONX86_EVIDENCE=1 to enable^)
)

if /I "%SIMD_GATE_QEMU_ARCH_MATRIX_EVIDENCE%"=="1" (
  echo [GATE] Optional qemu arch matrix evidence
  call "%SELF%" qemu-arch-matrix-evidence
  if errorlevel 1 exit /b 1
) else (
  echo [GATE] SKIP optional qemu arch matrix evidence ^(set SIMD_GATE_QEMU_ARCH_MATRIX_EVIDENCE=1 to enable^)
)

set "WIN_EVIDENCE_LOG=%ROOT%logs\windows_b07_gate.log"
if exist "%WIN_EVIDENCE_LOG%" (
  echo [GATE] Evidence verify ^(windows log present^)
  call "%SELF%" verify-win-evidence "%WIN_EVIDENCE_LOG%"
  if errorlevel 1 exit /b 1
) else (
  if /I "%SIMD_GATE_REQUIRE_WINDOWS_EVIDENCE%"=="1" (
    echo [GATE] FAIL required windows evidence log missing: %WIN_EVIDENCE_LOG%
    exit /b 1
  ) else (
    echo [GATE] SKIP evidence verify ^(windows log not present: %WIN_EVIDENCE_LOG%^)
  )
)

echo [GATE] OK
exit /b 0

:evidence_win
set "EVIDENCE_SCRIPT=%ROOT%collect_windows_b07_evidence.bat"
if not exist "%EVIDENCE_SCRIPT%" (
  echo [EVIDENCE] Missing collector: %EVIDENCE_SCRIPT%
  exit /b 2
)
call "%EVIDENCE_SCRIPT%"
exit /b %ERRORLEVEL%

:verify_win_evidence
set "VERIFY_SCRIPT=%ROOT%verify_windows_b07_evidence.bat"
if not exist "%VERIFY_SCRIPT%" (
  echo [EVIDENCE] Missing verifier: %VERIFY_SCRIPT%
  exit /b 2
)
call "%VERIFY_SCRIPT%" %NORMALIZED_TEST_ARGS%
exit /b %ERRORLEVEL%

:evidence_win_verify
call "%~f0" evidence-win
if errorlevel 1 exit /b 1
call "%~f0" verify-win-evidence %NORMALIZED_TEST_ARGS%
exit /b %ERRORLEVEL%

:gate_summary_sample
set "SAMPLE_SCRIPT=%ROOT%generate_gate_summary_sample.py"
set "SAMPLE_SCENARIO=%~1"
if "%SAMPLE_SCENARIO%"=="" set "SAMPLE_SCENARIO=mixed"
set "SAMPLE_OUTPUT=%~2"
if "%SAMPLE_OUTPUT%"=="" set "SAMPLE_OUTPUT=%LOG_DIR%\gate_summary.sample.%SAMPLE_SCENARIO%.md"
if "%SIMD_GATE_STEP_WARN_MS%"=="" set "SIMD_GATE_STEP_WARN_MS=20000"
if "%SIMD_GATE_STEP_FAIL_MS%"=="" set "SIMD_GATE_STEP_FAIL_MS=120000"

if not exist "%SAMPLE_SCRIPT%" (
  echo [GATE-SUMMARY-SAMPLE] Missing generator: %SAMPLE_SCRIPT%
  exit /b 2
)

where py >nul 2>nul
if not errorlevel 1 (
  py -3 "%SAMPLE_SCRIPT%" --scenario "%SAMPLE_SCENARIO%" --warn-ms %SIMD_GATE_STEP_WARN_MS% --fail-ms %SIMD_GATE_STEP_FAIL_MS% --output "%SAMPLE_OUTPUT%"
  if errorlevel 1 exit /b 1
  echo [GATE-SUMMARY-SAMPLE] output=%SAMPLE_OUTPUT%
  exit /b 0
)

where python >nul 2>nul
if not errorlevel 1 (
  python "%SAMPLE_SCRIPT%" --scenario "%SAMPLE_SCENARIO%" --warn-ms %SIMD_GATE_STEP_WARN_MS% --fail-ms %SIMD_GATE_STEP_FAIL_MS% --output "%SAMPLE_OUTPUT%"
  if errorlevel 1 exit /b 1
  echo [GATE-SUMMARY-SAMPLE] output=%SAMPLE_OUTPUT%
  exit /b 0
)

echo [GATE-SUMMARY-SAMPLE] SKIP ^(python runtime not found^)
exit /b 0

:gate_summary_rehearsal
set "REHEARSAL_SCRIPT=%ROOT%rehearse_gate_summary_thresholds.sh"
if not exist "%REHEARSAL_SCRIPT%" (
  echo [GATE-SUMMARY-REHEARSAL] Missing script: %REHEARSAL_SCRIPT%
  exit /b 2
)

where bash >nul 2>nul
if errorlevel 1 (
  echo [GATE-SUMMARY-REHEARSAL] SKIP ^(bash not found^)
  exit /b 0
)

bash "%REHEARSAL_SCRIPT%"
exit /b %ERRORLEVEL%

:gate_summary_inject
set "SAMPLE_SCRIPT=%ROOT%generate_gate_summary_sample.py"
set "SAMPLE_SCENARIO=%~1"
if "%SAMPLE_SCENARIO%"=="" set "SAMPLE_SCENARIO=mixed"
set "SUMMARY_FILE=%SIMD_GATE_SUMMARY_FILE%"
if "%SUMMARY_FILE%"=="" set "SUMMARY_FILE=%GATE_SUMMARY_LOG%"
set "SAMPLE_OUTPUT=%~2"
if "%SAMPLE_OUTPUT%"=="" set "SAMPLE_OUTPUT=%LOG_DIR%\rehearsal\injected\gate_summary.injected.%SAMPLE_SCENARIO%.md"
set "BACKUP_DIR=%LOG_DIR%\rehearsal\backups"
if "%SIMD_GATE_STEP_WARN_MS%"=="" set "SIMD_GATE_STEP_WARN_MS=20000"
if "%SIMD_GATE_STEP_FAIL_MS%"=="" set "SIMD_GATE_STEP_FAIL_MS=120000"

if not exist "%SAMPLE_SCRIPT%" (
  echo [GATE-SUMMARY-INJECT] Missing generator: %SAMPLE_SCRIPT%
  exit /b 2
)
if not exist "%LOG_DIR%\rehearsal\injected" mkdir "%LOG_DIR%\rehearsal\injected"
if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"

where py >nul 2>nul
if not errorlevel 1 (
  py -3 "%SAMPLE_SCRIPT%" --scenario "%SAMPLE_SCENARIO%" --warn-ms %SIMD_GATE_STEP_WARN_MS% --fail-ms %SIMD_GATE_STEP_FAIL_MS% --output "%SAMPLE_OUTPUT%"
  if errorlevel 1 exit /b 1
  goto :gate_summary_inject_apply
)

where python >nul 2>nul
if not errorlevel 1 (
  python "%SAMPLE_SCRIPT%" --scenario "%SAMPLE_SCENARIO%" --warn-ms %SIMD_GATE_STEP_WARN_MS% --fail-ms %SIMD_GATE_STEP_FAIL_MS% --output "%SAMPLE_OUTPUT%"
  if errorlevel 1 exit /b 1
  goto :gate_summary_inject_apply
)

echo [GATE-SUMMARY-INJECT] SKIP ^(python runtime not found^)
exit /b 0

:gate_summary_inject_apply
if /I "%SIMD_GATE_SUMMARY_APPLY%"=="1" (
  set "STAMP=%DATE:~0,4%%DATE:~5,2%%DATE:~8,2%-%TIME:~0,2%%TIME:~3,2%%TIME:~6,2%"
  set "STAMP=%STAMP: =0%"
  set "BACKUP_FILE=%BACKUP_DIR%\gate_summary.backup.!STAMP!.md"
  if exist "%SUMMARY_FILE%" (
    copy /y "%SUMMARY_FILE%" "!BACKUP_FILE!" >nul
    echo [GATE-SUMMARY-INJECT] backup=!BACKUP_FILE!
  )
  copy /y "%SAMPLE_OUTPUT%" "%SUMMARY_FILE%" >nul
  echo [GATE-SUMMARY-INJECT] applied target=%SUMMARY_FILE%
) else (
  echo [GATE-SUMMARY-INJECT] non-invasive mode ^(set SIMD_GATE_SUMMARY_APPLY=1 to replace target^)
)

echo [GATE-SUMMARY-INJECT] sample=%SAMPLE_OUTPUT%
exit /b 0

:gate_summary_rollback
set "SUMMARY_FILE=%SIMD_GATE_SUMMARY_FILE%"
if "%SUMMARY_FILE%"=="" set "SUMMARY_FILE=%GATE_SUMMARY_LOG%"
set "BACKUP_DIR=%LOG_DIR%\rehearsal\backups"
set "RESTORE_FILE=%SIMD_GATE_SUMMARY_BACKUP_FILE%"

if "%RESTORE_FILE%"=="" (
  for /f "delims=" %%f in ('dir /b /a-d /o-n "%BACKUP_DIR%\gate_summary.backup.*.md" 2^>nul') do (
    set "RESTORE_FILE=%BACKUP_DIR%\%%f"
    goto :gate_summary_rollback_do
  )
) else (
  goto :gate_summary_rollback_do
)

echo [GATE-SUMMARY-ROLLBACK] No backup found
exit /b 2

:gate_summary_rollback_do
if not exist "%RESTORE_FILE%" (
  echo [GATE-SUMMARY-ROLLBACK] Backup not found: %RESTORE_FILE%
  exit /b 2
)
copy /y "%RESTORE_FILE%" "%SUMMARY_FILE%" >nul
echo [GATE-SUMMARY-ROLLBACK] restored=%SUMMARY_FILE% from=%RESTORE_FILE%
exit /b 0

:gate_summary_backups
set "BACKUP_DIR=%LOG_DIR%\rehearsal\backups"
if not exist "%BACKUP_DIR%" (
  echo [GATE-SUMMARY-BACKUPS] none
  exit /b 0
)

dir /b /a-d /o-n "%BACKUP_DIR%\gate_summary.backup.*.md" >nul 2>nul
if errorlevel 1 (
  echo [GATE-SUMMARY-BACKUPS] none
  exit /b 0
)

echo [GATE-SUMMARY-BACKUPS] dir=%BACKUP_DIR%
dir /b /a-d /o-n "%BACKUP_DIR%\gate_summary.backup.*.md"
exit /b 0

:gate_summary
set "SUMMARY_FILE=%SIMD_GATE_SUMMARY_FILE%"
if "%SUMMARY_FILE%"=="" set "SUMMARY_FILE=%GATE_SUMMARY_LOG%"
if "%SIMD_GATE_STEP_WARN_MS%"=="" set "SIMD_GATE_STEP_WARN_MS=20000"
if "%SIMD_GATE_STEP_FAIL_MS%"=="" set "SIMD_GATE_STEP_FAIL_MS=120000"
set "SUMMARY_FILTER=%SIMD_GATE_SUMMARY_FILTER%"
if "%SUMMARY_FILTER%"=="" set "SUMMARY_FILTER=ALL"
if "%SIMD_GATE_SUMMARY_MAX_DETAIL%"=="" set "SIMD_GATE_SUMMARY_MAX_DETAIL=260"

if not exist "%SUMMARY_FILE%" (
  echo [GATE-SUMMARY] Missing summary file: %SUMMARY_FILE%
  exit /b 2
)

echo [GATE-SUMMARY] %SUMMARY_FILE%
echo [GATE-SUMMARY] thresholds: warn_ms=%SIMD_GATE_STEP_WARN_MS%, fail_ms=%SIMD_GATE_STEP_FAIL_MS%
echo [GATE-SUMMARY] filter=%SUMMARY_FILTER%, max_detail=%SIMD_GATE_SUMMARY_MAX_DETAIL%

if /I "%SUMMARY_FILTER%"=="ALL" (
  type "%SUMMARY_FILE%"
) else if /I "%SUMMARY_FILTER%"=="FAIL" (
  findstr /r /c:"^| Time |" /c:"^|---|" /c:"| FAIL |" "%SUMMARY_FILE%"
) else if /I "%SUMMARY_FILTER%"=="SLOW" (
  findstr /r /c:"^| Time |" /c:"^|---|" /c:"| SLOW_WARN |" /c:"| SLOW_FAIL |" "%SUMMARY_FILE%"
) else (
  echo [GATE-SUMMARY] WARN: unsupported filter=%SUMMARY_FILTER%, fallback=ALL
  set "SUMMARY_FILTER=ALL"
  type "%SUMMARY_FILE%"
)

if /I "%SIMD_GATE_SUMMARY_JSON%"=="1" (
  set "SUMMARY_JSON_FILE=%SIMD_GATE_SUMMARY_JSON_FILE%"
  if "%SUMMARY_JSON_FILE%"=="" set "SUMMARY_JSON_FILE=%GATE_SUMMARY_JSON_LOG%"
  set "EXPORT_SCRIPT=%ROOT%export_gate_summary_json.py"
  if not exist "%EXPORT_SCRIPT%" (
    echo [GATE-SUMMARY] Missing exporter: %EXPORT_SCRIPT%
    exit /b 2
  )

  where py >nul 2>nul
  if not errorlevel 1 (
    py -3 "%EXPORT_SCRIPT%" --input "%SUMMARY_FILE%" --output "%SUMMARY_JSON_FILE%" --filter "%SUMMARY_FILTER%" --warn-ms %SIMD_GATE_STEP_WARN_MS% --fail-ms %SIMD_GATE_STEP_FAIL_MS%
    if errorlevel 1 exit /b 1
    echo [GATE-SUMMARY] json=%SUMMARY_JSON_FILE%
    exit /b 0
  )

  where python >nul 2>nul
  if not errorlevel 1 (
    python "%EXPORT_SCRIPT%" --input "%SUMMARY_FILE%" --output "%SUMMARY_JSON_FILE%" --filter "%SUMMARY_FILTER%" --warn-ms %SIMD_GATE_STEP_WARN_MS% --fail-ms %SIMD_GATE_STEP_FAIL_MS%
    if errorlevel 1 exit /b 1
    echo [GATE-SUMMARY] json=%SUMMARY_JSON_FILE%
    exit /b 0
  )

  echo [GATE-SUMMARY] SKIP JSON export ^(python runtime not found^)
)

exit /b 0
