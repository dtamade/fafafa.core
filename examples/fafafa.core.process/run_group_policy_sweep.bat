@echo off
setlocal enabledelayedexpansion
cd /d "%~dp0"

call build_group_policy_sweep.bat
if errorlevel 1 (
  echo [ERROR] Build failed, aborting run.
  exit /b 1
)

set EXE=bin\example_group_policy_sweep.exe
if not exist "%EXE%" (
  echo [ERROR] Executable not found: %EXE%
  exit /b 1
)

set MS=%~1
if "%MS%"=="" set MS=500

"%EXE%" %MS%
set EC=%ERRORLEVEL%
echo [INFO] ExitCode=%EC%
exit /b %EC%

