@echo off
setlocal ENABLEEXTENSIONS
set "SCRIPT_DIR=%~dp0"
set "LAZBUILD=%SCRIPT_DIR%..\..\tools\lazbuild.bat"

pushd "%SCRIPT_DIR%" >nul

REM Fast path: report-only (skip build/clean)
if /i "%1"=="report-select-only" goto REPORT_ONLY

REM Fast path: run only metrics example (build + run)
if /i "%1"=="run-metrics" (
  echo Building and running example_metrics_light...
  "D:\devtools\lazarus\trunk\fpc\bin\x86_64-win64\fpc.exe" -MObjFPC -Scghi -O2 -Xs -XX -CX -Sd -Si -Sg -vewnhibq -Fi. -Fu. -Fu..\..\src -FEbin example_metrics_light.lpr
  if %ERRORLEVEL% NEQ 0 goto :ERR
  if "%~2"=="" (
    ".\bin\example_metrics_light.exe"
  ) else (
    ".\bin\example_metrics_light.exe" "%~2"
  )
  echo Done. CSV: %~2
  exit /b 0

  goto :END
)

REM Clean artifacts before build (iron rule)
for %%E in (example_thread_channel example_thread_scheduler example_thread_best_practices example_thread_future_helpers example_thread_select_nonpolling example_thread_select_best_practices example_thread_select_bench example_thread_cancel_io_batch example_metrics_light example_thread_spawn_token example_thread_wait_or_cancel example_thread_channel_select_cancel example_thread_scheduler_cancel_timeout example_thread_channel_timeout_multi_select benchmark_taskitem_pool) do (
  if exist ".\bin\%%E.exe" del /f /q ".\bin\%%E.exe" >nul 2>&1
)
if exist ".\lib" rmdir /s /q ".\lib" >nul 2>&1


call "%LAZBUILD%" --build-mode=Release "example_thread_channel.lpr"
if %ERRORLEVEL% NEQ 0 goto :ERR
call "%LAZBUILD%" --build-mode=Release "example_thread_scheduler.lpr"
if %ERRORLEVEL% NEQ 0 goto :ERR
call "%LAZBUILD%" --build-mode=Release "example_thread_best_practices.lpr"
if %ERRORLEVEL% NEQ 0 goto :ERR
call "%LAZBUILD%" --build-mode=Release "example_thread_future_helpers.lpr"
if %ERRORLEVEL% NEQ 0 goto :ERR
REM NOTE: lazbuild here does not accept --compiler-options; for nonpolling demo, the sample uses runtime path
if exist "example_thread_select_nonpolling.lpi" (
  call "%LAZBUILD%" --build-mode=Release "example_thread_select_nonpolling.lpr"
  if %ERRORLEVEL% NEQ 0 goto :ERR
  if exist "example_thread_select_best_practices.lpr" (
    call "%LAZBUILD%" --build-mode=Release "example_thread_select_best_practices.lpr"
    if %ERRORLEVEL% NEQ 0 goto :ERR
  )
  ) else (
  echo Skipping example_thread_select_nonpolling (no .lpi)
)
REM Skip select_bench if project file missing

