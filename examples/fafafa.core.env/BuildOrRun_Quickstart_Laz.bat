@echo off
setlocal

pushd "%~dp0"

set "LAZBUILD=lazbuild"
set "PROJECT=example_quickstart.lpi"
set "EXE=bin\example_quickstart.exe"

if exist bin rmdir /s /q bin
if exist lib rmdir /s /q lib
mkdir bin 2>nul
mkdir lib 2>nul

where lazbuild >nul 2>&1
if %errorlevel%==0 (
  echo Building with lazbuild...
  "%LAZBUILD%" "%PROJECT%" --build-mode=Debug
  if %ERRORLEVEL% NEQ 0 (
    echo Build failed with error code %ERRORLEVEL%.
    set "RC=%ERRORLEVEL%"
    goto END
  )
) else (
  echo [WARN] lazbuild not found, using fpc directly...
  fpc -Mobjfpc -Sh -O1 -g -gl -I../../src -Fu../../src -FUlib -FEbin example_quickstart.lpr
  if %ERRORLEVEL% NEQ 0 (
    echo Compilation failed with error code %ERRORLEVEL%.
    set "RC=%ERRORLEVEL%"
    goto END
  )
)

"%EXE%"
set "RC=%ERRORLEVEL%"

:END
popd

echo ExitCode=%RC%
exit /b %RC%

