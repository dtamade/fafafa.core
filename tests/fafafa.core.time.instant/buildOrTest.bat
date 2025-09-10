@echo off
setlocal
cd /d "%~dp0"

set LPI=fafafa.core.time.instant.test.lpi
set EXE=bin\fafafa.core.time.instant.test.exe

lazbuild --build-mode=Debug -B "%LPI%"
if errorlevel 1 (
  echo Build failed.
  exit /b 1
)

if not exist "%EXE%" (
  echo Executable not found: %EXE%
  exit /b 2
)

"%EXE%" %*
exit /b %errorlevel%

