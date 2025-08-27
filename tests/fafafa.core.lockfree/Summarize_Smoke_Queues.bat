@echo off
setlocal enabledelayedexpansion

REM Summarize latest queues smoke log (SPSC/MPMC + RingBuffer)
REM Usage: Summarize_Smoke_Queues.bat [log_file] [tail_lines]

set "SCRIPT_DIR=%~dp0"
set "LOG_DIR=%SCRIPT_DIR%logs"
set "LOG_FILE=%~1"
set "TAIL_LINES=%~2"

if "%LOG_FILE%"=="" set "LOG_FILE=%LOG_DIR%\latest_smoke_queues.log"
if "%TAIL_LINES%"=="" set "TAIL_LINES=100"

if not exist "%LOG_FILE%" (
  echo [error] Log file not found: %LOG_FILE%
  echo        Run via: BuildOrTest.bat minimal (auto-calls Run_Smoke_Queues_With_Log)
  exit /b 1
)

echo ---------------- SUMMARY (OK/Failed) ----------------
findstr /I "smoke OK Failed" "%LOG_FILE%"

for %%K in (SPSC MPMC RingBuffer enqueue dequeue value) do (
  echo ---------------- FINDSTR: %%K ----------------
  findstr /I "%%K" "%LOG_FILE%"
)

echo ---------------- TAIL (last %TAIL_LINES% lines) ----------------
powershell -NoProfile -Command "Get-Content -LiteralPath '%LOG_FILE%' -Tail %TAIL_LINES% | ForEach-Object { $_ }" 2>nul
if errorlevel 1 type "%LOG_FILE%"

echo ---------------- CSV export (ringbuffer timer) ----------------
powershell -NoProfile -Command "$log = '%LOG_FILE%'; $csv = Join-Path (Split-Path $log) 'smoke_ringbuffer_times.csv'; $lines = Get-Content -LiteralPath $log | Select-String -Pattern 'RingBuffer smoke timer: ops=(\d+) ms=(\d+) ops_per_sec=(\d+)'; if (!(Test-Path $csv)) { 'timestamp,ops,ms,ops_per_sec' | Set-Content -LiteralPath $csv }; foreach ($m in $lines) { if ($m.Matches.Count -gt 0) { $ops=$m.Matches[0].Groups[1].Value; $ms=$m.Matches[0].Groups[2].Value; $opsps=$m.Matches[0].Groups[3].Value; $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'; Add-Content -LiteralPath $csv -Value \"$ts,$ops,$ms,$opsps\" } }; Write-Host ('[csv] ' + $csv)" 2>nul

exit /b 0

