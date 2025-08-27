@echo off
setlocal
set PROJ_DIR=%~dp0
pushd "%PROJ_DIR%"

rem Build the example using lazbuild
call "..\..\..\tools\lazbuild.bat" example_help_schema.lpi
if errorlevel 1 (
  echo Build failed
  exit /b 1
)

echo Build OK. Run examples\fafafa.core.args.command\example_help_schema\bin\example_help_schema.exe
popd
endlocal

