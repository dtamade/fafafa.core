@echo off
setlocal enabledelayedexpansion
cd /d "%~dp0"
set OUTDIR=bin
set LIBDIR=lib
if not exist "%OUTDIR%" mkdir "%OUTDIR%"
if not exist "%LIBDIR%" mkdir "%LIBDIR%"

set FPC_EXE="%LAZARUSDIR%\fpc\bin\x86_64-win64\fpc.exe"
if not exist %FPC_EXE% set FPC_EXE=fpc

%FPC_EXE% -MObjFPC -Scaghi -CirotR -O1 -gw3 -gl -gh -Xg -gt -vewnhibq ^
  -dFAFAFA_PROCESS_SHELLEXECUTE_MINIMAL -dFAFAFA_PROCESS_GROUPS ^
  -Fi"%CD%\%LIBDIR%" ^
  -Fi"%CD%\..\..\src" ^
  -Fu"%CD%\..\..\src" ^
  -FU"%CD%\%LIBDIR%" ^
  -FE"%CD%\%OUTDIR%" ^
  -o"%CD%\%OUTDIR%\example_group_policy.exe" ^
  example_group_policy.lpr

if errorlevel 1 (
  echo [ERROR] Build failed.
  exit /b 1
) else (
  echo [OK] Built: %OUTDIR%\example_group_policy.exe
)

