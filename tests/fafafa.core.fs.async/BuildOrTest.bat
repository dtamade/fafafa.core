@echo off
setlocal
cd /d "%~dp0"

set "ACTION=%~1"
if "%ACTION%"=="" set "ACTION=test"

set "FPC_BIN=%FPC_BIN%"
if "%FPC_BIN%"=="" set "FPC_BIN=%FPC%"
if "%FPC_BIN%"=="" set "FPC_BIN=fpc"

set "PROJECT_LPR=run_async_tests.lpr"
set "TEST_BIN=bin\run_async_tests"

if /I "%ACTION%"=="clean" goto clean_only
if /I "%ACTION%"=="build" goto do_build
if /I "%ACTION%"=="test" goto do_build
if /I "%ACTION%"=="run" goto do_build
echo [ERROR] Unsupported action: %ACTION%
echo Usage: %~nx0 [build^|test^|clean]
exit /b 2

:clean_only
if exist "bin" rmdir /s /q "bin"
if exist "lib" rmdir /s /q "lib"
echo [CLEAN] removed bin and lib
exit /b 0

:do_build
where "%FPC_BIN%" >nul 2>nul
if errorlevel 1 (
  echo [ERROR] fpc not found in PATH: %FPC_BIN%
  exit /b 1
)

if exist "bin" rmdir /s /q "bin"
if exist "lib" rmdir /s /q "lib"
mkdir "bin"
mkdir "lib"

echo [BUILD] %FPC_BIN% %PROJECT_LPR%
call "%FPC_BIN%" -MObjFPC -Scghi -O1 -vewnhibq -Fu..\..\src -Fu. -FUlib -FEbin "%PROJECT_LPR%"
if errorlevel 1 (
  echo [ERROR] build failed
  if exist "README.md" echo [INFO] see README.md for the current source blocker
  exit /b 1
)

if /I "%ACTION%"=="build" (
  echo [INFO] build-only mode
  exit /b 0
)

echo [RUN] %TEST_BIN%
if exist "%TEST_BIN%" (
  "%TEST_BIN%" --all --format=plain
  exit /b %errorlevel%
)
if exist "%TEST_BIN%.exe" (
  "%TEST_BIN%.exe" --all --format=plain
  exit /b %errorlevel%
)

echo [ERROR] test executable not found: %TEST_BIN%[.exe]
exit /b 100
