@echo off
setlocal

set "SCRIPT_DIR=%~dp0"
set "LAZBUILD=%SCRIPT_DIR%..\..\tools\lazbuild.bat"
set "PROJECT=fafafa.core.lockfree.tests.lpi"

echo [BuildOnly] Building %PROJECT% ...
call "%LAZBUILD%" "%SCRIPT_DIR%%PROJECT%"
set "RC=%ERRORLEVEL%"
if %RC% NEQ 0 (
  echo [BuildOnly] Build failed with code %RC%
  exit /b %RC%
) else (
  echo [BuildOnly] Build successful.
)
exit /b 0
exit /b 0

