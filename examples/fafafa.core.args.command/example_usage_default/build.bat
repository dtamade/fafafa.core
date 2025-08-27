@echo off
setlocal
set PROJ_DIR=%~dp0
pushd "%PROJ_DIR%"

rem Build the example using lazbuild
call "..\..\..\tools\lazbuild.bat" example_usage_default.lpi
if errorlevel 1 (
  echo Build failed
  exit /b 1
)

echo Build OK. Run examples\fafafa.core.args.command\example_usage_default\bin\example_usage_default.exe --help
popd
endlocal

