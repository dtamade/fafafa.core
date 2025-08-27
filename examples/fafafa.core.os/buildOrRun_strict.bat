@echo off
setlocal ENABLEDELAYEDEXPANSION
pushd "%~dp0"

set "LAZBUILD=..\..\tools\lazbuild.bat"
set "PROJECT=example_strict.lpi"
set "EXE=bin\example_strict.exe"

if not exist "%LAZBUILD%" (
  where lazbuild >nul 2>nul
  if %ERRORLEVEL% EQU 0 (
    echo [INFO] Using lazbuild from PATH.
    set "LAZBUILD=lazbuild"
  ) else (
    echo [ERROR] lazbuild not found.
    popd & endlocal & exit /b 1
  )
)

call "%LAZBUILD%" --build-all "%PROJECT%"
if errorlevel 1 (
  echo [BUILD] failed.
  popd & endlocal & exit /b 1
)

if exist "%EXE%" (
  "%EXE%"
) else (
  echo [ERROR] Executable not found: %EXE%
  popd & endlocal & exit /b 1
)

