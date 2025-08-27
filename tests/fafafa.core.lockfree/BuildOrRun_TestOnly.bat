@echo off
setlocal

set "SCRIPT_DIR=%~dp0"
set "ROOT_DIR=%SCRIPT_DIR%..\.."
set "BIN_DIR=%ROOT_DIR%\bin"

echo [1/2] Build tests (Debug) ...
lazbuild --build-mode=Debug "%SCRIPT_DIR%tests_lockfree.lpi"
if %ERRORLEVEL% NEQ 0 (
  echo Build failed with code %ERRORLEVEL%.
  exit /b %ERRORLEVEL%
)

echo [2/2] Run tests ...
"%BIN_DIR%\tests_lockfree.exe"
set "RC=%ERRORLEVEL%"
if %RC% NEQ 0 (
  echo Tests failed with code %RC%.
)
exit /b %RC%

