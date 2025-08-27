@echo off
setlocal enableextensions enabledelayedexpansion

set BASELINE=%~1
set LATEST=%~2
if "%BASELINE%"=="" set BASELINE=tests\fafafa.core.fs\performance-data\baseline.txt
if "%LATEST%"==""   set LATEST=tests\fafafa.core.fs\performance-data\latest.txt

powershell -NoProfile -ExecutionPolicy Bypass -File "tests/fafafa.core.fs/Compare-Perf.ps1" -BaselinePath "%BASELINE%" -LatestPath "%LATEST%"
set EC=%ERRORLEVEL%
exit /b %EC%

