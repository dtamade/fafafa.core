@echo off
setlocal
set SCRIPT_DIR=%~dp0
pushd "%SCRIPT_DIR%"
call run_toml_bench.bat 5000 8 1000 pse
popd
exit /b %ERRORLEVEL%