REM Build extra cancellation demos (FPC direct compile)
"D:\devtools\lazarus\trunk\fpc\bin\x86_64-win64\fpc.exe" -MObjFPC -Scghi -O2 -Xs -XX -CX -Sd -Si -Sg -vewnhibq -Fi. -Fu. -Fu..\..\src -FEbin example_thread_channel_select_cancel.lpr
if %ERRORLEVEL% NEQ 0 goto :ERR
"D:\devtools\lazarus\trunk\fpc\bin\x86_64-win64\fpc.exe" -MObjFPC -Scghi -O2 -Xs -XX -CX -Sd -Si -Sg -vewnhibq -Fi. -Fu. -Fu..\..\src -FEbin example_thread_scheduler_cancel_timeout.lpr
if %ERRORLEVEL% NEQ 0 goto :ERR
"D:\devtools\lazarus\trunk\fpc\bin\x86_64-win64\fpc.exe" -MObjFPC -Scghi -O2 -Xs -XX -CX -Sd -Si -Sg -vewnhibq -Fi. -Fu. -Fu..\..\src -FEbin example_thread_channel_timeout_multi_select.lpr
if %ERRORLEVEL% NEQ 0 goto :ERR
if exist "example_thread_select_bench.lpi" (
  call "%LAZBUILD%" --build-mode=Release "example_thread_select_bench.lpr"
  if %ERRORLEVEL% NEQ 0 goto :ERR
) else (
  echo Skipping example_thread_select_bench no-lpi
)
if exist "example_thread_cancel_io_batch.lpi" (
  call "%LAZBUILD%" --build-mode=Release "example_thread_cancel_io_batch.lpr"
  if %ERRORLEVEL% NEQ 0 goto :ERR
) else (
  echo Building example_thread_cancel_io_batch via FPC no-lpi
  "D:\devtools\lazarus\trunk\fpc\bin\x86_64-win64\fpc.exe" -MObjFPC -Scghi -O2 -Xs -XX -CX -Sd -Si -Sg -vewnhibq -Fi. -Fu. -Fu..\..\src -FEbin example_thread_cancel_io_batch.lpr
  if %ERRORLEVEL% NEQ 0 goto :ERR
)
REM Build example_metrics_light (FPC direct compile for speed)
"D:\devtools\lazarus\trunk\fpc\bin\x86_64-win64\fpc.exe" -MObjFPC -Scghi -O2 -Xs -XX -CX -Sd -Si -Sg -vewnhibq -Fi. -Fu. -Fu..\..\src -FEbin example_metrics_light.lpr
if %ERRORLEVEL% NEQ 0 goto :ERR


REM Build new spawn-token example (FPC direct compile)
"D:\devtools\lazarus\trunk\fpc\bin\x86_64-win64\fpc.exe" -MObjFPC -Scghi -O2 -Xs -XX -CX -Sd -Si -Sg -vewnhibq -Fi. -Fu. -Fu..\..\src -FEbin example_thread_spawn_token.lpr
if %ERRORLEVEL% NEQ 0 goto :ERR

REM Build wait-or-cancel example (FPC direct compile)
"D:\devtools\lazarus\trunk\fpc\bin\x86_64-win64\fpc.exe" -MObjFPC -Scghi -O2 -Xs -XX -CX -Sd -Si -Sg -vewnhibq -Fi. -Fu. -Fu..\..\src -FEbin example_thread_wait_or_cancel.lpr
if %ERRORLEVEL% NEQ 0 goto :ERR

REM Build benchmark (FPC direct compile for speed)
"D:\devtools\lazarus\trunk\fpc\bin\x86_64-win64\fpc.exe" -MObjFPC -Scghi -O2 -Xs -XX -CX -Sd -Si -Sg -vewnhibq -Fi. -Fu. -Fu..\..\src -Fu..\..\tests\fafafa.core.thread -FEbin ..\..\play\fafafa.core.thread\benchmark_taskitem_pool.lpr
if %ERRORLEVEL% NEQ 0 goto :ERR

