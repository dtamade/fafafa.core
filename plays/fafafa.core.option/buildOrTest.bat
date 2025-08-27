@echo off
setlocal ENABLEDELAYEDEXPANSION
pushd "%~dp0"

set "LAZBUILD=..\..\tools\lazbuild.bat"
set "PROJECT=example_chain.lpi"
set "EXEC=bin\example_chain.exe"

if exist "%LAZBUILD%" (
  call "%LAZBUILD%" --build-all "%PROJECT%"
) else (
  where lazbuild >nul 2>nul
  if %ERRORLEVEL% EQU 0 (
    lazbuild --build-all "%PROJECT%"
  ) else (
    echo [WARN] lazbuild not found.
  )
)

if exist "%EXEC%" (
  echo [RUN] %EXEC%
  "%EXEC%"
)

popd
endlocal

