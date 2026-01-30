@echo off
setlocal enabledelayedexpansion

:: Build and run benchmark in two modes: PadOff (default) and PadOn (-dFAFAFA_LOCKFREE_CACHELINE_PAD)
:: Output: runs both executables and prints results to console

set "SCRIPT_DIR=%~dp0"
set "ROOT_DIR=%SCRIPT_DIR%..\.."
set "BIN_DIR=%ROOT_DIR%\bin"
set "TOOLS_DIR=%ROOT_DIR%\tools"
set "LAZBUILD=%TOOLS_DIR%\lazbuild.bat"

if not exist "%LAZBUILD%" (
  echo ERROR: lazbuild helper not found: %LAZBUILD%
  echo Please ensure tools\lazbuild.bat exists and is configured to call Lazarus' lazbuild.
  exit /b 1
)

if not exist "%BIN_DIR%" mkdir "%BIN_DIR%"

set "LPI=%SCRIPT_DIR%benchmark_lockfree.lpi"

echo === Build PadOff (no padding macro) ===
call "%LAZBUILD%" --build-mode=PadOff "%LPI%"
if %ERRORLEVEL% NEQ 0 (
  echo ERROR: Build PadOff failed
  exit /b 1
)

echo === Build PadOn (-dFAFAFA_LOCKFREE_CACHELINE_PAD) ===
call "%LAZBUILD%" --build-mode=PadOn "%LPI%"
if %ERRORLEVEL% NEQ 0 (
  echo ERROR: Build PadOn failed
  exit /b 1
)

set "EXE_OFF=%BIN_DIR%\benchmark_lockfree_padoff.exe"
set "EXE_ON=%BIN_DIR%\benchmark_lockfree_padon.exe"

if not exist "%EXE_OFF%" (
  echo ERROR: Missing %EXE_OFF%
  exit /b 1
)
if not exist "%EXE_ON%" (
  echo ERROR: Missing %EXE_ON%
  exit /b 1
)

echo.
echo ===== Running PadOff =====
echo (Tip: program pauses at end; sending newline automatically)
echo. | "%EXE_OFF%"
set "EC1=%ERRORLEVEL%"

echo.
echo ===== Running PadOn =====
echo (Tip: program pauses at end; sending newline automatically)
echo. | "%EXE_ON%"
set "EC2=%ERRORLEVEL%"

echo.
echo Exit codes: PadOff=%EC1% PadOn=%EC2%
if %EC1% NEQ 0 exit /b %EC1%
if %EC2% NEQ 0 exit /b %EC2%

echo.
echo ✅ Completed PadOn/PadOff benchmark runs.
exit /b 0

