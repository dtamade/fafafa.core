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
set "OUTPUT_ROOT=%SIMD_OUTPUT_ROOT%"
if "%OUTPUT_ROOT%"=="" set "OUTPUT_ROOT=%ROOT%"
set "PROJ=%ROOT%fafafa.core.simd.cpuinfo.x86.test.lpi"
set "LAZBUILD_EXE=%LAZBUILD%"
if "%LAZBUILD_EXE%"=="" set "LAZBUILD_EXE=%ProgramFiles%\Lazarus\lazbuild.exe"
if not exist "%LAZBUILD_EXE%" set "LAZBUILD_EXE=lazbuild"
set "FPC_EXE=%FPC_BIN%"
if "%FPC_EXE%"=="" set "FPC_EXE=fpc"
set "TARGET_CPU="
for /f "delims=" %%I in ('%FPC_EXE% -iTP 2^>nul') do if not defined TARGET_CPU set "TARGET_CPU=%%I"
if not defined TARGET_CPU set "TARGET_CPU=nativecpu"
set "TARGET_OS="
for /f "delims=" %%I in ('%FPC_EXE% -iTO 2^>nul') do if not defined TARGET_OS set "TARGET_OS=%%I"
if not defined TARGET_OS set "TARGET_OS=nativeos"
set "BIN_DIR=%OUTPUT_ROOT%\bin"
set "LIB_DIR=%OUTPUT_ROOT%\lib\%TARGET_CPU%-%TARGET_OS%"
set "BIN=%BIN_DIR%\fafafa.core.simd.cpuinfo.x86.test.exe"
set "LOG_DIR=%OUTPUT_ROOT%\logs"
set "BUILD_LOG=%LOG_DIR%\build.txt"
set "TEST_LOG=%LOG_DIR%\test.txt"
set "MODE=%FAFAFA_BUILD_MODE%"
if "%MODE%"=="" set "MODE=Debug"

if not exist "%BIN_DIR%" mkdir "%BIN_DIR%"
if not exist "%LIB_DIR%" mkdir "%LIB_DIR%"
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

if /I "%ACTION%"=="clean" goto :clean
if /I "%ACTION%"=="build" goto :build
if /I "%ACTION%"=="check" goto :check
if /I "%ACTION%"=="debug" goto :debug
if /I "%ACTION%"=="release" goto :release
if /I "%ACTION%"=="test" goto :test

echo Usage: %%~nx0 [clean^|build^|check^|test^|debug^|release] [test-args...]
echo Isolation env: SIMD_OUTPUT_ROOT=C:\temp\simd-cpuinfo-x86-run-123 ^(override bin/lib/logs root^)
exit /b 2

:clean
echo [CLEAN] Removing %BIN_DIR%, %OUTPUT_ROOT%\lib, %LOG_DIR%
if exist "%BIN_DIR%" rmdir /s /q "%BIN_DIR%"
if exist "%OUTPUT_ROOT%\lib" rmdir /s /q "%OUTPUT_ROOT%\lib"
if exist "%LOG_DIR%" rmdir /s /q "%LOG_DIR%"
exit /b 0

:build
echo [BUILD] Project: %PROJ% ^(mode=%MODE%, output_root=%OUTPUT_ROOT%^)
echo. > "%BUILD_LOG%"
if not exist "%BIN_DIR%" mkdir "%BIN_DIR%"
if not exist "%LIB_DIR%" mkdir "%LIB_DIR%"
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"
"%LAZBUILD_EXE%" --build-mode=%MODE% --build-all "--opt=-FE%BIN_DIR%" "--opt=-FU%LIB_DIR%" "%PROJ%" > "%BUILD_LOG%" 2>&1
if errorlevel 1 (
  echo [BUILD] FAILED ^(see %BUILD_LOG%^)
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
findstr /r /c:"src\\.*Warning:" /c:"src\\.*Hint:" "%BUILD_LOG%" >nul 2>nul
if not errorlevel 1 (
  echo [CHECK] Found warnings/hints from src/ in build log
  type "%BUILD_LOG%"
  exit /b 1
)
echo [CHECK] OK ^(no src/ warnings/hints^)
exit /b 0

:debug
set "MODE=Debug"
call :test %NORMALIZED_TEST_ARGS%
exit /b %ERRORLEVEL%

:release
set "MODE=Release"
call :test %NORMALIZED_TEST_ARGS%
exit /b %ERRORLEVEL%

:test
call :build
if errorlevel 1 exit /b 1
echo [TEST] Running: %BIN% %NORMALIZED_TEST_ARGS%
echo. > "%TEST_LOG%"
"%BIN%" %NORMALIZED_TEST_ARGS% > "%TEST_LOG%" 2>&1
set "RUN_RC=%ERRORLEVEL%"
if not "%RUN_RC%"=="0" (
  echo [TEST] FAILED rc=%RUN_RC% ^(see %TEST_LOG%^)
  type "%TEST_LOG%"
  exit /b %RUN_RC%
)
findstr /b /c:"Invalid option" "%TEST_LOG%" >nul 2>nul
if not errorlevel 1 (
  echo [TEST] FAILED: invalid option reported by test runner
  type "%TEST_LOG%"
  exit /b 2
)
findstr /r /c:"^[1-9][0-9]* unfreed memory blocks" "%TEST_LOG%" >nul 2>nul
if not errorlevel 1 (
  echo [LEAK] FAILED: heaptrc reports unfreed blocks
  type "%TEST_LOG%"
  exit /b 1
)
echo [TEST] OK
echo [LEAK] OK
exit /b 0
