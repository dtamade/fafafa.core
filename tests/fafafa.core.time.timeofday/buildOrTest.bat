@echo off
setlocal enabledelayedexpansion
cd /d "%~dp0"

set LPI=fafafa.core.time.timeofday.test.lpi
set EXE=bin\fafafa.core.time.timeofday.test.exe

REM Build in Debug with heap tracing
lazbuild --build-mode=Debug -B "%LPI%"
if errorlevel 1 (
  echo Build failed.
  exit /b 1
)

if not exist "%EXE%" (
  echo Executable not found: %EXE%
  exit /b 2
)

"%EXE%" --all --format=plain %*
exit /b %errorlevel%

