@echo off
setlocal
cd /d "%~dp0"

rem Use simple relative paths for robustness
set SRC=..\..\..\src
set BIN=.\bin
set LIB=.\lib

if not exist "%BIN%" mkdir "%BIN%"
if not exist "%LIB%" mkdir "%LIB%"

set FPC_FLAGS=-Mobjfpc -Scghi -gl -O2 -Fu%SRC% -FE%BIN% -FU%LIB%

fpc %FPC_FLAGS% example_canonicalize_vs_resolve.lpr
if %ERRORLEVEL% NEQ 0 (
  echo Build failed
  exit /b 1
)

"%BIN%\example_canonicalize_vs_resolve.exe"
exit /b %ERRORLEVEL%

