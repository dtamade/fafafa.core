@echo off
setlocal

pushd "%~dp0"

set "EXE=bin\example_arr_quickstart.exe"

if exist bin rmdir /s /q bin
if exist lib rmdir /s /q lib
mkdir bin 2>nul
mkdir lib 2>nul

REM Build with FPC directly to minimize dependencies
fpc -Mobjfpc -Sh -O1 -g -gl -I..\..\src -Fu..\..\src -FUlib -FEbin example_arr_quickstart.lpr
if %ERRORLEVEL% NEQ 0 (
  echo Compilation failed with error code %ERRORLEVEL%.
  set "RC=%ERRORLEVEL%"
  goto END
)

"%EXE%"
set "RC=%ERRORLEVEL%"

:END
popd

echo ExitCode=%RC%
exit /b %RC%

