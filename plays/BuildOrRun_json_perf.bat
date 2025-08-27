@echo off
setlocal ENABLEEXTENSIONS
cd /d "%~dp0"

if not exist bin mkdir bin

rem Compile with FPC in PATH
fpc.exe perf_json_read_write.lpr -Fu..\src -Fu. -FEbin -operf_json_read_write.exe -O1 -gl -B
if errorlevel 1 (
  echo.
  echo Build failed. Ensure FPC is installed and in PATH, or build via Lazarus IDE.
  exit /b 1
)

echo.
echo Build OK. Running...
bin\perf_json_read_write.exe %*
endlocal
