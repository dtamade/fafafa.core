@echo off
setlocal
cd /d "%~dp0"

set "ACTION=%~1"
if "%ACTION%"=="" set "ACTION=test"

set "FPC_BIN=%FPC_BIN%"
if "%FPC_BIN%"=="" set "FPC_BIN=%FPC%"
if "%FPC_BIN%"=="" set "FPC_BIN=fpc"

set "PROJECT_LPR=fafafa.core.socket.async.test.lpr"
set "TEST_BIN=bin\fafafa.core.socket.async.test"

if /I "%ACTION%"=="clean" goto do_clean
if /I "%ACTION%"=="build" goto do_build
if /I "%ACTION%"=="test" goto do_test
if /I "%ACTION%"=="run" goto do_test

echo Usage: %~nx0 [build^|test^|clean]
exit /b 2

:resolve_fpc
if exist "%FPC_BIN%" exit /b 0
where "%FPC_BIN%" >nul 2>&1
if errorlevel 1 (
  echo [ERROR] fpc not found: %FPC_BIN%
  exit /b 1
)
exit /b 0

:clean_outputs
if exist "bin" rmdir /s /q "bin"
if exist "lib" rmdir /s /q "lib"
mkdir "bin"
mkdir "lib"
exit /b 0

:do_build
call :resolve_fpc
if errorlevel 1 exit /b %errorlevel%

call :clean_outputs
if errorlevel 1 exit /b %errorlevel%

echo [BUILD] %FPC_BIN% %PROJECT_LPR%
call "%FPC_BIN%" -MObjFPC -Scghi -O2 -vewnhibq -Fu..\..\src -Fu. -FUlib -FEbin "%PROJECT_LPR%"
if errorlevel 1 exit /b 1

if exist "%TEST_BIN%" exit /b 0
if exist "%TEST_BIN%.exe" exit /b 0

echo [ERROR] test executable not found after build: %TEST_BIN%[.exe]
exit /b 100

:do_test
call :do_build
if errorlevel 1 exit /b %errorlevel%

echo [RUN] %TEST_BIN%
if exist "%TEST_BIN%" (
  "%TEST_BIN%" --all --progress --format=plain
  exit /b %errorlevel%
)

"%TEST_BIN%.exe" --all --progress --format=plain
exit /b %errorlevel%

:do_clean
call :clean_outputs
if errorlevel 1 exit /b %errorlevel%
echo [CLEAN] removed bin and lib
exit /b 0
