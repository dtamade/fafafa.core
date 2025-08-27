@echo off
setlocal
set LAZBUILD_EXE="D:\devtools\lazarus\trunk\lazarus\lazbuild.exe"
set PRJ=%~dp0example_gcm_bench.lpr

if not exist %LAZBUILD_EXE% (
  echo [error] lazbuild.exe not found: %LAZBUILD_EXE%
  exit /b 1
)

%LAZBUILD_EXE% --build-mode=Release %PRJ%
if errorlevel 1 exit /b 1

set EXE=%~dp0example_gcm_bench.exe
if exist %EXE% (
  echo.
  echo [run] %EXE%
  "%EXE%"
) else (
  echo [error] built exe not found: %EXE%
  exit /b 1
)

