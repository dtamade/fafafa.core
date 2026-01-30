@echo off
setlocal EnableDelayedExpansion

REM Try to locate lazbuild.exe: prefer env, then common path, else PATH
set LAZBUILD_EXE=%LAZBUILD_EXE%
if not defined LAZBUILD_EXE (
  for %%P in ("C:\lazarus\lazbuild.exe" "D:\devtools\lazarus\trunk\lazarus\lazbuild.exe") do (
    if exist %%~fP set LAZBUILD_EXE=%%~fP
  )
)

where lazbuild.exe >nul 2>&1
if not errorlevel 1 (
  if not defined LAZBUILD_EXE set LAZBUILD_EXE=lazbuild.exe
)

if not defined LAZBUILD_EXE (
  echo [error] lazbuild.exe not found. Please set LAZBUILD_EXE or ensure it is in PATH.
  echo        Example: set LAZBUILD_EXE=D:\devtools\lazarus\trunk\lazarus\lazbuild.exe
  exit /b 1
)

echo [info] Using lazbuild: %LAZBUILD_EXE%
set SCRIPT_DIR=%~dp0
set PRJ_LPI=%SCRIPT_DIR%example_aead_inplace_append_min.lpi
set PRJ_PAS=%SCRIPT_DIR%example_aead_inplace_append_min.pas

if exist "%PRJ_LPI%" (
  echo [build] lpi: "%PRJ_LPI%"
  "%LAZBUILD_EXE%" --bm=Release --cpu=x86_64 --os=win64 "%PRJ_LPI%"
  set BUILD_RC=!errorlevel!
) else (
  echo [warn] .lpi not found, building .pas directly (ensure src path is discoverable)
  "%LAZBUILD_EXE%" --bm=Release --cpu=x86_64 --os=win64 "%PRJ_PAS%"
  set BUILD_RC=!errorlevel!
)

if not !BUILD_RC! == 0 (
  echo [error] build failed with exit code !BUILD_RC!
  echo        Hint: verify lazbuild can resolve src path (OtherUnitFiles=..\..\src) and permissions.
  exit /b !BUILD_RC!
)

set EXE=%SCRIPT_DIR%example_aead_inplace_append_min.exe
if exist "%EXE%" (
  echo.
  echo [run] "%EXE%"
  "%EXE%"
) else (
  echo [error] built exe not found: %EXE%
  echo        Hint: check Target.Filename in .lpi or the default output location.
  exit /b 1
)

