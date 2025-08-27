@echo off
setlocal
set "SCRIPT_DIR=%~dp0"
pushd "%SCRIPT_DIR%"

set "LAZBUILD=..\..\tools\lazbuild.bat"
if not exist "%LAZBUILD%" (
  echo [WARN] tools\lazbuild.bat not found, falling back to lazbuild in PATH
  set "LAZBUILD=lazbuild"
)

set "LPI=example_writer_sort_pretty.lpi"

call "%LAZBUILD%" "%LPI%"
if errorlevel 1 goto :END

set "BIN=bin\example_writer_sort_pretty.exe"
if exist "%BIN%" (
  echo Running example...
  "%BIN%"
) else (
  echo Build ok. Run the executable in examples\fafafa.core.toml\bin\
)

:END
popd
endlocal

