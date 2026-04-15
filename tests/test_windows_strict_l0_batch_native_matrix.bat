@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION
cd /d "%~dp0\.."

set "REPO_ROOT=%CD%"
set "LOG_DIR=%REPO_ROOT%\tests\_windows_batch_native_matrix"
set "BOOTSTRAP_LOG=%LOG_DIR%\bootstrap.log"
set "SKIP_BUILD_FLAG=%FAFAFA_SKIP_BUILD: =%"

if exist "%LOG_DIR%" rmdir /s /q "%LOG_DIR%" 2>nul
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%" >nul 2>nul

if /I "%SKIP_BUILD_FLAG%"=="1" (
  echo [FAIL] FAFAFA_SKIP_BUILD must be unset for native build-path parity.
  exit /b 41
)

echo [INFO] strict L0 Windows native batch matrix
echo [INFO] logs: "%LOG_DIR%"

call :PREFLIGHT_LAZBUILD
set "EXIT_ERR=%ERRORLEVEL%"
if not "%EXIT_ERR%"=="0" exit /b %EXIT_ERR%

call :RUN_CASE "base" "tests\fafafa.core.base" "BuildOrTest.bat" "test"
set "EXIT_ERR=%ERRORLEVEL%"
if not "%EXIT_ERR%"=="0" exit /b %EXIT_ERR%

call :RUN_CASE "contracts" "tests\fafafa.core.contracts" "BuildOrTest.bat" "test"
set "EXIT_ERR=%ERRORLEVEL%"
if not "%EXIT_ERR%"=="0" exit /b %EXIT_ERR%

call :RUN_CASE "bits" "tests\fafafa.core.bits" "BuildOrTest.bat" "test"
set "EXIT_ERR=%ERRORLEVEL%"
if not "%EXIT_ERR%"=="0" exit /b %EXIT_ERR%

call :RUN_CASE "layout" "tests\fafafa.core.layout" "BuildOrTest.bat" "test"
set "EXIT_ERR=%ERRORLEVEL%"
if not "%EXIT_ERR%"=="0" exit /b %EXIT_ERR%

call :RUN_CASE "endian" "tests\fafafa.core.endian" "BuildOrTest.bat" "test"
set "EXIT_ERR=%ERRORLEVEL%"
if not "%EXIT_ERR%"=="0" exit /b %EXIT_ERR%

call :RUN_CASE "span" "tests\fafafa.core.span" "BuildOrTest.bat" "test"
set "EXIT_ERR=%ERRORLEVEL%"
if not "%EXIT_ERR%"=="0" exit /b %EXIT_ERR%

call :RUN_CASE "option" "tests\fafafa.core.option" "BuildOrTest.bat" "test"
set "EXIT_ERR=%ERRORLEVEL%"
if not "%EXIT_ERR%"=="0" exit /b %EXIT_ERR%

call :RUN_CASE "result" "tests\fafafa.core.result" "BuildOrTest.bat" "test"
set "EXIT_ERR=%ERRORLEVEL%"
if not "%EXIT_ERR%"=="0" exit /b %EXIT_ERR%

call :RUN_CASE "platform" "tests\fafafa.core.platform" "BuildOrTest.bat" "test"
set "EXIT_ERR=%ERRORLEVEL%"
if not "%EXIT_ERR%"=="0" exit /b %EXIT_ERR%

call :RUN_CASE "atomic" "tests\fafafa.core.atomic" "BuildOrTest.bat" "test"
set "EXIT_ERR=%ERRORLEVEL%"
if not "%EXIT_ERR%"=="0" exit /b %EXIT_ERR%

call :RUN_CASE "mem_allocator_foundation" "tests\fafafa.core.mem.allocator.foundation" "BuildOrTest.bat" "test"
set "EXIT_ERR=%ERRORLEVEL%"
if not "%EXIT_ERR%"=="0" exit /b %EXIT_ERR%

call :RUN_CASE "mem_allocator_only" "tests\fafafa.core.mem" "BuildOrTest.bat" "test"
set "EXIT_ERR=%ERRORLEVEL%"
if not "%EXIT_ERR%"=="0" exit /b %EXIT_ERR%

echo [PASS] strict L0 Windows native batch matrix verified
exit /b 0

