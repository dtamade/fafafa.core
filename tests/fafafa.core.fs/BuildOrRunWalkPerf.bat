@echo off
setlocal ENABLEDELAYEDEXPANSION
set SCRIPT_DIR=%~dp0
set BIN=%SCRIPT_DIR%bin

rem Optional arg: LF -> enable LargeFetch macro
if /I "%~1"=="LF" set FPCOPT=-dFS_WALK_WIN_LARGE_FETCH

rem Build perf_walk_bench (fallback to lazbuild if needed)
if exist "tools\lazbuild.bat" (
  call "tools\lazbuild.bat" "tests\fafafa.core.fs\perf_walk_bench.lpr" >nul 2>&1
) else (
  "D:\devtools\lazarus\trunk\fpc\bin\x86_64-win64\fpc.exe" -MObjFPC -Scghi -O1 -g -gl -l -vewnhibq -Fusrc -Fu..\..\src -FE"%BIN%" %FPCOPT% "%SCRIPT_DIR%perf_walk_bench.lpr" >nul 2>&1
)
if errorlevel 1 (
  echo [ERROR] Build perf_walk_bench failed
  exit /b 1
)

set ROOT=%SCRIPT_DIR%walk_bench_root
if not exist "%ROOT%" mkdir "%ROOT%" >nul 2>&1

"%BIN%\perf_walk_bench.exe" "%ROOT%" genwalk 3 4 2 >nul 2>&1
"%BIN%\perf_walk_bench.exe" "%ROOT%" walk 3 4 2 >nul 2>&1

set OUT=%SCRIPT_DIR%performance-data\perf_walk_latest.txt
if not exist "%OUT%" (
  echo [WARN] perf_walk_latest.txt not found: %OUT%
  exit /b 0
)

echo Output file: %OUT%
findstr /B "CSV,Walk" "%OUT%"
findstr /B "Walk entries:" "%OUT%"

exit /b 0
