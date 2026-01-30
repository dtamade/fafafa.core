@echo off
setlocal
set "SCRIPT_DIR=%~dp0"
set "LAZBUILD=%SCRIPT_DIR%..\..\tools\lazbuild.bat"
set "PROJECT=%SCRIPT_DIR%example_json.lpr"
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

set "EXE=%BIN_DIR%\example_json.exe"
if exist "%EXE%" (
  echo [RUN] example_json
  "%EXE%" || (echo [RUN] FAILED code=%ERRORLEVEL% & exit /b %ERRORLEVEL%)
) else (
  echo Executable not found: %EXE%
  exit /b 1
)

rem Build minimal single-file examples
for %%F in (example_reader_flags.lpr example_stop_when_done.lpr) do (
  echo Building %%F...
  call "%LAZBUILD%" "%%~fF"
  if errorlevel 1 exit /b 1
)

rem Run minimal examples
"%BIN_DIR%\example_reader_flags.exe" || (echo [RUN] example_reader_flags FAILED code=%ERRORLEVEL% & exit /b %ERRORLEVEL%)
"%BIN_DIR%\example_stop_when_done.exe" || (echo [RUN] example_stop_when_done FAILED code=%ERRORLEVEL% & exit /b %ERRORLEVEL%)
