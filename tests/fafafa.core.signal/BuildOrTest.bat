@echo off
setlocal ENABLEDELAYEDEXPANSION

set "SCRIPT_DIR=%~dp0"
set "LAZBUILD=%SCRIPT_DIR%..\..\tools\lazbuild.bat"
set "PROJECT=%SCRIPT_DIR%fafafa.core.signal.test.lpi"
set "BIN=%SCRIPT_DIR%bin"
set "LIB=%SCRIPT_DIR%lib"
set "TEST_EXE=%BIN%\tests_signal.exe"

if not exist "%BIN%" mkdir "%BIN%"
if not exist "%LIB%" mkdir "%LIB%"

REM Guard stale exe
if exist "%TEST_EXE%" del /f /q "%TEST_EXE%"

echo [BUILD] Project: %PROJECT%
call "%LAZBUILD%" "%PROJECT%"
set "BUILD_ERR=%ERRORLEVEL%"
if !BUILD_ERR! NEQ 0 (
  echo [BUILD] FAILED code=!BUILD_ERR!
  goto END
) else (
  echo [BUILD] OK
)

echo.
if /i "%1"=="test" (
  echo Running tests...
  if exist "%TEST_EXE%" (
    set "FAFAFA_SIGNAL_TEST_DISABLE_WINCTRL=1"
    "%TEST_EXE%" --all --format=plain --progress
    set "TEST_ERR=%ERRORLEVEL%"
  ) else (
    echo [TEST] ERROR: Test executable not found: %TEST_EXE%
    set "TEST_ERR=1"
  )
  echo.
  echo [TEST] ExitCode=!TEST_ERR!
  if !TEST_ERR! NEQ 0 (
    echo [TEST] FAILED code=!TEST_ERR!
  ) else (
    echo [TEST] OK
  )
  exit /b !TEST_ERR!
) else (
  echo To run tests, call this script with the 'test' parameter.
)

:END
endlocal

