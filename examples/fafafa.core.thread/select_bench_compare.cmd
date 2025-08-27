@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION
set "SCRIPT_DIR=%~dp0"
pushd "%SCRIPT_DIR%" >nul

:: Args: %1 = ITER (default 200); %2 = REPEATS (default 3); %3 = CSV path (optional, default timestamped); %4..%6 = STEP,SPAN,BASE
set "ITER=%~1"
if "%ITER%"=="" set "ITER=200"
set "REPEATS=%~2"
if "%REPEATS%"=="" set "REPEATS=3"
set "CSV=%~3"
set "STEP=%~4"
if "%STEP%"=="" set "STEP=7"
set "SPAN=%~5"
if "%SPAN%"=="" set "SPAN=60"
set "BASE=%~6"
if "%BASE%"=="" set "BASE=20"

if "%CSV%"=="" (
  for /f %%T in ('powershell -NoProfile -Command "(Get-Date).ToString('yyyyMMdd_HHmmss')"') do set "TS=%%T"
  set "CSV=%SCRIPT_DIR%bin\select_bench_compare_!TS!.csv"
)

set "LAZBUILD=%SCRIPT_DIR%..\..\tools\lazbuild.bat"
set "BENCH_PROJ=example_thread_select_bench.lpr"
set "BENCH_EXE=%SCRIPT_DIR%bin\example_thread_select_bench.exe"

echo mode,N,avg_ms,iter,step,span,base>"%CSV%"

echo [1/4] Build bench (polling)...
call "%LAZBUILD%" --build-mode=Release "%BENCH_PROJ%" >nul
if %ERRORLEVEL% NEQ 0 (
  echo Build polling failed
  goto :END
)

echo [2/4] Run bench (polling)...
for /l %%I in (1,1,%REPEATS%) do (
  for /f "usebackq delims=" %%L in (`"%BENCH_EXE%" %ITER% %STEP% %SPAN% %BASE%`) do (
    echo %%L | findstr /i /c:"N=" >nul
    if not errorlevel 1 (
      for /f "tokens=2,6 delims== " %%N %%A in ("%%L") do (
        echo polling,N=%%N,avg_ms=%%A iter=%ITER% step=%STEP% span=%SPAN% base=%BASE%
        echo polling,%%N,%%A,%ITER%,%STEP%,%SPAN%,%BASE%>>"%CSV%"
      )
    )
  )
)

echo [3/4] Build bench (non-polling)...
rem lazbuild 不支持直接传 --compiler-options，这里使用 fpc 直编译添加宏
set "FPCEXE=D:\devtools\lazarus\trunk\fpc\bin\x86_64-win64\fpc.exe"
"%FPCEXE%" -MObjFPC -Scghi -O2 -Xs -XX -CX -Sd -Si -Sg -vewnhibq -dFAFAFA_THREAD_SELECT_NONPOLLING -Fi. -Fu. -Fu..\..\src -FEbin "%BENCH_PROJ%" >nul
if %ERRORLEVEL% NEQ 0 (
  echo Build non-polling failed
  goto :END
)

echo [4/4] Run bench (non-polling)...
for /l %%I in (1,1,%REPEATS%) do (
  for /f "usebackq delims=" %%L in (`"%BENCH_EXE%" %ITER% %STEP% %SPAN% %BASE%`) do (
    echo %%L | findstr /i /c:"N=" >nul
    if not errorlevel 1 (
      for /f "tokens=2,6 delims== " %%N %%A in ("%%L") do (
        echo nonpolling,N=%%N,avg_ms=%%A iter=%ITER% step=%STEP% span=%SPAN% base=%BASE%
        echo nonpolling,%%N,%%A,%ITER%,%STEP%,%SPAN%,%BASE%>>"%CSV%"
      )
    )
  )
)

echo CSV saved to: %CSV%

:END
popd >nul
endlocal
