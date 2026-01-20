@echo off
setlocal ENABLEDELAYEDEXPANSION

pushd "%~dp0"

set "LAZBUILD=..\..\tools\lazbuild.bat"
set "PROJECT=tests_term_ui.lpi"
set "TEST_EXECUTABLE=bin\tests.exe"

if exist "%LAZBUILD%" (
  echo [BUILD] Project: %PROJECT%
  call "%LAZBUILD%" "%PROJECT%"
  set "BUILD_ERR=%ERRORLEVEL%"
) else (
  echo [WARN] tools\lazbuild.bat not found. Skipping build step.
  set "BUILD_ERR=1"
)

if !BUILD_ERR! EQU 0 (
  echo [BUILD] OK
) else (
  echo [BUILD] FAILED code=!BUILD_ERR!
)

if /i "%1"=="test" (
  if exist "%TEST_EXECUTABLE%" (
    echo Running tests...
    "%TEST_EXECUTABLE%" -a -p --format=plain
    set "ERR=!ERRORLEVEL!"
    echo Test runner exit code: !ERR!
    popd & endlocal & exit /b !ERR!
  ) else (
    echo [ERROR] Test executable not found: %TEST_EXECUTABLE%
    popd & endlocal & exit /b !BUILD_ERR!
  )
) else (
  echo To run tests, call this script with the 'test' parameter.
  if !BUILD_ERR! NEQ 0 (popd & endlocal & exit /b !BUILD_ERR!) else (popd & endlocal & exit /b 0)
)
