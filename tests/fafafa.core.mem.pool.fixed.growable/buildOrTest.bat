@echo off
setlocal ENABLEDELAYEDEXPANSION
pushd "%~dp0"

set "FINAL_RC=0"
set "LAZBUILD=..\..\tools\lazbuild.bat"
set "PROJECT=%CD%\fafafa.core.mem.pool.fixed.growable.test.lpi"
set "BIN=%CD%\bin"
set "LIB=%CD%\lib"

if exist "%BIN%" rmdir /s /q "%BIN%"
if exist "%LIB%" rmdir /s /q "%LIB%"
mkdir "%BIN%" 2>nul
mkdir "%LIB%" 2>nul

if not exist "%LAZBUILD%" (
  echo [WARN] tools\lazbuild.bat not found, trying PATH lazbuild
  set "LAZBUILD=lazbuild"
)

echo Building project: %PROJECT% ...
call "%LAZBUILD%" "%PROJECT%" --build-mode=Debug
if %ERRORLEVEL% NEQ 0 (
  echo Build failed with error code %ERRORLEVEL%.
  set "FINAL_RC=%ERRORLEVEL%"
  goto END
)

echo.
echo Build successful.
echo.

if /i "%1"=="test" (
  set "EXE=%BIN%\fafafa.core.mem.pool.fixed.growable.test.exe"
  echo [INFO] Executable should be at: !EXE!
  if exist "!EXE!" (
    "!EXE!" --all --format=plainnotiming
    set "FINAL_RC=!ERRORLEVEL!"
  ) else (
    echo [ERROR] Test executable not found: !EXE!
    echo [DEBUG] BIN contents:
    dir /b "%BIN%"
    set "FINAL_RC=1"
  )
) else (
  echo To run tests, call this script with the 'test' parameter.
)

:END
popd
endlocal
exit /b %FINAL_RC%

