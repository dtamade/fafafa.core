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

rem Build all modes once
call "%LAZBUILD%" --build-mode=PadOff "%LPI%" || exit /b 1
call "%LAZBUILD%" --build-mode=PadOn "%LPI%" || exit /b 1
call "%LAZBUILD%" --build-mode=BackoffOn "%LPI%" || exit /b 1

set "EXE_OFF=%BIN_DIR%\benchmark_micro_padoff.exe"
set "EXE_ON=%BIN_DIR%\benchmark_micro_padon.exe"
set "EXE_BF=%BIN_DIR%\benchmark_micro_backoffon.exe"

for /f %%a in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss"') do set TS=%%a

rem Prepare output directory and CSV path (robust to relative/dir override)
set "OUT_DIR=%SCRIPT_DIR%logs"
if not exist "%OUT_DIR%" mkdir "%OUT_DIR%"

set "CSV="
if defined FAFAFA_LOCKFREE_BENCH_OUT set "CSV=%FAFAFA_LOCKFREE_BENCH_OUT%"

for /f "usebackq delims=" %%p in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "$csv='%CSV%'; $csv=$csv -replace '/', '\\'; if ([string]::IsNullOrWhiteSpace($csv)) { $csv='%OUT_DIR%\micro_matrix_%TS%.csv' } elseif ($csv.TrimEnd() -match '\\$') { $csv = Join-Path $csv 'micro_matrix_%TS%.csv' } elseif (-not [System.IO.Path]::HasExtension($csv)) { $csv = Join-Path $csv 'micro_matrix_%TS%.csv' } $d=[System.IO.Path]::GetDirectoryName($csv); if ($d -and -not (Test-Path -LiteralPath $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }; $csv"`) do set "CSV=%%p"

rem Write header + environment metadata (robust via PowerShell Add-Content)
powershell -NoProfile -ExecutionPolicy Bypass -Command "$cpu=(Get-CimInstance Win32_Processor | Select-Object -First 1 -ExpandProperty Name); $os=(Get-CimInstance Win32_OperatingSystem | Select-Object -ExpandProperty Version); $hostn=$env:COMPUTERNAME; $lz=(Get-Command lazbuild -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source); $git=(git rev-parse --short HEAD) 2>$null; $meta='# commit='+$git+', cpu='+$cpu+', os='+$os+', host='+$hostn+($(if($lz){', lazbuild='+$lz}else{''})); Add-Content -LiteralPath '%CSV%' -Value $meta -Encoding ASCII; Add-Content -LiteralPath '%CSV%' -Value 'algo,mode,capacity,producers,consumers,duration_ms,ops,ops_per_sec,run' -Encoding ASCII"

set DURATION=3000
set REPEATS=5
rem 0 => auto-timeout based on repeats*duration
set TIMEOUT_SEC=0

rem Iterate modes outermost to ensure each mode is executed and recorded
for %%M in (OFF ON BF) do (
  if "%%M"=="OFF" set "EXE=%EXE_OFF%"
  if "%%M"=="ON" set "EXE=%EXE_ON%"
  if "%%M"=="BF" set "EXE=%EXE_BF%"
  echo === MODE %%M ===
  for %%C in (16384 65536 262144) do (
    set "CUR_CAP=%%C"
    rem SPSC: 1P/1C
    echo --- Running SPSC capacity=!CUR_CAP! P=1 C=1 ^(MODE=%%M^) ---
    powershell -NoProfile -ExecutionPolicy Bypass -File "%ROOT_DIR%\scripts\run_micro_once.ps1" -Exe "!EXE!" -DurationMs !DURATION! -Repeats !REPEATS! -Capacity !CUR_CAP! -Producers 1 -Consumers 1 -Algo spsc -TimeoutSec !TIMEOUT_SEC! -Csv "%CSV%"
    if !ERRORLEVEL! GEQ 1 (
      echo [ERROR] Execution failed or timed out for SPSC MODE=%%M capacity=!CUR_CAP! (EC=!ERRORLEVEL!)
      rem continue to collect other data
    )

    rem MPMC: P=C in (2 4 8)
    for %%X in (2 4 8) do (
      echo --- Running MPMC capacity=!CUR_CAP! P=%%X C=%%X ^(MODE=%%M^) ---
      powershell -NoProfile -ExecutionPolicy Bypass -File "%ROOT_DIR%\scripts\run_micro_once.ps1" -Exe "!EXE!" -DurationMs !DURATION! -Repeats !REPEATS! -Capacity !CUR_CAP! -Producers %%X -Consumers %%X -Algo mpmc -TimeoutSec !TIMEOUT_SEC! -Csv "%CSV%"
      if !ERRORLEVEL! GEQ 1 (
        echo [ERROR] Execution failed or timed out for MPMC MODE=%%M capacity=!CUR_CAP! P=%%X C=%%X (EC=!ERRORLEVEL!)
        rem continue to collect other data
      )
    )

    rem MPMC: P!=C asymmetric pairs
    for %%P in (2 3 4) do (
      for %%S in (1 2 3 4) do (
        if not %%P==%%S (
          echo --- Running MPMC capacity=!CUR_CAP! P=%%P C=%%S ^(MODE=%%M^) ---
          powershell -NoProfile -ExecutionPolicy Bypass -File "%ROOT_DIR%\scripts\run_micro_once.ps1" -Exe "!EXE!" -DurationMs !DURATION! -Repeats !REPEATS! -Capacity !CUR_CAP! -Producers %%P -Consumers %%S -Algo mpmc -TimeoutSec !TIMEOUT_SEC! -Csv "%CSV%"
          if !ERRORLEVEL! GEQ 1 (
            echo [ERROR] Execution failed or timed out for MPMC MODE=%%M capacity=!CUR_CAP! P=%%P C=%%S (EC=!ERRORLEVEL!)
          )
        )
      )
    )
  )
)

echo Saved results to %CSV%

rem Post-process: normalize and summarize results
set "ROOT_SCRIPTS=%ROOT_DIR%\scripts"
powershell -NoProfile -ExecutionPolicy Bypass -File "%ROOT_SCRIPTS%\normalize_micro_csv.ps1" "%CSV%"
powershell -NoProfile -ExecutionPolicy Bypass -File "%ROOT_SCRIPTS%\summarize_quick_matrix.ps1" "%CSV%"

exit /b 0

