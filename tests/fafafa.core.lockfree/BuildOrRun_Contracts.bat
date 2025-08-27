@echo off
setlocal enabledelayedexpansion

set "SCRIPT_DIR=%~dp0"
set "LAZBUILD=%SCRIPT_DIR%..\..\tools\lazbuild.bat"

set "PROJECT=contracts_runner.lpr"
set "BIN_DIR=%SCRIPT_DIR%bin"
set "LIB_DIR=%SCRIPT_DIR%lib"

if not exist "%BIN_DIR%" mkdir "%BIN_DIR%"
if not exist "%LIB_DIR%" mkdir "%LIB_DIR%"

pushd "%SCRIPT_DIR%"

"%LAZBUILD%" --build-mode=Debug "%PROJECT%"
if %ERRORLEVEL% NEQ 0 (
  echo Build failed with error code %ERRORLEVEL%.
  popd
  exit /b %ERRORLEVEL%
)

set "EXE=%SCRIPT_DIR%contracts_runner.exe"
if exist "%EXE%" (
  echo Running contracts_runner.exe ...
  "%EXE%"
) else (
  echo contracts_runner.exe not found. Please open contracts_runner.lpr in Lazarus and build manually.
)

popd
endlocal

