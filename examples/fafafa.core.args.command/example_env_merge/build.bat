@echo off
setlocal
set PROJ_DIR=%~dp0
pushd "%PROJ_DIR%"

rem Build the example using lazbuild
call "..\..\..\tools\lazbuild.bat" example_env_merge.lpi
if errorlevel 1 (
  echo Build failed
  exit /b 1
)

echo Build OK. Try:
set APP_COUNT=3 & set APP_DEBUG= & bin\example_env_merge.exe run
popd
endlocal

