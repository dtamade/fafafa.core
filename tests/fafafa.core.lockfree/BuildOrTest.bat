@echo off

set "SCRIPT_DIR=%~dp0"

set "LAZBUILD=%SCRIPT_DIR%..\..\tools\lazbuild.bat"
set "ROOT_DIR=%SCRIPT_DIR%..\.."


set "PROJECT=fafafa.core.lockfree.tests.lpi"



set "TEST_EXECUTABLE=%SCRIPT_DIR%bin\lockfree_tests.exe"

REM Fast-branch: minimal/minimal-runner do not build the full test project
if /i "%1"=="minimal" goto :BRANCH
if /i "%1"=="minimal-runner" goto :BRANCH

echo Building project: %PROJECT%...
call "%LAZBUILD%" "%SCRIPT_DIR%%PROJECT%"

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo Build failed with error code %ERRORLEVEL%.
:SKIP_MAIN_BUILD
)

echo.
:BRANCH

echo Build successful.
echo.

REM Branch: minimal quick tests (standalone exe)
if /i "%1"=="minimal" (
    echo Running minimal standalone tests with log...
    call "%SCRIPT_DIR%Run_Minimal_With_Log.bat"
    set "RUN_IFACES=1"
) else if /i "%1"=="minimal-runner" (
    echo Building and running minimal suite runner with log...
    lazbuild --build-mode=Release "%SCRIPT_DIR%test_minimal_suite.lpi"
    if %ERRORLEVEL% NEQ 0 (
      echo Build failed with code %ERRORLEVEL%.
      exit /b %ERRORLEVEL%
    )
    set "RUNNER_EXE=%ROOT_DIR%\bin\test_minimal_suite.exe"
    if not exist "%RUNNER_EXE%" (
      echo Runner not found at %RUNNER_EXE%
      exit /b 1
    )
    set "LOG_DIR=%SCRIPT_DIR%logs"
    if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"
    set "LOG_FILE_MINRUN=%LOG_DIR%\latest_minimal_runner.log"
    echo [run] %RUNNER_EXE% > "%LOG_FILE_MINRUN%"
    "%RUNNER_EXE%" >> "%LOG_FILE_MINRUN%" 2>&1
    type "%LOG_FILE_MINRUN%"
    set "RUN_IFACES=1"
) else if /i "%1"=="test" (
    echo Running tests...
    "%TEST_EXECUTABLE%" --all --format=plain --progress
    set "RUN_IFACES=1"
) else (
    echo To run tests, call this script with 'test', 'minimal', or 'minimal-runner'.
    set "RUN_IFACES=1"
)

REM Always run interface/factories extended tests if script exists
  echo.
  echo Running queues smoke tests with log...
  if exist "%SCRIPT_DIR%Run_Smoke_Queues_With_Log.bat" (
    call "%SCRIPT_DIR%Run_Smoke_Queues_With_Log.bat"
  ) else (
    echo [warn] Run_Smoke_Queues_With_Log.bat not found
  )

if exist "%SCRIPT_DIR%build_ifaces_factories_tests.bat" (
  echo.
  echo Building and running interface/factories extended tests...
  call "%SCRIPT_DIR%build_ifaces_factories_tests.bat"
)

:END
