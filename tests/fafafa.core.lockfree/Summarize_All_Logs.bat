@echo off
setlocal enabledelayedexpansion

REM Summarize latest logs of minimal, minimal-runner, ifaces/factories, and PadOn/PadOff benchmark
REM Output: tests\fafafa.core.lockfree\logs\summary_latest.txt

set "SCRIPT_DIR=%~dp0"
set "LOG_DIR=%SCRIPT_DIR%logs"
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"
set "OUT_FILE=%LOG_DIR%\summary_latest.txt"

>"%OUT_FILE%" echo ===== Summary generated at %DATE% %TIME% =====
>>"%OUT_FILE%" echo.

REM Minimal
if exist "%SCRIPT_DIR%Summarize_Minimal.bat" (
  >>"%OUT_FILE%" echo --- Minimal (logs\latest_minimal.log) ---
  call "%SCRIPT_DIR%Summarize_Minimal.bat" >> "%OUT_FILE%" 2>&1
  >>"%OUT_FILE%" echo.
) else (
  >>"%OUT_FILE%" echo [warn] Summarize_Minimal.bat not found
)

REM Minimal Runner
if exist "%SCRIPT_DIR%Summarize_Minimal_Runner.bat" (
  >>"%OUT_FILE%" echo --- Minimal Runner (logs\latest_minimal_runner.log) ---
  call "%SCRIPT_DIR%Summarize_Minimal_Runner.bat" >> "%OUT_FILE%" 2>&1
  >>"%OUT_FILE%" echo.
) else (
  >>"%OUT_FILE%" echo [warn] Summarize_Minimal_Runner.bat not found
)

REM Queues smoke (SPSC/MPMC+RingBuffer)
if exist "%SCRIPT_DIR%Summarize_Smoke_Queues.bat" (
  >>"%OUT_FILE%" echo --- Queues Smoke (logs\latest_smoke_queues.log) ---
  call "%SCRIPT_DIR%Summarize_Smoke_Queues.bat" >> "%OUT_FILE%" 2>&1
  >>"%OUT_FILE%" echo.
) else (
  >>"%OUT_FILE%" echo [warn] Summarize_Smoke_Queues.bat not found
)

REM Ifaces/Factories
if exist "%SCRIPT_DIR%Summarize_Ifaces_Factories.bat" (
  >>"%OUT_FILE%" echo --- Ifaces/Factories (logs\latest_ifaces_factories.log) ---
  call "%SCRIPT_DIR%Summarize_Ifaces_Factories.bat" >> "%OUT_FILE%" 2>&1
  >>"%OUT_FILE%" echo.
) else (
  >>"%OUT_FILE%" echo [warn] Summarize_Ifaces_Factories.bat not found
)

REM Benchmark PadCompare
if exist "%SCRIPT_DIR%Summarize_Benchmark_PadCompare.bat" (
  >>"%OUT_FILE%" echo --- Benchmark PadOn/PadOff (logs\latest.log) ---
  call "%SCRIPT_DIR%Summarize_Benchmark_PadCompare.bat" >> "%OUT_FILE%" 2>&1
  >>"%OUT_FILE%" echo.
) else (
  >>"%OUT_FILE%" echo [warn] Summarize_Benchmark_PadCompare.bat not found
)

REM Generate RingBuffer smoke performance report (Markdown)
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%Generate_Smoke_Report.ps1" -RecentN 15 >> "%OUT_FILE%" 2>&1


REM Append brief RingBuffer report preview to summary
set "REPORT_MD=%SCRIPT_DIR%logs\report_smoke_ringbuffer.md"
if exist "%REPORT_MD%" (
  >>"%OUT_FILE%" echo --- RingBuffer Smoke Report (preview) ---
  powershell -NoProfile -Command "Get-Content -LiteralPath '%REPORT_MD%' -Head 40" >> "%OUT_FILE%" 2>&1
  >>"%OUT_FILE%" echo [report-md] %REPORT_MD%
  >>"%OUT_FILE%" echo.
)

REM Show combined summary
Type "%OUT_FILE%"

exit /b 0

