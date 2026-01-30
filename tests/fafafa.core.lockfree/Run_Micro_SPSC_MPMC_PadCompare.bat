@echo off
setlocal ENABLEDELAYEDEXPANSION

set "SCRIPT_DIR=%~dp0"
set "ROOT_DIR=%SCRIPT_DIR%..\.."
set "TOOLS_DIR=%ROOT_DIR%\tools"
set "BIN_DIR=%ROOT_DIR%\bin"
set "LAZBUILD=%TOOLS_DIR%\lazbuild.bat"
set "LPI=%SCRIPT_DIR%benchmark_micro_spsc_mpmc.lpi"

if not exist "%LAZBUILD%" (
  echo [ERROR] lazbuild helper not found: %LAZBUILD%
  exit /b 1
)

if not exist "%BIN_DIR%" mkdir "%BIN_DIR%"

echo === Build microbench (PadOff) ===
call "%LAZBUILD%" --build-mode=PadOff "%LPI%"
if %ERRORLEVEL% NEQ 0 exit /b %ERRORLEVEL%

echo === Build microbench (PadOn) ===
call "%LAZBUILD%" --build-mode=PadOn "%LPI%"
if %ERRORLEVEL% NEQ 0 exit /b %ERRORLEVEL%

echo === Build microbench (BackoffOn) ===
call "%LAZBUILD%" --build-mode=BackoffOn "%LPI%"
if %ERRORLEVEL% NEQ 0 exit /b %ERRORLEVEL%

set "EXE_OFF=%BIN_DIR%\benchmark_micro_padoff.exe"
set "EXE_ON=%BIN_DIR%\benchmark_micro_padon.exe"
set "EXE_BF=%BIN_DIR%\benchmark_micro_backoffon.exe"

set "ARGS=duration_ms=3000 repeats=3 capacity=65536 producers=4 consumers=4 algo=both"

echo.
echo --- PadOff ---
"%EXE_OFF%" %ARGS%
set EC1=%ERRORLEVEL%

echo.
echo --- PadOn ---
"%EXE_ON%" %ARGS%
set EC2=%ERRORLEVEL%

echo.
echo --- BackoffOn ---
"%EXE_BF%" %ARGS%
set EC3=%ERRORLEVEL%

echo ExitCodes: PadOff=%EC1% PadOn=%EC2% BackoffOn=%EC3%
if %EC1% NEQ 0 exit /b %EC1%
if %EC2% NEQ 0 exit /b %EC2%
if %EC3% NEQ 0 exit /b %EC3%

echo Done.
exit /b 0

