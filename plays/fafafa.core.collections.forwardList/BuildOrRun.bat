@echo off
setlocal
set HERE=%~dp0
set ROOT=%HERE%..\..\..

set BIN=%ROOT%\bin
set LIB=%ROOT%\lib
set LIBCPU=%LIB%\x86_64-win64

if not exist "%BIN%" mkdir "%BIN%"
if not exist "%LIB%" mkdir "%LIB%"
if not exist "%LIBCPU%" mkdir "%LIBCPU%"

lazbuild --bm=Default --cpu=x86_64 --os=win64 "%HERE%plays_forwardlist.lpi"
if %errorlevel% neq 0 (
  echo Build failed
  exit /b 1
)

"%LIBCPU%\plays_forwardlist.exe"

