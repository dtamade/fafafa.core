@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

set "OUTPUT_ROOT=%~dp0_windows_l0_native_evidence"
set "EVIDENCE_DIR=%~1"
set "FAIL=0"

if "%EVIDENCE_DIR%"=="" call :find_latest_evidence_dir
if "%EVIDENCE_DIR%"=="" (
  echo [EVIDENCE] Missing evidence directory.
  exit /b 2
)

set "EVIDENCE_LOG=%EVIDENCE_DIR%\evidence.log"
set "SUMMARY_FILE=%EVIDENCE_DIR%\summary.md"
set "ENV_FILE=%EVIDENCE_DIR%\environment.txt"
set "SOURCE_FILE=%EVIDENCE_DIR%\source_revision.txt"
set "MATRIX_LOG=%EVIDENCE_DIR%\native_matrix.log"
set "MODULE_LOG_DIR=%EVIDENCE_DIR%\module-logs"

if not exist "%EVIDENCE_LOG%" (
  echo [EVIDENCE] Missing evidence log: %EVIDENCE_LOG%
  exit /b 2
)
if not exist "%SUMMARY_FILE%" (
  echo [EVIDENCE] Missing summary: %SUMMARY_FILE%
  exit /b 2
)
if not exist "%ENV_FILE%" (
  echo [EVIDENCE] Missing environment file: %ENV_FILE%
  exit /b 2
)
if not exist "%SOURCE_FILE%" (
  echo [EVIDENCE] Missing source revision file: %SOURCE_FILE%
  exit /b 2
)
if not exist "%MATRIX_LOG%" (
  echo [EVIDENCE] Missing matrix log: %MATRIX_LOG%
  exit /b 2
)
if not exist "%MODULE_LOG_DIR%" (
  echo [EVIDENCE] Missing module log dir: %MODULE_LOG_DIR%
  exit /b 2
)

call :check_fixed "%EVIDENCE_LOG%" "[L0-NATIVE] strict L0 Windows native evidence capture"
call :check_fixed "%EVIDENCE_LOG%" "[L0-NATIVE] Source: collect_windows_strict_l0_native_evidence.bat"
call :check_fixed "%EVIDENCE_LOG%" "[L0-NATIVE] HostOS: Windows_NT"
call :check_fixed "%EVIDENCE_LOG%" "[L0-NATIVE] MatrixCommand: tests\test_windows_strict_l0_batch_native_matrix.bat"
call :check_fixed "%EVIDENCE_LOG%" "[L0-NATIVE] Total: 12"
call :check_fixed "%EVIDENCE_LOG%" "[L0-NATIVE] Passed: 12"
call :check_fixed "%EVIDENCE_LOG%" "[L0-NATIVE] Failed: 0"
call :check_fixed "%EVIDENCE_LOG%" "[L0-NATIVE] MATRIX_EXIT_CODE=0"
call :check_windows_working_dir "%EVIDENCE_LOG%"

call :check_fixed "%SUMMARY_FILE%" "- Result: PASS"
call :check_fixed "%SOURCE_FILE%" "git_commit="
call :check_fixed "%SOURCE_FILE%" "git_ref_hint="
call :check_fixed "%ENV_FILE%" "host_os=Windows_NT"
call :check_fixed "%ENV_FILE%" "tool_lazbuild_wrapper="
call :check_fixed "%ENV_FILE%" "where_lazbuild_exe="
call :check_fixed "%MATRIX_LOG%" "[PASS] strict L0 Windows native batch matrix verified"

call :check_module_log base.log
call :check_module_log contracts.log
call :check_module_log bits.log
call :check_module_log layout.log
call :check_module_log endian.log
call :check_module_log span.log
call :check_module_log option.log
call :check_module_log result.log
call :check_module_log platform.log
call :check_module_log atomic.log
call :check_module_log mem_allocator_foundation.log
call :check_module_log mem_allocator_only.log

if not "%FAIL%"=="0" (
  echo [EVIDENCE] FAILED: %EVIDENCE_DIR%
  exit /b 1
)

echo [EVIDENCE] OK: %EVIDENCE_DIR%
exit /b 0

:find_latest_evidence_dir
for /f "delims=" %%I in ('dir /b /ad /o-n "%OUTPUT_ROOT%" 2^>nul') do (
  set "EVIDENCE_DIR=%OUTPUT_ROOT%\%%I"
  exit /b 0
)
exit /b 0

:check_fixed
set "CHECK_FILE=%~1"
set "CHECK_PATTERN=%~2"
findstr /L /C:"%CHECK_PATTERN%" "%CHECK_FILE%" >nul 2>nul
if errorlevel 1 (
  echo [EVIDENCE] Missing pattern in %CHECK_FILE%: %CHECK_PATTERN%
  set "FAIL=1"
)
exit /b 0

:check_windows_working_dir
set "CHECK_FILE=%~1"
set "WORKING_DIR="
for /f "usebackq tokens=1,* delims=:" %%A in ("%CHECK_FILE%") do (
  if /I "%%A"=="[L0-NATIVE] Working dir" (
    set "WORKING_DIR=%%B"
  )
)
if defined WORKING_DIR set "WORKING_DIR=!WORKING_DIR:~1!"
if not defined WORKING_DIR (
  echo [EVIDENCE] Missing working dir marker
  set "FAIL=1"
  exit /b 0
)
if not "!WORKING_DIR:~1,1!"==":" goto :invalid_working_dir
if not "!WORKING_DIR:~2,1!"=="\" goto :invalid_working_dir
echo(!WORKING_DIR:~0,1!| findstr /R /C:"^[A-Za-z]$" >nul 2>nul
if errorlevel 1 goto :invalid_working_dir
exit /b 0

:invalid_working_dir
echo [EVIDENCE] Invalid Windows working dir: !WORKING_DIR!
set "FAIL=1"
exit /b 0

:check_module_log
set "MODULE_FILE=%~1"
set "MODULE_PATH=%MODULE_LOG_DIR%\%MODULE_FILE%"
if not exist "%MODULE_PATH%" (
  echo [EVIDENCE] Missing module log: %MODULE_PATH%
  set "FAIL=1"
  exit /b 0
)
call :check_fixed "%MODULE_PATH%" "[BUILD] OK"
call :check_fixed "%MODULE_PATH%" "[TEST] OK"
call :check_fixed "%MODULE_PATH%" "[LEAK] OK"
exit /b 0
