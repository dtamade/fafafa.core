@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION
cd /d "%~dp0\.."

set "REPO_ROOT=%CD%"
set "OUTPUT_ROOT=%REPO_ROOT%\tests\_windows_l0_native_evidence"
set "BATCH_ID=%L0_WINDOWS_EVIDENCE_BATCH_ID%"
set "TS="
set "CMD_VER="
set "GIT_COMMIT="
set "GIT_REF_HINT="
set "GIT_TREE_STATE=unknown"
set "MATRIX_LOG_DIR=%REPO_ROOT%\tests\_windows_batch_native_matrix"

if not exist "%OUTPUT_ROOT%" mkdir "%OUTPUT_ROOT%" >nul 2>nul

if "%BATCH_ID%"=="" (
  for /f %%I in ('powershell -NoProfile -Command "(Get-Date).ToUniversalTime().ToString(\"yyyyMMdd-HHmmss\")"') do set "TS=%%I"
  if "!TS!"=="" set "TS=manual-%RANDOM%%RANDOM%"
  set "TS=!TS: =0!"
  set "TS=!TS::=!"
  set "TS=!TS:/=-!"
  set "BATCH_ID=L0-!TS!"
)

set "OUT_DIR=%OUTPUT_ROOT%\%BATCH_ID%"
set "MODULE_LOG_DIR=%OUT_DIR%\module-logs"
set "EVIDENCE_LOG=%OUT_DIR%\evidence.log"
set "MATRIX_LOG=%OUT_DIR%\native_matrix.log"
set "SUMMARY_FILE=%OUT_DIR%\summary.md"
set "ENV_FILE=%OUT_DIR%\environment.txt"
set "SOURCE_FILE=%OUT_DIR%\source_revision.txt"
set "WHERE_LAZBUILD_FILE=%OUT_DIR%\where_lazbuild_exe.txt"
set "TOTAL_COUNT=0"
set "PASS_COUNT=0"
set "FAIL_COUNT=0"
set "RESULT=FAIL"
set "MATRIX_RC=1"

if exist "%OUT_DIR%" rmdir /s /q "%OUT_DIR%" 2>nul
mkdir "%OUT_DIR%" >nul 2>nul
mkdir "%MODULE_LOG_DIR%" >nul 2>nul

for /f "delims=" %%V in ('ver') do set "CMD_VER=%%V"
if "%CMD_VER%"=="" set "CMD_VER=unknown"

for /f %%I in ('powershell -NoProfile -Command "(Get-Date).ToUniversalTime().ToString(\"yyyy-MM-ddTHH:mm:ssZ\")"') do set "COLLECTED_AT_UTC=%%I"
if "%COLLECTED_AT_UTC%"=="" set "COLLECTED_AT_UTC=unknown-windows-time"

for /f %%I in ('git rev-parse HEAD 2^>nul') do set "GIT_COMMIT=%%I"
if "%GIT_COMMIT%"=="" set "GIT_COMMIT=unknown"

for /f "delims=" %%I in ('git branch --show-current 2^>nul') do set "GIT_REF_HINT=%%I"
if "%GIT_REF_HINT%"=="" if not "%GITHUB_REF_NAME%"=="" set "GIT_REF_HINT=%GITHUB_REF_NAME%"
if "%GIT_REF_HINT%"=="" set "GIT_REF_HINT=%GIT_COMMIT%"

git rev-parse --is-inside-work-tree >nul 2>nul
if not errorlevel 1 (
  git status --short --untracked-files=no > "%OUT_DIR%\git_status_tracked.txt" 2>nul
  for %%I in ("%OUT_DIR%\git_status_tracked.txt") do (
    if %%~zI EQU 0 (
      set "GIT_TREE_STATE=clean"
    ) else (
      set "GIT_TREE_STATE=dirty"
    )
  )
)

> "%EVIDENCE_LOG%" (
  echo [L0-NATIVE] strict L0 Windows native evidence capture
  echo [L0-NATIVE] Source: collect_windows_strict_l0_native_evidence.bat
  echo [L0-NATIVE] HostOS: %OS%
  echo [L0-NATIVE] CmdVer: %CMD_VER%
  echo [L0-NATIVE] Started: %DATE% %TIME%
  echo [L0-NATIVE] CollectedAtUtc: %COLLECTED_AT_UTC%
  echo [L0-NATIVE] Working dir: %REPO_ROOT%
  echo [L0-NATIVE] BatchId: %BATCH_ID%
  echo [L0-NATIVE] EvidenceDir: %OUT_DIR%
  echo [L0-NATIVE] MatrixCommand: tests\test_windows_strict_l0_batch_native_matrix.bat
  echo [L0-NATIVE] MatrixLog: %MATRIX_LOG%
  echo [L0-NATIVE] SummaryFile: %SUMMARY_FILE%
  echo [L0-NATIVE] EnvironmentFile: %ENV_FILE%
  echo [L0-NATIVE] SourceRevisionFile: %SOURCE_FILE%
)

where lazbuild.exe > "%WHERE_LAZBUILD_FILE%" 2>&1

