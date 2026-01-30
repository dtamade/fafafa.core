@echo off
setlocal ENABLEDELAYEDEXPANSION
REM Build and run palette_demo, tee output to a log file

REM Change to repo root (this script lives in examples\fafafa.core.color)
set SCRIPT_DIR=%~dp0
pushd "%SCRIPT_DIR%"
cd /d "%SCRIPT_DIR%\..\.."

if not exist tools\lazbuild.bat (
  echo [RunDemo] tools\lazbuild.bat not found. Make sure you run from the repo root.
  popd & endlocal & exit /b 1
)

call tools\lazbuild.bat --build-mode=Debug examples\fafafa.core.color\palette_demo.lpi
if errorlevel 1 (
  echo [RunDemo] Build failed. Aborting.
  popd & endlocal & exit /b 1
)

set LOG=examples\fafafa.core.color\palette_demo.log

REM Use PowerShell Tee-Object to write both console and file
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference='Stop'; ^
    if (Test-Path 'bin\\palette_demo.exe') { ^
      & 'bin\\palette_demo.exe' | Tee-Object -FilePath '%LOG%' ^
    } else { ^
      Write-Error 'bin\\palette_demo.exe not found after build.' ^
    }"

if errorlevel 1 (
  echo [RunDemo] Run failed.
  popd & endlocal & exit /b 1
)

echo [RunDemo] Log written to %LOG%

popd
endlocal

