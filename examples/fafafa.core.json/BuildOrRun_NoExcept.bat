@echo off
setlocal
set "SCRIPT_DIR=%~dp0"
set "LAZBUILD=%SCRIPT_DIR%..\..\tools\lazbuild.bat"
set "PROJECT=%SCRIPT_DIR%example_json_noexcept.lpr"
set "BIN_DIR=%SCRIPT_DIR%bin"
if not exist "%BIN_DIR%" mkdir "%BIN_DIR%"

call "%LAZBUILD%" "%PROJECT%"
if %ERRORLEVEL% NEQ 0 (
  echo [BUILD] FAILED code=%ERRORLEVEL%
  exit /b %ERRORLEVEL%
)

if %ERRORLEVEL% NEQ 0 (
  echo Build failed with error %ERRORLEVEL%.
  exit /b %ERRORLEVEL%
)

set "EXE=%BIN_DIR%\example_json_noexcept.exe"
if exist "%EXE%" (
  echo [RUN] example_json_noexcept
  "%EXE%" || (echo [RUN] FAILED code=%ERRORLEVEL% & exit /b %ERRORLEVEL%)
) else (
  echo Executable not found: %EXE%
)

