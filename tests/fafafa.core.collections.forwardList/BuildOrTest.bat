@echo off
setlocal ENABLEDELAYEDEXPANSION

REM Use standard template with overrides
set "MODULE_NAME=forwardList"
set "PROJECT=%~dp0tests_forwardList.lpi"
set "LAZBUILD_ARGS=--build-mode=Debug"
set "TEST_EXE=%~dp0..\..\bin\tests_forwardList.exe"
call "%~dp0..\..\tools\test_template.bat" %*
exit /b %ERRORLEVEL%

set "SCRIPT_DIR=%~dp0"
set "LAZBUILD=%SCRIPT_DIR%..\..\tools\lazbuild.bat"
set "PROJECT=%SCRIPT_DIR%tests_forwardList.lpi"
set "TEST_EXECUTABLE=%SCRIPT_DIR%..\..\bin\tests_forwardList.exe"

echo Building project: %PROJECT%...
call "%LAZBUILD%" "%PROJECT%" --build-mode=Debug

if %ERRORLEVEL% NEQ 0 (
  echo.
  echo Build failed with error code %ERRORLEVEL%.
  goto END
)

echo.
echo Build successful.

if /i "%1"=="test" (
  echo.
  echo Running tests...
  "%TEST_EXECUTABLE%" --all --format=plain --progress > "%SCRIPT_DIR%results_plain.txt" 2>&1
  "%TEST_EXECUTABLE%" --all --format=xml --progress > "%SCRIPT_DIR%junit.xml" 2>&1
  echo Test run finished. See results_plain.txt and junit.xml
) else (
  echo.
  echo To run tests, call this script with the 'test' parameter.
)

:END
endlocal

