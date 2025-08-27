@echo off
setlocal enabledelayedexpansion

REM Build toml_bench.lpr with FPC using absolute paths
set SCRIPT_DIR=%~dp0
pushd "%SCRIPT_DIR%"

REM Repo root = three levels up from tools dir (src\tests\tools)
for %%I in (.) do set TOOLS_DIR=%%~fI
set SRC_DIR=%TOOLS_DIR%\..\..\..
set SRC_DIR=%SRC_DIR%\src

if not exist "%SRC_DIR%\fafafa.core.toml.pas" (
  echo ERROR: src path not found: "%SRC_DIR%"
  popd
  exit /b 1
)

REM Compile into current folder
"D:\devtools\lazarus\trunk\fpc\bin\x86_64-win64\fpc.exe" toml_bench.lpr -Fu"%SRC_DIR%" -Fi"%SRC_DIR%" -FE"%TOOLS_DIR%"
set EC=%ERRORLEVEL%
if not %EC%==0 (
  echo Build failed with exit code %EC%
  popd
  exit /b %EC%
)

echo Build succeeded: %TOOLS_DIR%\toml_bench.exe
popd
exit /b 0

