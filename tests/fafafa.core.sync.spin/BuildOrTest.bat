@echo off
setlocal
cd /d "%~dp0"

set "ACTION=%~1"
if "%ACTION%"=="" set "ACTION=test"

echo [BUILD] lazbuild --build-mode=Debug fafafa.core.sync.spin.test.lpi
lazbuild --build-mode=Debug fafafa.core.sync.spin.test.lpi
if errorlevel 1 exit /b 1

if /I "%ACTION%"=="test" (
  echo [RUN] bin\fafafa.core.sync.spin.test.exe
  if exist "bin\fafafa.core.sync.spin.test.exe" (
    "bin\fafafa.core.sync.spin.test.exe" --all --format=plain
    if errorlevel 1 exit /b 1
  ) else (
    echo [ERROR] test executable not found: bin\fafafa.core.sync.spin.test.exe
    exit /b 100
  )
)

if "%FAFAFA_INTERACTIVE%"=="1" pause
exit /b 0
