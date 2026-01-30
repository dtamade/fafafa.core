@echo off
setlocal ENABLEDELAYEDEXPANSION
REM build and/or run fafafa.core.socket.poller tests (ASCII-only, no line continuations)

set "TEST_DIR=%~dp0"
cd /d "%TEST_DIR%"

set "BIN_DIR=bin"
set "LIB_DIR=lib"

if not exist "%BIN_DIR%" mkdir "%BIN_DIR%"
if not exist "%LIB_DIR%" mkdir "%LIB_DIR%"

REM build
call ..\..\tools\lazbuild.bat --build-mode=debug -B fafafa.core.socket.poller.test.lpi
if errorlevel 1 (
  echo [ERROR] build failed
  exit /b 1
)

REM run tests if requested
if /I "%1"=="test" (
  .\bin\fafafa_core_socket_poller_test.exe --all --format=plain --progress
  exit /b %ERRORLEVEL%
)

endlocal
exit /b 0
