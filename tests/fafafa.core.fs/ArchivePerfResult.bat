@echo off
setlocal ENABLEDELAYEDEXPANSION

set "SCRIPT_DIR=%~dp0"
set "PERF_DIR=%SCRIPT_DIR%performance-data"
set "RUN_BAT=%SCRIPT_DIR%BuildOrRunPerf.bat"
set "LOG_FILE=%PERF_DIR%\latest.txt"

if not exist "%PERF_DIR%" mkdir "%PERF_DIR%"

:: timestamp: YYYY-MM-DD_HH-MM-SS
for /f "tokens=1-6 delims=/:. " %%a in ("%date% %time%") do set TS=%%a-%%b-%%c_%%d-%%e-%%f
set "TS_FILE=%PERF_DIR%\perf_%TS%.txt"

echo [1/2] Running perf ...
call "%RUN_BAT%" %*
set "RET=%ERRORLEVEL%"

if not "%RET%"=="0" (
  echo Perf run failed with code %RET% > "%TS_FILE%"
  echo Perf run failed with code %RET%
  exit /b %RET%
)

:: Capture last console lines from previous run is not trivial; re-run perf to a log
(
  echo Timestamp: %TS%
  echo Command: BuildOrRunPerf.bat %*
  echo --- Output ---
  call "%RUN_BAT%" %*
) > "%TS_FILE%"

copy /Y "%TS_FILE%" "%LOG_FILE%" >nul

:: Optional baseline diff
if exist "%PERF_DIR%\baseline.txt" (
  echo.
  echo [Diff] latest vs baseline:
  fc "%PERF_DIR%\baseline.txt" "%LOG_FILE%" | more
) else (
  echo.
  echo [Tip] You can set "%PERF_DIR%\baseline.txt" to enable baseline diff.
)

echo.
echo Saved: %TS_FILE%
echo Latest: %LOG_FILE%
exit /b 0

