@echo off
setlocal ENABLEDELAYEDEXPANSION

set "SCRIPT_DIR=%~dp0"
set "LAZBUILD=%SCRIPT_DIR%..\..\tools\lazbuild.bat"
set "LPI=%SCRIPT_DIR%bench_map_str_key.lpi"
set "EXEC=%SCRIPT_DIR%..\..\bin\bench_map_str_key.exe"
set "OUT=%SCRIPT_DIR%..\..\bin\bench_map_str_key.csv"

REM Build bench project (Debug)
call "%LAZBUILD%" "%LPI%" --build-mode=Debug
if %ERRORLEVEL% NEQ 0 (
  echo Build bench project failed with error code %ERRORLEVEL%.
  exit /b %ERRORLEVEL%
)

REM Prepare output CSV
if exist "%OUT%" del /f /q "%OUT%" >nul 2>nul

echo mode,nkeys,iter,capmul100,maxload1000,probe,time_ms,resize_count,last_resize_ms,total_resize_ms> "%OUT%"

set "ITER=10"
set "NKEYS_LIST=10000 50000 100000"
set "CAPMUL_LIST=80 100 120 150 200 300"

for %%N in (%NKEYS_LIST%) do (
  for %%C in (%CAPMUL_LIST%) do (
    echo Running MM nkeys=%%N capmul=%%C
    "%EXEC%" --mode=mm --nkeys=%%N --iter=%ITER% --capmul100=%%C --maxload1000=600 --probe=linear --csv --csv-no-header >> "%OUT%"
    echo Running OA nkeys=%%N capmul=%%C
    "%EXEC%" --mode=oa --nkeys=%%N --iter=%ITER% --capmul100=%%C --maxload1000=600 --probe=linear --csv --csv-no-header >> "%OUT%"
    "%EXEC%" --mode=oa --nkeys=%%N --iter=%ITER% --capmul100=%%C --maxload1000=600 --probe=quad --csv --csv-no-header >> "%OUT%"
    "%EXEC%" --mode=oa --nkeys=%%N --iter=%ITER% --capmul100=%%C --maxload1000=600 --probe=double --csv --csv-no-header >> "%OUT%"
  )
)

echo.
echo Done. CSV saved to: %OUT%
exit /b 0

