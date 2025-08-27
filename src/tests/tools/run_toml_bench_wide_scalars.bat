@echo off
setlocal
set SCRIPT_DIR=%~dp0
pushd "%SCRIPT_DIR%"
call run_toml_bench.bat 20000 0 0 ps
popd
exit /b %ERRORLEVEL%

