@echo off
setlocal enabledelayedexpansion

set "SCRIPT_DIR=%~dp0"
set "SRC_DIR=%SCRIPT_DIR%..\..\src"
set "BIN_DIR=%SCRIPT_DIR%bin"
set "LOG_DIR=%SCRIPT_DIR%logs"
if not exist "%BIN_DIR%" mkdir "%BIN_DIR%"
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

set "LOG_FILE=%LOG_DIR%\latest_smoke_queues.log"

REM Build padding smoke (SPSC+MPMC)
fpc -Fu"%SRC_DIR%" -FE"%BIN_DIR%" "%SCRIPT_DIR%test_padding_smoke.lpr" > "%LOG_FILE%" 2>&1
if %ERRORLEVEL% NEQ 0 (
  echo [build] test_padding_smoke.lpr failed >> "%LOG_FILE%"
) else (
  "%BIN_DIR%\test_padding_smoke.exe" >> "%LOG_FILE%" 2>&1
)

echo.>>"%LOG_FILE%"
REM Build ringbuffer smoke (prefer lazbuild project if available)
set "LAZBUILD=%SCRIPT_DIR%..\..\tools\lazbuild.bat"
if exist "%SCRIPT_DIR%smoke_ringbuffer.lpi" (
  call "%LAZBUILD%" --build-mode=Release "%SCRIPT_DIR%smoke_ringbuffer.lpi" >> "%LOG_FILE%" 2>&1
  if %ERRORLEVEL% NEQ 0 (
    echo [build] smoke_ringbuffer.lpi failed >> "%LOG_FILE%"
  ) else (
    set "SMOKE_TIMER=${SMOKE_TIMER}" & set "SMOKE_OPS=${SMOKE_OPS}"
    "%BIN_DIR%\smoke_ringbuffer.exe" >> "%LOG_FILE%" 2>&1
  )
) else (
  fpc -Fu"%SRC_DIR%" -FE"%BIN_DIR%" "%SCRIPT_DIR%smoke_ringbuffer.lpr" >> "%LOG_FILE%" 2>&1
  if %ERRORLEVEL% NEQ 0 (
    echo [build] smoke_ringbuffer.lpr failed >> "%LOG_FILE%"
  ) else (
    set "SMOKE_TIMER=${SMOKE_TIMER}" & set "SMOKE_OPS=${SMOKE_OPS}"
    "%BIN_DIR%\smoke_ringbuffer.exe" >> "%LOG_FILE%" 2>&1
  )
)

echo.>>"%LOG_FILE%"
echo ===== Summary (OK/Failed lines) ===== >> "%LOG_FILE%"
findstr /I "OK Failed" "%LOG_FILE%" >> "%LOG_FILE%" 2>&1

echo === Latest smoke queues log ===
type "%LOG_FILE%"

endlocal & exit /b 0

