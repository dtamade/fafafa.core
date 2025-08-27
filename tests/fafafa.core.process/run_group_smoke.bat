@echo off
setlocal ENABLEDELAYEDEXPANSION
set "SCRIPT_DIR=%~dp0"
set "PROJECT_DIR=%SCRIPT_DIR%"
set "RUN_BUILD=%PROJECT_DIR%buildOrTest.bat"

if not exist "%RUN_BUILD%" (
  echo ERROR: buildOrTest.bat not found under %PROJECT_DIR%
  exit /b 1
)

REM Quick smoke: build then run all tests (group tests are part of suite)
call "%RUN_BUILD%" test
exit /b %ERRORLEVEL%

