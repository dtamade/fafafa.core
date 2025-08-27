@echo off
setlocal ENABLEDELAYEDEXPANSION
REM Build and run the temporary play VecDeque tests

set SCRIPT_DIR=%~dp0
REM Root of repo relative to this script (tests\play\vecdeque\..\..\..)
for %%I in ("%SCRIPT_DIR%..\..\..") do set ROOT=%%~fI

if not defined FPC_EXE set FPC_EXE=fpc
if not defined FPC_OPTS set FPC_OPTS=-Mobjfpc -Sh -g -gl -l -vewnhibq

set SRC_DIR="%ROOT%\src"
set TESTS_DIR="%ROOT%\tests"
set OUT_BIN_DIR="%ROOT%\bin\play"
set OUT_UNIT_DIR="%ROOT%\lib\play"
set PROG="%ROOT%\tests\play\vecdeque\Play_VecDeque_Tests.pas"
set OUT_EXE="%OUT_BIN_DIR%\Play_VecDeque_Tests.exe"

if not exist %OUT_BIN_DIR% mkdir %OUT_BIN_DIR%
if not exist %OUT_UNIT_DIR% mkdir %OUT_UNIT_DIR%

REM Compile
%FPC_EXE% %FPC_OPTS% -Fu%SRC_DIR% -Fu%TESTS_DIR% -FE%OUT_BIN_DIR% -FU%OUT_UNIT_DIR% %PROG%
if errorlevel 1 (
  echo [ERROR] Build failed with code !ERRORLEVEL!
  exit /b !ERRORLEVEL!
)

REM Run
%OUT_EXE%
set RUN_EXIT=!ERRORLEVEL!
if not %RUN_EXIT%==0 (
  echo [ERROR] Tests failed with code !RUN_EXIT!
) else (
  echo [OK] Tests passed.
)
exit /b %RUN_EXIT%

