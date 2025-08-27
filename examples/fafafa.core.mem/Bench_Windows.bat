@echo off
setlocal ENABLEDELAYEDEXPANSION

set "SCRIPT_DIR=%~dp0"
set "LAZBUILD=%SCRIPT_DIR%..\..\tools\lazbuild.bat"
set "LPI=%SCRIPT_DIR%example_mem_baseline_win.lpi"
set "OUTDIR=%SCRIPT_DIR%bench_out"
set "EXE=%SCRIPT_DIR%bin\example_mem_baseline_win_debug.exe"

if not exist "%OUTDIR%" mkdir "%OUTDIR%"

rem Build debug (contains baseline runner)
call "%LAZBUILD%" --build-mode=Debug "%LPI%"
if ERRORLEVEL 1 goto :BUILD_FAIL

rem Run baseline and capture CSV
"%EXE%" > "%OUTDIR%\results_windows.csv"
if ERRORLEVEL 1 goto :RUN_FAIL

rem Also run our aligned example (optional smoke)
if exist "%SCRIPT_DIR%bin\example_mem_debug.exe" (
  echo.>> "%OUTDIR%\results_windows.csv"
  echo # Smoke: example_stack_aligned >> "%OUTDIR%\results_windows.csv"
  "%SCRIPT_DIR%bin\example_mem_debug.exe" >nul 2>&1
)

echo done. Output: %OUTDIR%\results_windows.csv
exit /b 0

:BUILD_FAIL
echo Build failed: %ERRORLEVEL%
exit /b %ERRORLEVEL%

:RUN_FAIL
echo Run failed: %ERRORLEVEL%
exit /b %ERRORLEVEL%

