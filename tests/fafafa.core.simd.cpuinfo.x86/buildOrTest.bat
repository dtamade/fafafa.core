@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "ACTION=%~1"
if "%ACTION%"=="" set "ACTION=test"
if not "%~1"=="" shift

set "NORMALIZED_TEST_ARGS="
:collect_args
if "%~1"=="" goto :args_done
if /I "%~1"=="--list-suites" (
  set "NORMALIZED_TEST_ARGS=!NORMALIZED_TEST_ARGS! --list"
) else (
  set "NORMALIZED_TEST_ARGS=!NORMALIZED_TEST_ARGS! %~1"
)
shift
goto :collect_args
:args_done

set "ROOT=%~dp0"
set "PROJ=%ROOT%fafafa.core.simd.cpuinfo.x86.test.lpi"
set "BIN_DIR=%ROOT%bin"
set "LIB_DIR=%ROOT%lib"
set "BIN=%BIN_DIR%\fafafa.core.simd.cpuinfo.x86.test.exe"
set "LOG_DIR=%ROOT%logs"
set "BUILD_LOG=%LOG_DIR%\build.txt"
set "TEST_LOG=%LOG_DIR%\test.txt"
set "MODE=%FAFAFA_BUILD_MODE%"
if "%MODE%"=="" set "MODE=Release"

if not exist "%BIN_DIR%" mkdir "%BIN_DIR%"
if not exist "%LIB_DIR%" mkdir "%LIB_DIR%"
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

set "LAZBUILD_EXE=%LAZBUILD%"
if "%LAZBUILD_EXE%"=="" set "LAZBUILD_EXE=%ProgramFiles%\Lazarus\lazbuild.exe"
if not exist "%LAZBUILD_EXE%" set "LAZBUILD_EXE=lazbuild"

if /I "%ACTION%"=="debug" set "MODE=Debug"
if /I "%ACTION%"=="release" set "MODE=Release"

if /I "%ACTION%"=="clean" goto :clean
if /I "%ACTION%"=="build" goto :build
if /I "%ACTION%"=="check" goto :check
if /I "%ACTION%"=="test" goto :test
if /I "%ACTION%"=="debug" goto :test
if /I "%ACTION%"=="release" goto :test

echo Usage: %~nx0 [clean^|build^|check^|test^|debug^|release] [test-args...]
exit /b 2

:clean
echo [CLEAN] Removing bin, lib, logs
if exist "%BIN_DIR%" rmdir /s /q "%BIN_DIR%"
if exist "%LIB_DIR%" rmdir /s /q "%LIB_DIR%"
if exist "%LOG_DIR%" rmdir /s /q "%LOG_DIR%"
exit /b 0

:build
set "LAZARUS_MODE=%MODE%"
if /I "%LAZARUS_MODE%"=="Release" set "LAZARUS_MODE=Default"
echo [BUILD] Project: %PROJ% (mode=%MODE%, lazarus-mode=%LAZARUS_MODE%)
echo. > "%BUILD_LOG%"
"%LAZBUILD_EXE%" --build-mode=%LAZARUS_MODE% --build-all "%PROJ%" > "%BUILD_LOG%" 2>&1
if errorlevel 1 (
  echo [BUILD] FAILED (see %BUILD_LOG%)
  type "%BUILD_LOG%"
  exit /b 1
)
echo [BUILD] OK
exit /b 0

:check
call :build
if errorlevel 1 exit /b 1
findstr /r /c:"src\\fafafa\.core\.simd\..*Warning:" /c:"src\\fafafa\.core\.simd\..*Hint:" /c:"fafafa\.core\.simd\.cpuinfo\.x86\.testcase\.pas.*Warning:" /c:"fafafa\.core\.simd\.cpuinfo\.x86\.testcase\.pas.*Hint:" /c:"fafafa\.core\.simd\.cpuinfo\.x86\.test\.lpr.*Warning:" /c:"fafafa\.core\.simd\.cpuinfo\.x86\.test\.lpr.*Hint:" "%BUILD_LOG%" >nul 2>nul
if not errorlevel 1 (
  echo [CHECK] Found warnings/hints from SIMD units or cpuinfo.x86 test sources in build log
  type "%BUILD_LOG%"
  exit /b 1
)
echo [CHECK] OK (no SIMD-unit and cpuinfo.x86-test warnings/hints)
exit /b 0

:test
call :build
if errorlevel 1 exit /b 1
findstr /r /c:"src\\fafafa\.core\.simd\..*Warning:" /c:"src\\fafafa\.core\.simd\..*Hint:" /c:"fafafa\.core\.simd\.cpuinfo\.x86\.testcase\.pas.*Warning:" /c:"fafafa\.core\.simd\.cpuinfo\.x86\.testcase\.pas.*Hint:" /c:"fafafa\.core\.simd\.cpuinfo\.x86\.test\.lpr.*Warning:" /c:"fafafa\.core\.simd\.cpuinfo\.x86\.test\.lpr.*Hint:" "%BUILD_LOG%" >nul 2>nul
if not errorlevel 1 (
  echo [CHECK] Found warnings/hints from SIMD units or cpuinfo.x86 test sources in build log
  type "%BUILD_LOG%"
  exit /b 1
)

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
findstr /r /c:"Number of failures:[ ]*[1-9][0-9]*" /c:"Number of errors:[ ]*[1-9][0-9]*" /c:"Time:.* E:[1-9][0-9]*" /c:"Time:.* F:[1-9][0-9]*" "%TEST_LOG%" >nul 2>nul
if not errorlevel 1 (
  echo [TEST] FAILED: test runner reports failures/errors (see %TEST_LOG%)
  type "%TEST_LOG%"
  exit /b 1
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