> "%ENV_FILE%" (
  echo host_os=%OS%
  echo cmd_ver=%CMD_VER%
  echo repo_root=%REPO_ROOT%
  echo batch_id=%BATCH_ID%
  echo collected_at_utc=%COLLECTED_AT_UTC%
  echo lazbuild_env=%LAZBUILD_EXE%
  echo tool_lazbuild_wrapper=%REPO_ROOT%\tools\lazbuild.bat
  echo where_lazbuild_exe=%WHERE_LAZBUILD_FILE%
  echo git_commit=%GIT_COMMIT%
  echo git_ref_hint=%GIT_REF_HINT%
  echo git_tree_state=%GIT_TREE_STATE%
  echo github_repository=%GITHUB_REPOSITORY%
  echo github_workflow=%GITHUB_WORKFLOW%
  echo github_run_id=%GITHUB_RUN_ID%
  echo github_run_attempt=%GITHUB_RUN_ATTEMPT%
)

> "%SOURCE_FILE%" (
  echo collected_at_utc=%COLLECTED_AT_UTC%
  echo git_commit=%GIT_COMMIT%
  echo git_ref_hint=%GIT_REF_HINT%
  echo git_tree_state=%GIT_TREE_STATE%
  echo github_repository=%GITHUB_REPOSITORY%
  echo github_workflow=%GITHUB_WORKFLOW%
  echo github_run_id=%GITHUB_RUN_ID%
  echo github_run_attempt=%GITHUB_RUN_ATTEMPT%
)

call "tests\test_windows_strict_l0_batch_native_matrix.bat" > "%MATRIX_LOG%" 2>&1
set "MATRIX_RC=%ERRORLEVEL%"

if exist "%MATRIX_LOG_DIR%" (
  xcopy /Y /I /Q "%MATRIX_LOG_DIR%\*.log" "%MODULE_LOG_DIR%\" >nul 2>nul
)

call :CHECK_MODULE_LOG base.log
call :CHECK_MODULE_LOG contracts.log
call :CHECK_MODULE_LOG bits.log
call :CHECK_MODULE_LOG layout.log
call :CHECK_MODULE_LOG endian.log
call :CHECK_MODULE_LOG span.log
call :CHECK_MODULE_LOG option.log
call :CHECK_MODULE_LOG result.log
call :CHECK_MODULE_LOG platform.log
call :CHECK_MODULE_LOG atomic.log
call :CHECK_MODULE_LOG mem_allocator_foundation.log
call :CHECK_MODULE_LOG mem_allocator_only.log

if "%MATRIX_RC%"=="0" if "%FAIL_COUNT%"=="0" set "RESULT=PASS"

>> "%EVIDENCE_LOG%" (
  echo [L0-NATIVE] Total: %TOTAL_COUNT%
  echo [L0-NATIVE] Passed: %PASS_COUNT%
  echo [L0-NATIVE] Failed: %FAIL_COUNT%
  echo [L0-NATIVE] MATRIX_EXIT_CODE=%MATRIX_RC%
)

> "%SUMMARY_FILE%" (
  echo # strict L0 Windows Native Evidence ^(%BATCH_ID%^)
  echo.
  echo - Result: %RESULT%
  echo - Batch: %BATCH_ID%
  echo - Evidence Log: %EVIDENCE_LOG%
  echo - Matrix Log: %MATRIX_LOG%
  echo - Module Logs: %MODULE_LOG_DIR%
  echo - Environment: %ENV_FILE%
  echo - Source Revision: %SOURCE_FILE%
  echo.
  echo ## Matrix
  echo - Exit Code: %MATRIX_RC%
  echo - Total: %TOTAL_COUNT%
  echo - Passed: %PASS_COUNT%
  echo - Failed: %FAIL_COUNT%
  echo.
  echo ## Module Logs
  echo - base.log
  echo - contracts.log
  echo - bits.log
  echo - layout.log
  echo - endian.log
  echo - span.log
  echo - option.log
  echo - result.log
  echo - platform.log
  echo - atomic.log
  echo - mem_allocator_foundation.log
  echo - mem_allocator_only.log
)

type "%EVIDENCE_LOG%"
if not "%MATRIX_RC%"=="0" (
  type "%MATRIX_LOG%"
)

echo [L0-NATIVE] Evidence ready: %OUT_DIR%
exit /b %MATRIX_RC%

:CHECK_MODULE_LOG
set /a TOTAL_COUNT+=1
set "MODULE_FILE=%~1"
set "MODULE_PATH=%MODULE_LOG_DIR%\%MODULE_FILE%"
if not exist "%MODULE_PATH%" (
  set /a FAIL_COUNT+=1
  >> "%EVIDENCE_LOG%" echo [L0-NATIVE] ModuleMissing: %MODULE_FILE%
  exit /b 0
)

findstr /R /C:"\[BUILD\] OK" "%MODULE_PATH%" >nul 2>nul
if errorlevel 1 goto :module_fail
findstr /R /C:"\[TEST\] OK" "%MODULE_PATH%" >nul 2>nul
if errorlevel 1 goto :module_fail
findstr /R /C:"\[LEAK\] OK" "%MODULE_PATH%" >nul 2>nul
if errorlevel 1 goto :module_fail

set /a PASS_COUNT+=1
>> "%EVIDENCE_LOG%" echo [L0-NATIVE] ModuleOK: %MODULE_FILE%
exit /b 0

:module_fail
set /a FAIL_COUNT+=1
>> "%EVIDENCE_LOG%" echo [L0-NATIVE] ModuleFail: %MODULE_FILE%
exit /b 0
