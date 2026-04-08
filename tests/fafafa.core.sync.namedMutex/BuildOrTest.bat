@echo off
setlocal
cd /d "%~dp0"

set "ACTION=%~1"
if "%ACTION%"=="" set "ACTION=test"
set "LAZBUILD_BIN=%LAZBUILD%"
if "%LAZBUILD_BIN%"=="" set "LAZBUILD_BIN=lazbuild"
set "PROJECT_LPI=fafafa.core.sync.namedMutex.test.lpi"
set "TEST_BIN=bin\fafafa.core.sync.namedMutex.test"

where "%LAZBUILD_BIN%" >nul 2>nul
if errorlevel 1 (
  echo [ERROR] lazbuild not found in PATH
  exit /b 1
)

if exist "bin" rmdir /s /q "bin"
if exist "lib" rmdir /s /q "lib"
mkdir "bin"
mkdir "lib"

echo [BUILD] %LAZBUILD_BIN% %PROJECT_LPI%
call "%LAZBUILD_BIN%" "%PROJECT_LPI%"
if errorlevel 1 exit /b 1

if /I "%ACTION%"=="test" goto run_tests
if /I "%ACTION%"=="run" goto run_tests
echo [INFO] build-only mode (%ACTION%)
exit /b 0

:run_tests
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
