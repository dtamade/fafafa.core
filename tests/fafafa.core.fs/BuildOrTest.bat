@echo off
setlocal ENABLEDELAYEDEXPANSION

set "SCRIPT_DIR=%~dp0"
set "LAZBUILD=%SCRIPT_DIR%..\..\tools\lazbuild.bat"
set "PROJECT=%SCRIPT_DIR%tests_fs.lpi"
set "BIN=%SCRIPT_DIR%bin"
set "LIB=%SCRIPT_DIR%lib"
set "TEST_EXE=%BIN%\tests_fs.exe"

if not exist "%BIN%" mkdir "%BIN%"
if not exist "%LIB%" mkdir "%LIB%"


REM Guard against stale binary: remove previous test exe to avoid running old build on failure
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

echo Listing bin directory: %BIN%
dir "%BIN%"

REM Ensure test executable exists before attempting to run
if not exist "%TEST_EXE%" (
  echo ERROR: Test executable not found: %TEST_EXE%
  goto END
)

echo.
if /i "%1"=="test" (
  echo Running tests...
  echo %TEST_EXE%
  "%TEST_EXE%" --all --progress --format=plain
) else (
  echo To run tests, call this script with the 'test' parameter.
)

:END
endlocal

