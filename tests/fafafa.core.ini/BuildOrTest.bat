@echo off
setlocal

set "SCRIPT_DIR=%~dp0"
pushd "%SCRIPT_DIR%"

set "LAZBUILD=..\..\tools\lazbuild.bat"
if not exist "%LAZBUILD" (
  echo [WARN] tools\lazbuild.bat not found, falling back to lazbuild in PATH
  set "LAZBUILD=lazbuild"
)

set "PROJECT=fafafa.core.ini.test.lpi"
set "EXE=bin\fafafa.core.ini.test.exe"

if exist bin rmdir /s /q bin
if exist lib rmdir /s /q lib
mkdir bin 2>nul
mkdir lib 2>nul

echo Building project: %PROJECT% ...
call "%LAZBUILD%" "%PROJECT%" --build-mode=Debug
if %ERRORLEVEL% NEQ 0 (
  echo Build failed with error code %ERRORLEVEL%.
  set "FINAL_RC=%ERRORLEVEL%"
  goto END
)

echo.
echo Build successful.

echo.
if /i "%1"=="test" (
  echo Running tests...
  "%EXE%" --all --format=plain --progress
  set "FINAL_RC=%ERRORLEVEL%"
) else (
  echo To run tests, call this script with the 'test' parameter.
  set "FINAL_RC=0"
)

:END
popd
endlocal
exit /b %FINAL_RC%

