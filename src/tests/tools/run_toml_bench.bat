@echo off
setlocal

set SCRIPT_DIR=%~dp0
pushd "%SCRIPT_DIR%"
call build_toml_bench.bat
if not %ERRORLEVEL%==0 (
  echo Build failed
  popd
  exit /b 1
)

echo Running toml_bench with args: %*
"%SCRIPT_DIR%\toml_bench.exe" %*
echo Done.
popd
exit /b 0

