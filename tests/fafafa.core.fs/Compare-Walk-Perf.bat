@echo off
setlocal ENABLEDELAYEDEXPANSION

rem Compare perf_walk CSV line without PowerShell
rem Usage: Compare-Walk-Perf.bat [baseline] [latest] [maxRegressionPct]

set BASE=%~1
set LATEST=%~2
set MAXPCT=%~3
if "%BASE%"=="" set BASE=tests\fafafa.core.fs\performance-data\perf_walk_baseline.txt
if "%LATEST%"=="" set LATEST=tests\fafafa.core.fs\performance-data\perf_walk_latest.txt
if "%MAXPCT%"=="" set MAXPCT=25

if not exist "%BASE%" echo [ERR] Baseline not found: %BASE% & exit /b 2
if not exist "%LATEST%" echo [ERR] Latest not found: %LATEST% & exit /b 2

for /f "tokens=1-8 delims=, " %%a in ('type "%BASE%" ^| findstr /B "CSV,Walk"') do (
  set _tag=%%a
  set _walk=%%b
  set BR=%%c
  set BD=%%d
  set BF=%%e
  set BP=%%f
  set BT=%%g
  set BC=%%h
)
for /f "tokens=1-8 delims=, " %%a in ('type "%LATEST%" ^| findstr /B "CSV,Walk"') do (
  set _tag2=%%a
  set _walk2=%%b
  set LR=%%c
  set LD=%%d
  set LF=%%e
  set LP=%%f
  set LT=%%g
  set LC=%%h
)

if "!BT!"=="" echo [ERR] Baseline CSV not found & exit /b 3
if "!LT!"=="" echo [ERR] Latest CSV not found & exit /b 3

rem Compare by time: regression if time increases by more than MAXPCT
set /a CHGT=(LT-BT)*100/BT

set FLAG=OK
if !CHGT! GTR %MAXPCT% set FLAG=REGRESSION

echo Result(Walk): %FLAG%; time latest=!LT! ms (baseline=!BT! ms, change=!CHGT!%%), entries latest=!LC!, baseline=!BC!

if /I "%FLAG%"=="OK" exit /b 0
exit /b 1

