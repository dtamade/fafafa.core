@echo off
setlocal enabledelayedexpansion

REM Ensure working directory is this script's directory
pushd "%~dp0"

set "LAZBUILD=lazbuild"
set "PROJECT=fafafa.core.env.test.lpi"
set "EXE=bin\fafafa.core.env.test.exe"

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
    set "FINAL_RC=%ERRORLEVEL%"
    goto END
  )
) else (
  echo [WARN] lazbuild not found, compiling with fpc directly...
  fpc -Mobjfpc -Sh -O1 -g -gl -gh -Ci -Co -Cr -Ct -I../../src -Fu../../src -Fu. -FUlib -FEbin fafafa.core.env.test.lpr
  if %ERRORLEVEL% NEQ 0 (
    echo Compilation failed with error code %ERRORLEVEL%.
    set "FINAL_RC=%ERRORLEVEL%"
    goto END
  )
)

"%EXE%" --all --format=plain
set "FINAL_RC=%ERRORLEVEL%"

:END
popd

echo ExitCode=%FINAL_RC%
exit /b %FINAL_RC%

