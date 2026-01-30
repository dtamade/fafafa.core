@echo off
setlocal enabledelayedexpansion
cd /d "%~dp0"

call build_wmclose_child_gui.bat
if errorlevel 1 (
  echo [ERROR] Build failed, aborting run.
  exit /b 1
)

set EXE=bin\example_wmclose_child_gui.exe
if not exist "%EXE%" (
  echo [ERROR] Executable not found: %EXE%
  exit /b 1
)

"%EXE%"

