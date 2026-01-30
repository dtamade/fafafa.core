@echo off
setlocal ENABLEDELAYEDEXPANSION

REM Unified entry: subcommands [resolve|walk|all]
set "SUBCMD=%~1"
if /I "%SUBCMD%"=="resolve" goto do_resolve
if /I "%SUBCMD%"=="walk"    goto do_walk
if /I "%SUBCMD%"=="all"     goto do_all


:continue_legacy


echo === fafafa.core.fs perf benchmark: build and run perf_fs_bench ===

set "SCRIPT_DIR=%~dp0"
set "ROOT_DIR=%SCRIPT_DIR%..\.."
set "SRC_DIR=%ROOT_DIR%\src"
set "LIB_DIR=%SCRIPT_DIR%lib"
set "BIN_DIR=%SCRIPT_DIR%bin"
set "EXE=%BIN_DIR%\perf_fs_bench.exe"

if not exist "%LIB_DIR%" mkdir "%LIB_DIR%"
if not exist "%BIN_DIR%" mkdir "%BIN_DIR%"

REM Compiler options
set "FPC_OPTS=-MObjFPC -Scghi -O2 -XX -CX -Si -vewnhibq"
set "FPC_PATHS=-Fu%SRC_DIR% -FU%LIB_DIR% -FE%BIN_DIR%"

echo [1/2] Compiling: perf_fs_bench.lpr ...
pushd "%SCRIPT_DIR%"
fpc %FPC_OPTS% %FPC_PATHS% "perf_fs_bench.lpr"
set "ERR=%ERRORLEVEL%"
popd
if not "%ERR%"=="0" (
  echo.
  echo Build failed with error code %ERR%.
  exit /b %ERR%
)

echo.
echo [OK] Build successful.
echo.

echo [2/2] Running benchmark...
if exist "%EXE%" (

:do_resolve
REM args: root iters
set ROOT=%~2
if "%ROOT%"=="" set ROOT=tests\fafafa.core.fs\walk_bench_root
set ITERS=%~3
if "%ITERS%"=="" set ITERS=2000
call tests\fafafa.core.fs\BuildOrRunWalkPerf.bat >nul 2>&1
call tests\fafafa.core.fs\bin\perf_resolve_bench.exe "%ROOT%" %ITERS%
call tests\fafafa.core.fs\tools\Compare-Resolve-Perf.bat tests\fafafa.core.fs\performance-data\perf_resolve_baseline.txt tests\fafafa.core.fs\performance-data\perf_resolve_latest.txt 25
exit /b %ERRORLEVEL%

:do_walk
call tests\fafafa.core.fs\BuildOrRunWalkPerf.bat
exit /b %ERRORLEVEL%

:do_all
set ROOT=%~2
if "%ROOT%"=="" set ROOT=tests\fafafa.core.fs\walk_bench_root
set ITERS=%~3
if "%ITERS%"=="" set ITERS=2000
call tests\fafafa.core.fs\BuildOrRunWalkPerf.bat >nul 2>&1
call tests\fafafa.core.fs\bin\perf_resolve_bench.exe "%ROOT%" %ITERS%
call tests\fafafa.core.fs\tools\Compare-Resolve-Perf.bat tests\fafafa.core.fs\performance-data\perf_resolve_baseline.txt tests\fafafa.core.fs\performance-data\perf_resolve_latest.txt 25
exit /b %ERRORLEVEL%

  "%EXE%" %*
  set "RET=%ERRORLEVEL%"
  echo.
  echo Benchmark exited with code !RET!
  exit /b !RET!
) else (
  echo ERROR: Executable not found: %EXE%
  exit /b 2
)

