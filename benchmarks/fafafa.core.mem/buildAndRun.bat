@echo off
setlocal enabledelayedexpansion

set BENCH_DIR=%~dp0
set ROOT_DIR=%BENCH_DIR%\..\..

if not exist "%BENCH_DIR%\bin" mkdir "%BENCH_DIR%\bin"
if not exist "%BENCH_DIR%\lib" mkdir "%BENCH_DIR%\lib"

echo Building benchmarks\fafafa.core.mem\bench_blockpool.lpr ...
fpc -Mobjfpc -Sh -O2 ^
  -Fu"%ROOT_DIR%\src" ^
  -FE"%BENCH_DIR%\bin" ^
  -FU"%BENCH_DIR%\lib" ^
  "%BENCH_DIR%\bench_blockpool.lpr"
if errorlevel 1 exit /b 1

echo Running...
"%BENCH_DIR%\bin\bench_blockpool.exe" %*

endlocal

