@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "ACTION=%~1"
if "%ACTION%"=="" set "ACTION=test"
if not "%~1"=="" shift

set "ROOT=%~dp0"
if not "%ROOT:~-1%"=="\" set "ROOT=%ROOT%\"
set "OUTPUT_ROOT=%SIMD_OUTPUT_ROOT%"
if "%OUTPUT_ROOT%"=="" set "OUTPUT_ROOT=%ROOT%"

set "PROJECT_NAME=fafafa.core.simd.intrinsics.sse.test"
set "PROJECT_FILE=%ROOT%%PROJECT_NAME%.lpi"
set "LAZBUILD_EXE=%LAZBUILD%"
if "%LAZBUILD_EXE%"=="" set "LAZBUILD_EXE=lazbuild"

set "TARGET_CPU="
for /f "delims=" %%I in ('fpc -iTP 2^>nul') do if not defined TARGET_CPU set "TARGET_CPU=%%I"
if not defined TARGET_CPU set "TARGET_CPU=nativecpu"
set "TARGET_OS="
for /f "delims=" %%I in ('fpc -iTO 2^>nul') do if not defined TARGET_OS set "TARGET_OS=%%I"
if not defined TARGET_OS set "TARGET_OS=nativeos"

set "BIN_DIR=%OUTPUT_ROOT%\bin"
set "LIB_DIR=%OUTPUT_ROOT%\lib\%TARGET_CPU%-%TARGET_OS%"
set "LOG_DIR=%OUTPUT_ROOT%\logs"
set "EXECUTABLE=%BIN_DIR%\%PROJECT_NAME%.exe"
set "BUILD_LOG=%LOG_DIR%\build.txt"
set "TEST_LOG=%LOG_DIR%\test.txt"

if not exist "%BIN_DIR%" mkdir "%BIN_DIR%"
if not exist "%LIB_DIR%" mkdir "%LIB_DIR%"
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

if /I "%ACTION%"=="clean" goto :clean
if /I "%ACTION%"=="build" goto :build
if /I "%ACTION%"=="check" goto :check
if /I "%ACTION%"=="test" goto :test

echo Usage: %~nx0 [clean^|build^|check^|test]
exit /b 2

:clean
echo [CLEAN] Removing %BIN_DIR%, %LIB_DIR%, %LOG_DIR%
if exist "%BIN_DIR%" rmdir /s /q "%BIN_DIR%"
if exist "%LIB_DIR%" rmdir /s /q "%LIB_DIR%"
if exist "%LOG_DIR%" rmdir /s /q "%LOG_DIR%"
exit /b 0

:normalize_binary
if exist "%EXECUTABLE%" exit /b 0
if exist "%ROOT%bin\%PROJECT_NAME%.exe" (
  copy /y "%ROOT%bin\%PROJECT_NAME%.exe" "%EXECUTABLE%" >nul
  echo [BUILD] Binary normalized: %ROOT%bin\%PROJECT_NAME%.exe ^> %EXECUTABLE%
)
exit /b 0

:build
echo [BUILD] Project: %PROJECT_FILE% (output_root=%OUTPUT_ROOT%)
> "%BUILD_LOG%" echo.
"%LAZBUILD_EXE%" --build-all "--opt=-FE%BIN_DIR%" "--opt=-FU%LIB_DIR%" "%PROJECT_FILE%" >> "%BUILD_LOG%" 2>&1
if errorlevel 1 (
  echo [BUILD] FAILED ^(see %BUILD_LOG%^)
  exit /b 1
)
call :normalize_binary
if not exist "%EXECUTABLE%" (
  echo [BUILD] FAILED ^(binary missing after build: %EXECUTABLE%^)
  exit /b 1
)
echo [BUILD] OK
exit /b 0

:check
call :build
if errorlevel 1 exit /b 1
findstr /r /c:"src\fafafa\.core\.simd.*Warning:" /c:"src\fafafa\.core\.simd.*Hint:" "%BUILD_LOG%" >nul 2>nul
if not errorlevel 1 (
  echo [CHECK] Found warnings/hints from SIMD units in build log
  type "%BUILD_LOG%"
  exit /b 1
)
echo [CHECK] OK ^(no SIMD unit warnings/hints^)
exit /b 0

:test
call :check
if errorlevel 1 exit /b 1
echo [TEST] Running: %EXECUTABLE% --all --format=plain
> "%TEST_LOG%" echo.
"%EXECUTABLE%" --all --format=plain > "%TEST_LOG%" 2>&1
if errorlevel 1 (
  echo [TEST] FAILED ^(see %TEST_LOG%^)
  exit /b 1
)
findstr /r /c:"^[1-9][0-9]* unfreed memory blocks" "%TEST_LOG%" >nul 2>nul
if not errorlevel 1 (
  echo [LEAK] FAILED: heaptrc reports unfreed blocks
  type "%TEST_LOG%"
  exit /b 1
)
echo [TEST] OK
echo [LEAK] OK
exit /b 0
