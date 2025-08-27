@echo off
setlocal EnableDelayedExpansion

REM Locate lazbuild: env > common paths > PATH
set LAZBUILD_EXE=%LAZBUILD_EXE%
if not defined LAZBUILD_EXE (
  for %%P in ("C:\lazarus\lazbuild.exe" "D:\devtools\lazarus\trunk\lazarus\lazbuild.exe") do (
    if exist %%~fP set LAZBUILD_EXE=%%~fP
  )
)
where lazbuild.exe >nul 2>&1
if not errorlevel 1 if not defined LAZBUILD_EXE set LAZBUILD_EXE=lazbuild.exe

if not defined LAZBUILD_EXE (
  echo [error] lazbuild.exe not found. Set LAZBUILD_EXE or ensure it is in PATH.
  exit /b 1
)

echo [info] Using lazbuild: %LAZBUILD_EXE%
set SCRIPT_DIR=%~dp0
set PRJ=%SCRIPT_DIR%file_encryption.lpr

"%LAZBUILD_EXE%" --bm=Release "%PRJ%"
if errorlevel 1 (
  echo [error] build failed with exit code !errorlevel!
  exit /b !errorlevel!
)

set EXE=%SCRIPT_DIR%file_encryption.exe
if exist "%EXE%" (
  echo.
  echo [run] "%EXE%"
  "%EXE%"
) else (
  echo [error] built exe not found: %EXE%
  exit /b 1
)