:PREFLIGHT_LAZBUILD
call "tools\lazbuild.bat" --help >"%BOOTSTRAP_LOG%" 2>&1
set "BOOTSTRAP_RC=%ERRORLEVEL%"
if "%BOOTSTRAP_RC%"=="0" (
  echo [INFO] lazbuild bootstrap OK
  exit /b 0
)

type "%BOOTSTRAP_LOG%"

findstr /R /C:"\[ERROR\] lazbuild not found\. Set LAZBUILD_EXE or install Lazarus\." "%BOOTSTRAP_LOG%" >nul
if not errorlevel 1 (
  call :PRINT_WINDOWS_RECOVERY_GUIDANCE
  exit /b 31
)

findstr /R /C:"non-Windows executable" "%BOOTSTRAP_LOG%" >nul
if not errorlevel 1 (
  call :PRINT_WINDOWS_RECOVERY_GUIDANCE
  exit /b 32
)

findstr /I /C:"not recognized as an internal or external command" /C:"Can't recognize" "%BOOTSTRAP_LOG%" >nul
if not errorlevel 1 (
  echo [FAIL] tools\lazbuild.bat was not callable from cmd. See "%BOOTSTRAP_LOG%".
  exit /b 33
)

echo [FAIL] Windows lazbuild bootstrap failed with rc=%BOOTSTRAP_RC%. See "%BOOTSTRAP_LOG%".
exit /b %BOOTSTRAP_RC%

:PRINT_WINDOWS_RECOVERY_GUIDANCE
echo [INFO] Provide a real Windows lazbuild.exe before rerunning.
echo [INFO] Example CMD setup:
echo [INFO]   set LAZBUILD_EXE=C:\Lazarus\lazbuild.exe
echo [INFO]   rem or: set LAZBUILD_EXE=%%ProgramFiles%%\Lazarus\lazbuild.exe
echo [INFO] Then rerun:
echo [INFO]   tests\test_windows_strict_l0_batch_native_matrix.bat
exit /b 0

:RUN_CASE
set "CASE_NAME=%~1"
set "CASE_DIR=%~2"
set "CASE_BATCH=%~3"
set "CASE_ACTION=%~4"
set "CASE_LOG=%LOG_DIR%\%CASE_NAME%.log"

pushd "%CASE_DIR%" >nul
call "%CASE_BATCH%" %CASE_ACTION% >"%CASE_LOG%" 2>&1
set "CASE_RC=%ERRORLEVEL%"
popd >nul

if not "%CASE_RC%"=="0" (
  type "%CASE_LOG%"
  echo [FAIL] %CASE_NAME%: batch runner exited with rc=%CASE_RC%. See "%CASE_LOG%".
  exit /b %CASE_RC%
)

findstr /R /C:"\[BUILD\] OK" "%CASE_LOG%" >nul
if errorlevel 1 (
  type "%CASE_LOG%"
  echo [FAIL] %CASE_NAME%: missing [BUILD] OK marker. See "%CASE_LOG%".
  exit /b 34
)

findstr /R /C:"\[TEST\] OK" "%CASE_LOG%" >nul
if errorlevel 1 (
  type "%CASE_LOG%"
  echo [FAIL] %CASE_NAME%: missing [TEST] OK marker. See "%CASE_LOG%".
  exit /b 35
)

findstr /R /C:"\[LEAK\] OK" "%CASE_LOG%" >nul
if errorlevel 1 (
  type "%CASE_LOG%"
  echo [FAIL] %CASE_NAME%: missing [LEAK] OK marker. See "%CASE_LOG%".
  exit /b 36
)

findstr /R /C:"\[BUILD\] SKIPPED" /C:"lazbuild not found" /C:"non-Windows executable" /C:"Test executable not found" /C:"heaptrc reports unfreed blocks" /C:"\[BUILD\] FAILED code=" /C:"\[TEST\] FAILED code=" /C:"\[LEAK\] FAILED" "%CASE_LOG%" >nul
if not errorlevel 1 (
  type "%CASE_LOG%"
  echo [FAIL] %CASE_NAME%: build or runtime failure markers found. See "%CASE_LOG%".
  exit /b 37
)

echo [INFO] %CASE_NAME%: PASS
exit /b 0
