@echo off
setlocal ENABLEDELAYEDEXPANSION

set "SCRIPT_DIR=%~dp0"
set "ROOT_DIR=%SCRIPT_DIR%..\.."
set "TOOLS_DIR=%ROOT_DIR%\tools"
set "BIN_DIR=%ROOT_DIR%\bin"
set "LAZBUILD=%TOOLS_DIR%\lazbuild.bat"
set "LPI=%SCRIPT_DIR%benchmark_micro_spsc_mpmc.lpi"

if not exist "%LAZBUILD%" (
  echo [ERROR] lazbuild helper not found: %LAZBUILD%
  exit /b 1
)
if not exist "%BIN_DIR%" mkdir "%BIN_DIR%"

rem Build all modes once (fast)
call "%LAZBUILD%" --build-mode=PadOff "%LPI%" || exit /b 1
call "%LAZBUILD%" --build-mode=PadOn "%LPI%" || exit /b 1
call "%LAZBUILD%" --build-mode=BackoffOn "%LPI%" || exit /b 1

set "EXE_OFF=%BIN_DIR%\benchmark_micro_padoff.exe"
set "EXE_ON=%BIN_DIR%\benchmark_micro_padon.exe"
set "EXE_BF=%BIN_DIR%\benchmark_micro_backoffon.exe"

for /f %%a in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss"') do set TS=%%a
set "OUT_DIR=%SCRIPT_DIR%logs"
if not exist "%OUT_DIR%" mkdir "%OUT_DIR%"
set "CSV=%OUT_DIR%\micro_matrix_quick_%TS%.csv"

for /f "usebackq delims=" %%m in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "$o='%CSV%'; $cpu=(Get-CimInstance Win32_Processor | Select-Object -First 1 -ExpandProperty Name); $os=(Get-CimInstance Win32_OperatingSystem | Select-Object -ExpandProperty Version); $hostn=$env:COMPUTERNAME; $lz=(Get-Command lazbuild -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source); $git=(git rev-parse --short HEAD 2^>^&1); '# commit='+$git+', cpu='+$cpu+', os='+$os+', host='+$hostn+ (if($lz){', lazbuild='+$lz} else {''})"`) do (
  echo %%m>>"%CSV%"
)
>>"%CSV%" echo algo,mode,capacity,producers,consumers,duration_ms,ops,ops_per_sec,run

set DURATION=1000
set REPEATS=2
set TIMEOUT_SEC=30

for %%C in (16384 65536) do (
  for %%P in (2 4) do (
    for %%S in (2 4) do (
      echo --- Running capacity=%%C P=%%P C=%%S ---
      for %%M in (OFF ON BF) do (
        if "%%M"=="OFF" set "EXE=%EXE_OFF%"
        if "%%M"=="ON" set "EXE=%EXE_ON%"
        if "%%M"=="BF" set "EXE=%EXE_BF%"
        powershell -NoProfile -ExecutionPolicy Bypass -File "%ROOT_DIR%\scripts\run_micro_once.ps1" -Exe "!EXE!" -DurationMs !DURATION! -Repeats !REPEATS! -Capacity %%C -Producers %%P -Consumers %%S -Algo both -TimeoutSec !TIMEOUT_SEC! -Csv "%CSV%"
        if !ERRORLEVEL! NEQ 0 (
          echo [ERROR] Execution failed for mode %%M capacity=%%C P=%%P C=%%S (EC=!ERRORLEVEL!)
          rem do not exit; continue to next to collect as much data as possible
        )
      )
    )
  )
)

echo Saved results to %CSV%

rem Post-process: normalize CSV and write Markdown summary (best practice)
set "ROOT_SCRIPTS=%ROOT_DIR%\scripts"
if exist "%ROOT_SCRIPTS%\normalize_micro_csv.ps1" (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%ROOT_SCRIPTS%\normalize_micro_csv.ps1" "%CSV%"
) else (
  echo [WARN] normalize_micro_csv.ps1 not found under %ROOT_SCRIPTS%, skipping normalization
)

if exist "%ROOT_SCRIPTS%\summarize_quick_matrix.ps1" (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%ROOT_SCRIPTS%\summarize_quick_matrix.ps1" "%CSV%"
) else (
  echo [WARN] summarize_quick_matrix.ps1 not found under %ROOT_SCRIPTS%, skipping summary
)

exit /b 0

