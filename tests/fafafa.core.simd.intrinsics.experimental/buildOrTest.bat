@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "ACTION=%~1"
if "%ACTION%"=="" set "ACTION=test"
if not "%~1"=="" shift
set "TEST_ARGS=%*"

set "ROOT=%~dp0"
set "OUTPUT_ROOT=%SIMD_OUTPUT_ROOT%"
if "%OUTPUT_ROOT%"=="" set "OUTPUT_ROOT=%ROOT%"
set "BIN_DIR=%OUTPUT_ROOT%bin"
set "LIB_DIR=%OUTPUT_ROOT%lib"
set "LOG_DIR=%OUTPUT_ROOT%logs"
set "CANONICAL_RUNNER=%ROOT%BuildOrTest.sh"

if /I "%ACTION%"=="clean" goto :clean
if /I "%ACTION%"=="build" goto :build
if /I "%ACTION%"=="build-experimental" goto :build_experimental
if /I "%ACTION%"=="check" goto :check
if /I "%ACTION%"=="test" goto :test
if /I "%ACTION%"=="test-experimental" goto :test_experimental
if /I "%ACTION%"=="test-all" goto :test_all

echo Usage: %~nx0 [clean^|build^|build-experimental^|check^|test^|test-experimental^|test-all] [test-args...]
echo [INFO] Canonical runner: tests\fafafa.core.simd.intrinsics.experimental\BuildOrTest.sh
exit /b 2

:require_canonical_runner
if not exist "%CANONICAL_RUNNER%" (
  echo [CANONICAL] Missing runner: %CANONICAL_RUNNER%
  exit /b 2
)
exit /b 0

:require_bash_runtime
where bash >nul 2>nul
if errorlevel 1 (
  echo [CANONICAL] FAILED ^(bash runtime not found; direct batch experimental runner requires bash to preserve shell parity^)
  exit /b 2
)
exit /b 0

:run_canonical
set "CANONICAL_ACTION=%~1"
set "CANONICAL_EXPERIMENTAL_FLAG=%~2"
call :require_canonical_runner
if errorlevel 1 exit /b 2
call :require_bash_runtime
if errorlevel 1 exit /b 2

set "PREV_SIMD_OUTPUT_ROOT=%SIMD_OUTPUT_ROOT%"
set "PREV_FAFAFA_SIMD_EXPERIMENTAL_INTRINSICS=%FAFAFA_SIMD_EXPERIMENTAL_INTRINSICS%"
set "SIMD_OUTPUT_ROOT=%OUTPUT_ROOT%"
if "%CANONICAL_EXPERIMENTAL_FLAG%"=="" (
  set "FAFAFA_SIMD_EXPERIMENTAL_INTRINSICS="
) else (
  set "FAFAFA_SIMD_EXPERIMENTAL_INTRINSICS=%CANONICAL_EXPERIMENTAL_FLAG%"
)

echo [CANONICAL] Running: bash %CANONICAL_RUNNER% %CANONICAL_ACTION% %TEST_ARGS%
bash "%CANONICAL_RUNNER%" "%CANONICAL_ACTION%" %TEST_ARGS%
set "CANONICAL_RC=%ERRORLEVEL%"

if defined PREV_FAFAFA_SIMD_EXPERIMENTAL_INTRINSICS (
  set "FAFAFA_SIMD_EXPERIMENTAL_INTRINSICS=%PREV_FAFAFA_SIMD_EXPERIMENTAL_INTRINSICS%"
) else (
  set "FAFAFA_SIMD_EXPERIMENTAL_INTRINSICS="
)

if defined PREV_SIMD_OUTPUT_ROOT (
  set "SIMD_OUTPUT_ROOT=%PREV_SIMD_OUTPUT_ROOT%"
) else (
  set "SIMD_OUTPUT_ROOT="
)

set "PREV_FAFAFA_SIMD_EXPERIMENTAL_INTRINSICS="
set "PREV_SIMD_OUTPUT_ROOT="
set "CANONICAL_ACTION="
set "CANONICAL_EXPERIMENTAL_FLAG="
exit /b %CANONICAL_RC%

:clean
echo [CLEAN] Removing bin/, lib/, logs/
if exist "%BIN_DIR%" rmdir /s /q "%BIN_DIR%"
if exist "%LIB_DIR%" rmdir /s /q "%LIB_DIR%"
if exist "%LOG_DIR%" rmdir /s /q "%LOG_DIR%"
exit /b 0

:build
call :run_canonical "build" "0"
exit /b %ERRORLEVEL%

:build_experimental
call :run_canonical "build" "1"
exit /b %ERRORLEVEL%

:check
call :run_canonical "check" "0"
exit /b %ERRORLEVEL%

:test
call :run_canonical "test" "0"
exit /b %ERRORLEVEL%

:test_experimental
call :run_canonical "test" "1"
exit /b %ERRORLEVEL%

:test_all
call :run_canonical "test-all" "0"
exit /b %ERRORLEVEL%
