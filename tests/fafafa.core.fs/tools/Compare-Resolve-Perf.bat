@echo off
setlocal ENABLEDELAYEDEXPANSION

rem Compare perf_resolve CSV line without PowerShell
rem Usage: Compare-Resolve-Perf.bat [baseline] [latest] [maxRegressionPct]

set BASE=%~1
set LATEST=%~2
set MAXPCT=%~3
if "%BASE%"=="" set BASE=tests\fafafa.core.fs\performance-data\perf_resolve_baseline.txt
if "%LATEST%"=="" set LATEST=tests\fafafa.core.fs\performance-data\perf_resolve_latest.txt
if "%MAXPCT%"=="" set MAXPCT=%PERF_REG_PCT%
if "%MAXPCT%"=="" set MAXPCT=25

if not exist "%BASE%" echo [ERR] Baseline not found: %BASE% & exit /b 2
if not exist "%LATEST%" echo [ERR] Latest not found: %LATEST% & exit /b 2

for /f "tokens=1-6 delims=," %%a in ('type "%BASE%" ^| findstr /B "CSV,ResolvePathEx"') do (
  set BP=%%c
  set BI=%%d
  set BF=%%e
  set BT=%%f
)
for /f "tokens=1-6 delims=," %%a in ('type "%LATEST%" ^| findstr /B "CSV,ResolvePathEx"') do (
  set LP=%%c
  set LI=%%d
  set LF=%%e
  set LT=%%f
)

if "!BF!"=="" echo [ERR] Baseline CSV not found & exit /b 3
if "!LF!"=="" echo [ERR] Latest CSV not found & exit /b 3

rem integer math: pct = (latest - base) * 100 / base
set /a CHGF=(LF-BF)*100/BF
set /a CHGT=(LT-BT)*100/BT

set FLAG=OK
if !CHGF! GTR %MAXPCT% set FLAG=REGRESSION
if !CHGT! GTR %MAXPCT% set FLAG=REGRESSION

echo Result: %FLAG%; TouchDisk=False: latest=!LF! ms (baseline=!BF! ms, change=!CHGF!%%), TouchDisk=True: latest=!LT! ms (baseline=!BT! ms, change=!CHGT!%%)

if /I "%FLAG%"=="OK" exit /b 0
exit /b 1

