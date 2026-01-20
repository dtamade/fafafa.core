@echo off
setlocal
cd /d "%~dp0"

set "ACTION=%~1"
if "%ACTION%"=="" set "ACTION=test"

echo [BUILD] lazbuild --build-mode=Debug fafafa.core.sync.rwlock.downgrade.test.lpi
lazbuild --build-mode=Debug fafafa.core.sync.rwlock.downgrade.test.lpi
if errorlevel 1 exit /b 1

if /I "%ACTION%"=="test" (
  echo [RUN] bin\fafafa.core.sync.rwlock.downgrade.test.exe
  if exist "bin\fafafa.core.sync.rwlock.downgrade.test.exe" (
    "bin\fafafa.core.sync.rwlock.downgrade.test.exe" --all --format=plain
    if errorlevel 1 exit /b 1
  ) else (
    echo [ERROR] test executable not found: bin\fafafa.core.sync.rwlock.downgrade.test.exe
    exit /b 100
  )
)

if "%FAFAFA_INTERACTIVE%"=="1" pause
exit /b 0
