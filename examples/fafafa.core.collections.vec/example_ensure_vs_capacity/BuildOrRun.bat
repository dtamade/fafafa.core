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

REM Build with FPC directly to avoid lazbuild option incompatibilities
fpc -B -gl -gh -O1 -MObjFPC -Sc -Fu"%ROOT%\src" -FE"%BIN%" -FU"%LIBCPU%" "%HERE%example_ensure_vs_capacity.lpr"
if %errorlevel% neq 0 (
  echo Build failed
  exit /b 1
)

"%BIN%\example_ensure_vs_capacity.exe"

