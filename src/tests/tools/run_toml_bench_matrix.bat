@echo off
setlocal enabledelayedexpansion

set SCRIPT_DIR=%~dp0
pushd "%SCRIPT_DIR%"

for /f %%t in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd"') do set DATE_DIR=%%t

rem args: [csvDir] [keysList] [depthList] [aotList]
set CSV_DIR=%~1
if "%CSV_DIR%"=="" set CSV_DIR=%SCRIPT_DIR%bench_results\%DATE_DIR%\
set KEYS_LIST=%~2
if "%KEYS_LIST%"=="" set KEYS_LIST=5000
set DEPTH_LIST=%~3
if "%DEPTH_LIST%"=="" set DEPTH_LIST=2 4
set AOT_LIST=%~4
if "%AOT_LIST%"=="" set AOT_LIST=0 200

for %%K in (%KEYS_LIST%) do (
  for %%D in (%DEPTH_LIST%) do (
    for %%A in (%AOT_LIST%) do (
      set CSV=%CSV_DIR%bench_%%K_%%D_%%A.csv
      if not exist "%CSV_DIR%" mkdir "%CSV_DIR%"
      if exist "%CSV%" del /f /q "%CSV%"
      echo Running matrix to CSV: %CSV%
      set FLAGS_LIST=ps p s e pe se pse
      for %%F in (!FLAGS_LIST!) do (
        call run_toml_bench.bat %%K %%D %%A %%F --csv=!CSV! --bigreader=false
      )
      call run_toml_bench.bat %%K %%D %%A ps --csv=!CSV! --bigreader=true
    )
  )
)

echo Matrix completed. Results -> %CSV_DIR%
popd
exit /b 0

