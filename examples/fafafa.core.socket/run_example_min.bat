@echo off
setlocal ENABLEDELAYEDEXPANSION

set "DIR=%~dp0"
set "BIN=%DIR%bin"
set "SERVER=%BIN%\echo_server.exe"
set "CLIENT=%BIN%\example_echo_min_poll_nb.exe"

if not exist "%SERVER%" (
  echo [run_example_min] server not found. Building examples...
  call "%DIR%build_examples.bat"
)
if not exist "%SERVER%" (
  echo [run_example_min] server still not found at "%SERVER%".
  exit /b 1
)
if not exist "%CLIENT%" (
  echo [run_example_min] client not found. Building examples...
  call "%DIR%build_examples.bat"
)
if not exist "%CLIENT%" (
  echo [run_example_min] client still not found at "%CLIENT%".
  exit /b 1
)

echo [run_example_min] starting server on port 8080...
start "echo_server" "%SERVER%" --port=8080
ping -n 2 127.0.0.1 >nul

echo [run_example_min] running minimal client...
"%CLIENT%"

endlocal