if /i "%1"=="run" (
  if not "%~2"=="" (
    set "_ONE=%~2"
    if exist ".\bin\%_ONE%.exe" (
      echo Running single example: %_ONE%
      ".\bin\%_ONE%.exe"
      goto :END
    ) else (
      echo Example not found: %_ONE% ^(expected .\bin\%_ONE%.exe^) & goto :ERR
    )
  )
  echo Running examples...
  ".\bin\example_thread_channel.exe"
  ".\bin\example_thread_scheduler.exe"
  ".\bin\example_thread_best_practices.exe"
  ".\bin\example_thread_future_helpers.exe"
  ".\bin\example_thread_cancel_io_batch.exe"
  ".\bin\example_metrics_light.exe"
  ".\bin\example_thread_spawn_token.exe"
  ".\bin\example_thread_wait_or_cancel.exe"
  ".\bin\example_thread_channel_select_cancel.exe"
  ".\bin\example_thread_scheduler_cancel_timeout.exe"
  ".\bin\example_thread_select_best_practices.exe"
  ".\bin\example_thread_channel_timeout_multi_select.exe"
) else if /i "%1"=="bench" (
  echo Running benchmark...
  ".\bin\benchmark_taskitem_pool.exe"
) else if /i "%1"=="run-bench" (
  echo Running benchmark with args ^(default: 1 1 -1 5000^)...
  if "%2"=="" (
    ".\bin\benchmark_taskitem_pool.exe"
  ) else (
    ".\bin\benchmark_taskitem_pool.exe" %2 %3 %4 %5
  )
) else if /i "%1"=="compare-select" (
  rem Args: ITER [REPEATS] [CSV_PATH] [STEP] [SPAN] [BASE]
  set "PSARGS="
  if not "%2"=="" set "PSARGS=!PSARGS! -Iter %2"
  if not "%3"=="" set "PSARGS=!PSARGS! -Repeats %3"
  if not "%4"=="" set "PSARGS=!PSARGS! -CsvPath %4"
  if not "%5"=="" set "PSARGS=!PSARGS! -Step %5"
  if not "%6"=="" set "PSARGS=!PSARGS! -Span %6"
  if not "%7"=="" set "PSARGS=!PSARGS! -Base %7"
  powershell -NoProfile -ExecutionPolicy Bypass -File ".\select_bench_compare.ps1" !PSARGS!
) else if /i "%1"=="compare-select-matrix" (
  rem Args: [ITERSComma] [REPEATS] [CSV_PATH] [STEPSComma] [SPANSComma] [BASESComma]
  setlocal ENABLEDELAYEDEXPANSION
  set "PSARGS="
  if not "%~2"=="" set "PSARGS=!PSARGS! -Iters \"%~2\""
  if not "%~3"=="" set "PSARGS=!PSARGS! -Repeats %~3"
  if not "%~4"=="" set "PSARGS=!PSARGS! -CsvPath %~4"
  if not "%~5"=="" set "PSARGS=!PSARGS! -Steps \"%~5\""
  if not "%~6"=="" set "PSARGS=!PSARGS! -Spans \"%~6\""
  if not "%~7"=="" set "PSARGS=!PSARGS! -Bases \"%~7\""
  powershell -NoProfile -ExecutionPolicy Bypass -File ".\select_bench_compare_matrix.ps1" !PSARGS!
  endlocal
) else if /i "%1"=="report-select" (
  rem Args: CSV_PATHS_COMMA [OUT_PATH]
  setlocal ENABLEDELAYEDEXPANSION
  set "PSARGS="
  if not "%~2"=="" set "PSARGS=!PSARGS! -CsvPaths \"%~2\""
  if not "%~3"=="" set "PSARGS=!PSARGS! -OutPath %~3"
  powershell -NoProfile -ExecutionPolicy Bypass -File ".\select_bench_report.ps1" !PSARGS!
  endlocal
) else (
:REPORT_ONLY
setlocal ENABLEDELAYEDEXPANSION
set "PSARGS="
if not "%~2"=="" set "PSARGS=!PSARGS! -CsvPaths \"%~2\""
if not "%~3"=="" set "PSARGS=!PSARGS! -OutPath %~3"
if not "%~4"=="" set "PSARGS=!PSARGS! -HtmlOutPath %~4"
if /i "%~5"=="bg" (
  set "PSARGS=!PSARGS! -BgHighlight:$true"
)
powershell -NoProfile -ExecutionPolicy Bypass -File ".\select_bench_report.ps1" !PSARGS!
endlocal
goto :END

  echo To run examples, call this script with 'run'.
  echo To run benchmark, call this script with 'bench' or 'run-bench ^<core^> ^<max^> ^<queue^> ^<total^>'.
  echo To compare Select modes, call this script with 'compare-select [ITER] [REPEATS] [CSV_PATH] [STEP] [SPAN] [BASE]'.
  echo To compare matrix, call this script with 'compare-select-matrix [ITERS list] [REPEATS] [CSV_PATH] [STEPS list] [SPANS list] [BASES list]'.
  echo To generate markdown/HTML report, call this script with "report-select-only \"<csv1,csv2,...>\" [OutPath] [HtmlOutPath]".
  echo Or use: report-select [CSV_PATHS...] (slower; may trigger builds).
)

goto :END
:ERR
echo Build failed %ERRORLEVEL%.
:END
popd >nul
endlocal

