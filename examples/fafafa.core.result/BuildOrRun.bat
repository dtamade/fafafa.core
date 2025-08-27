@echo off
setlocal ENABLEDELAYEDEXPANSION
pushd "%~dp0"

set "LAZBUILD=..\..\tools\lazbuild.bat"
set "LPI=example_result_chain.lpi"
set "BIN=bin\example_result_chain.exe"

if "%1"=="filters" (
  set "LPI=example_result_filters_and_try.lpi"
  set "BIN=bin\example_result_filters_and_try.exe"
)


if not exist "%LAZBUILD%" (
  where lazbuild >nul 2>nul
  if %ERRORLEVEL% EQU 0 (
    echo [INFO] Using lazbuild from PATH.
    set "LAZBUILD=lazbuild"
  ) else (
    echo [ERROR] lazbuild not found. Aborting.
    exit /b 1
  )
)

if not exist lib mkdir lib >nul 2>nul
if not exist bin mkdir bin >nul 2>nul

call "%LAZBUILD%" --build-all "%LPI%"
if not %ERRORLEVEL% EQU 0 (
  echo [BUILD] FAILED
  popd & endlocal & exit /b 1
)

echo [RUN]
"%BIN%"
set "RC=%ERRORLEVEL%"

popd
endlocal
exit /b %RC%

