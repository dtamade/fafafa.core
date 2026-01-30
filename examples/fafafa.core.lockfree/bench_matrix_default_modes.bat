@echo off
setlocal ENABLEDELAYEDEXPANSION

set "SCRIPT_DIR=%~dp0"
set "LAZBUILD=%SCRIPT_DIR%..\..\tools\lazbuild.bat"
set "LPI=%SCRIPT_DIR%bench_map_str_key.lpi"
set "EXEC=%SCRIPT_DIR%..\..\bin\bench_map_str_key.exe"
set "OUT1=%SCRIPT_DIR%..\..\bin\bench_default_linear.csv"
set "OUT2=%SCRIPT_DIR%..\..\bin\bench_default_double.csv"

REM Build default linear (Debug)
call "%LAZBUILD%" "%LPI%" --build-mode=Debug
if %ERRORLEVEL% NEQ 0 exit /b %ERRORLEVEL%

echo mode,nkeys,iter,capmul100,maxload1000,probe,dist,seed,unique,time_ms,resize_count,last_resize_ms,total_resize_ms> "%OUT1%"
set "ITER=10"
set "NKEYS_LIST=10000 50000 100000"
set "CAPMUL_LIST=80 100 120 150 200 300"
set "SEEDS=42 123 2025"
for %%N in (%NKEYS_LIST%) do (
  for %%C in (%CAPMUL_LIST%) do (
    echo [linear-default] nkeys=%%N capmul=%%C
    for /f "usebackq skip=1 tokens=1-4 delims=," %%I in (`"%EXEC%" --mode=oa --nkeys=%%N --iter=%ITER% --capmul100=%%C --maxload1000=600 --probe=default --dist=seq --seed=123 --csv`) do (
      echo oa,%%J,%%K,%%C,600,default,seq,123,0,%%L,0,0,0 >> "%OUT1%"
    )
    for %%S in (%SEEDS%) do (
      for /f "usebackq skip=1 tokens=1-4 delims=," %%I in (`"%EXEC%" --mode=oa --nkeys=%%N --iter=%ITER% --capmul100=%%C --maxload1000=600 --probe=default --dist=rand --seed=%%S --csv`) do (
        echo oa,%%J,%%K,%%C,600,default,rand,%%S,0,%%L,0,0,0 >> "%OUT1%"
      )
    )
    set /a U=%%N/10
    for /f "usebackq skip=1 tokens=1-4 delims=," %%I in (`"%EXEC%" --mode=oa --nkeys=%%N --iter=%ITER% --capmul100=%%C --maxload1000=600 --probe=default --dist=repeat --unique=!U! --csv`) do (
      echo oa,%%J,%%K,%%C,600,default,repeat,0,!U!,%%L,0,0,0 >> "%OUT1%"
    )
  )
)

REM Build default double (new build mode); fallback to Debug if mode missing
call "%LAZBUILD%" "%LPI%" --build-mode=DefaultDoubleHash
if %ERRORLEVEL% NEQ 0 (
  echo [bench_matrix] WARN: DefaultDoubleHash build mode not found, fallback to Debug
  call "%LAZBUILD%" "%LPI%" --build-mode=Debug
  if %ERRORLEVEL% NEQ 0 exit /b %ERRORLEVEL%
)

echo mode,nkeys,iter,capmul100,maxload1000,probe,dist,seed,unique,time_ms,resize_count,last_resize_ms,total_resize_ms> "%OUT2%"
for %%N in (%NKEYS_LIST%) do (
  for %%C in (%CAPMUL_LIST%) do (
    echo [double-default] nkeys=%%N capmul=%%C
    for /f "usebackq skip=1 tokens=1-4 delims=," %%I in (`"%EXEC%" --mode=oa --nkeys=%%N --iter=%ITER% --capmul100=%%C --maxload1000=600 --probe=default --dist=seq --seed=123 --csv`) do (
      echo oa,%%J,%%K,%%C,600,default,seq,123,0,%%L,0,0,0 >> "%OUT2%"
    )
    for %%S in (%SEEDS%) do (
      for /f "usebackq skip=1 tokens=1-4 delims=," %%I in (`"%EXEC%" --mode=oa --nkeys=%%N --iter=%ITER% --capmul100=%%C --maxload1000=600 --probe=default --dist=rand --seed=%%S --csv`) do (
        echo oa,%%J,%%K,%%C,600,default,rand,%%S,0,%%L,0,0,0 >> "%OUT2%"
      )
    )
    set /a U=%%N/10
    for /f "usebackq skip=1 tokens=1-4 delims=," %%I in (`"%EXEC%" --mode=oa --nkeys=%%N --iter=%ITER% --capmul100=%%C --maxload1000=600 --probe=default --dist=repeat --unique=!U! --csv`) do (
      echo oa,%%J,%%K,%%C,600,default,repeat,0,!U!,%%L,0,0,0 >> "%OUT2%"
    )
  )
)

echo.
echo Done. CSVs:
echo   %OUT1%
echo   %OUT2%
exit /b 0

