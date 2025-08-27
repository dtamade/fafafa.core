@echo off
setlocal ENABLEDELAYEDEXPANSION

set FPCEXE="D:\devtools\lazarus\trunk\fpc\bin\x86_64-win64\fpc.exe"

REM Change to tests directory so the .lpr is in CWD
pushd "%~dp0"

REM Ensure unit output directory for faster incremental builds
set UNIT_OUT=lib_quick\x86_64-win64
if not exist "%UNIT_OUT%" mkdir "%UNIT_OUT%"
if not exist "bin" mkdir "bin"

REM Build reporters_quick with -FU (faster incremental)
%FPCEXE% -MObjFPC -Scaghi ^
  -Fu"..\..\src" ^
  -Fu"." ^
  -Fi"." ^
  -FE"bin" ^
  -FU"%UNIT_OUT%" ^
  reporters_quick.lpr
if errorlevel 1 (
  echo Build failed with errorlevel %errorlevel%
  popd
  exit /b %errorlevel%
)

REM Run
pushd "bin"
reporters_quick.exe
set EC=%ERRORLEVEL%
popd
popd

exit /b %EC%

