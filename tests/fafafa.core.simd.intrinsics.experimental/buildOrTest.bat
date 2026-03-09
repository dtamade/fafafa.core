@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "ACTION=%~1"
if "%ACTION%"=="" set "ACTION=test"
if not "%~1"=="" shift
set "TEST_ARGS=%*"

set "ROOT=%~dp0"
set "PROG=%ROOT%fafafa.core.simd.intrinsics.experimental.test.lpr"
set "BIN_DIR=%ROOT%bin"
set "LIB_DIR=%ROOT%lib"
set "BIN=%BIN_DIR%\fafafa.core.simd.intrinsics.experimental.test.exe"
set "LOG_DIR=%ROOT%logs"
set "BUILD_LOG=%LOG_DIR%\build.txt"
set "TEST_LOG=%LOG_DIR%\test.txt"

if not exist "%BIN_DIR%" mkdir "%BIN_DIR%"
if not exist "%LIB_DIR%" mkdir "%LIB_DIR%"
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

set "FPC_BIN=%FPC%"
if "%FPC_BIN%"=="" set "FPC_BIN=fpc"

if /I "%ACTION%"=="clean" goto :clean
if /I "%ACTION%"=="build" goto :build
if /I "%ACTION%"=="build-experimental" goto :build_experimental
if /I "%ACTION%"=="check" goto :check
if /I "%ACTION%"=="test" goto :test
if /I "%ACTION%"=="test-experimental" goto :test_experimental
if /I "%ACTION%"=="test-all" goto :test_all

echo Usage: %~nx0 [clean^|build^|build-experimental^|check^|test^|test-experimental^|test-all] [test-args...]
exit /b 2

:build_core
set "EXTRA_DEFINE=%~1"
echo [BUILD] Target: %PROG% (define=%EXTRA_DEFINE%)
>"%BUILD_LOG%" (
  "%FPC_BIN%" -B -Mobjfpc -Sc -Si -O1 -g -gl -dDEBUG %EXTRA_DEFINE% -Fu"%ROOT%" -Fu"%ROOT%..\..\src" -Fi"%ROOT%..\..\src" -FE"%BIN_DIR%" -FU"%LIB_DIR%" -o"%BIN%" "%PROG%"
)
if errorlevel 1 (
  echo [BUILD] FAILED (see %BUILD_LOG%)
  type "%BUILD_LOG%"
  exit /b 1
)
echo [BUILD] OK
exit /b 0

:check_build_log
findstr /r /c:"src\\fafafa\.core\.simd\..*Warning:" /c:"src\\fafafa\.core\.simd\..*Hint:" "%BUILD_LOG%" >nul 2>nul
if not errorlevel 1 (
  echo [CHECK] Found warnings/hints from SIMD units in build log
  type "%BUILD_LOG%"
  exit /b 1
)
echo [CHECK] OK (no SIMD-unit warnings/hints)
exit /b 0

:run_tests
if not exist "%BIN%" (
  echo [TEST] Missing binary: %BIN%
  exit /b 2
)
set "NORMALIZED_TEST_ARGS=%TEST_ARGS:--list-suites=--list%"
echo [TEST] Running: %BIN% %NORMALIZED_TEST_ARGS%
"%BIN%" %NORMALIZED_TEST_ARGS% >"%TEST_LOG%" 2>&1
if errorlevel 1 (
  echo [TEST] FAILED (see %TEST_LOG%)
  type "%TEST_LOG%"
  exit /b 1
)
findstr /b /c:"Invalid option" "%TEST_LOG%" >nul 2>nul
if not errorlevel 1 (
  echo [TEST] FAILED: unsupported test argument
  type "%TEST_LOG%"
  exit /b 2
)
echo [TEST] OK
findstr /r /c:"^[1-9][0-9]* unfreed memory blocks" "%TEST_LOG%" >nul 2>nul
if not errorlevel 1 (
  echo [LEAK] FAILED: heaptrc reports unfreed blocks
  type "%TEST_LOG%"
  exit /b 1
)
echo [LEAK] OK
exit /b 0

:clean
echo [CLEAN] Removing bin/, lib/, logs/
if exist "%BIN_DIR%" rmdir /s /q "%BIN_DIR%"
if exist "%LIB_DIR%" rmdir /s /q "%LIB_DIR%"
if exist "%LOG_DIR%" rmdir /s /q "%LOG_DIR%"
exit /b 0

:build
call :build_core ""
exit /b %errorlevel%

:build_experimental
call :build_core "-dFAFAFA_SIMD_EXPERIMENTAL_INTRINSICS -dFAFAFA_SIMD_EXPERIMENTAL_TEST_BUILD"
exit /b %errorlevel%

:check
call :build_core ""
if errorlevel 1 exit /b 1
call :check_build_log
exit /b %errorlevel%

:test
call :build_core ""
if errorlevel 1 exit /b 1
call :check_build_log
if errorlevel 1 exit /b 1
call :run_tests
exit /b %errorlevel%

:test_experimental
call :build_core "-dFAFAFA_SIMD_EXPERIMENTAL_INTRINSICS -dFAFAFA_SIMD_EXPERIMENTAL_TEST_BUILD"
if errorlevel 1 exit /b 1
call :check_build_log
if errorlevel 1 exit /b 1
call :run_tests
exit /b %errorlevel%

:test_all
call "%~f0" test %TEST_ARGS%
if errorlevel 1 exit /b 1
call "%~f0" test-experimental %TEST_ARGS%
if errorlevel 1 exit /b 1
exit /b 0
