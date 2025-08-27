@echo on
setlocal ENABLEDELAYEDEXPANSION
REM Build and run the temporary play VecDeque tests in plays\fafafa.core.collections.vecdeque

set SCRIPT_DIR=%~dp0
for %%I in ("%SCRIPT_DIR%..\..") do set ROOT=%%~fI

if not defined FPC_EXE set FPC_EXE=fpc
if not defined FPC_OPTS set FPC_OPTS=-Mobjfpc -Sh -g -gl -l -vewnhibq

set SRC_DIR="%ROOT%\src"
set TESTS_DIR="%ROOT%\tests"
set OUT_BIN_DIR="%ROOT%\bin\play"
set OUT_UNIT_DIR="%ROOT%\lib\play"
set PROG="%ROOT%\plays\fafafa.core.collections.vecdeque\Play_VecDeque_Tests.pas"
set OUT_EXE="%OUT_BIN_DIR%\Play_VecDeque_Tests.exe"

if not exist %OUT_BIN_DIR% mkdir %OUT_BIN_DIR%
if not exist %OUT_UNIT_DIR% mkdir %OUT_UNIT_DIR%

REM Logs in plays namespace dir
set LOG_DIR="%SCRIPT_DIR%"
set BUILD_LOG=%LOG_DIR%play_build.log
set RUN_LOG=%LOG_DIR%play_run.log
if exist %BUILD_LOG% del /f /q %BUILD_LOG%
if exist %RUN_LOG% del /f /q %RUN_LOG%

REM Compile
%FPC_EXE% %FPC_OPTS% -Fu%SRC_DIR% -Fu%TESTS_DIR% -FE%OUT_BIN_DIR% -FU%OUT_UNIT_DIR% %PROG% 1> %BUILD_LOG% 2>&1
set BUILD_EXIT=!ERRORLEVEL!
if not !BUILD_EXIT!==0 (
  echo [ERROR] Build failed with code !BUILD_EXIT!
  echo --- Build log ---
  type %BUILD_LOG%
  exit /b !BUILD_EXIT!
)

REM Run
%OUT_EXE% --all --format=plain 1> %RUN_LOG% 2>&1
set RUN_EXIT=!ERRORLEVEL!
if not !RUN_EXIT!==0 (
  echo [ERROR] Tests failed with code !RUN_EXIT!
  echo --- Test run log ---
  type %RUN_LOG%
) else (
  echo [OK] Tests passed.
  echo --- Test run log ---
  type %RUN_LOG%
)
exit /b !RUN_EXIT!

