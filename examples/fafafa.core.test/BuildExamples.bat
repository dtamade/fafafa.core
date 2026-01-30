@echo off
setlocal ENABLEDELAYEDEXPANSION
cd /d "%~dp0"
set "LAZBUILD=..\..\tools\lazbuild.bat"
set "PROJECT=%CD%\example_fafafa.core.test.lpi"
set "BIN=%CD%\bin"
set "LIB=%CD%\lib"

if exist "%BIN%" rmdir /s /q "%BIN%"
if exist "%LIB%" rmdir /s /q "%LIB%"
mkdir "%BIN%" 2>nul
mkdir "%LIB%" 2>nul

call "%LAZBUILD%" "%PROJECT%"
call "%LAZBUILD%" "%CD%\example_snapshots.lpi"
if %ERRORLEVEL% NEQ 0 (
  echo Build failed with code %ERRORLEVEL%.
  exit /b %ERRORLEVEL%
)

echo Build OK. Output in %BIN%
exit /b 0

