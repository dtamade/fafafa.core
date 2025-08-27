@echo off
setlocal enabledelayedexpansion
set "SCRIPT_DIR=%~dp0"
set "LAZBUILD=lazbuild"

rem Project files
set "PROJECT=%SCRIPT_DIR%example_sync.lpr"
set "BIN_DIR=%SCRIPT_DIR%bin"
if not exist "%BIN_DIR%" mkdir "%BIN_DIR%"

rem Build Debug by default
lazbuild --build-mode=Debug "%PROJECT%"
if %ERRORLEVEL% NEQ 0 (
  echo Build failed with error %ERRORLEVEL%.
  exit /b %ERRORLEVEL%
)

set "EXE=%BIN_DIR%\example_sync.exe"
if exist "%EXE%" (
  echo Running example_sync...
  "%EXE%"
) else (
  echo Executable not found: %EXE%
  exit /b 1
)

