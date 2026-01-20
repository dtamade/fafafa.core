@echo off
setlocal
cd /d "%~dp0"

set "ACTION=%~1"
if "%ACTION%"=="" set "ACTION=test"

echo [BUILD] lazbuild --build-mode=Debug fafafa.core.sync.parker.test.lpi
lazbuild --build-mode=Debug fafafa.core.sync.parker.test.lpi
if errorlevel 1 exit /b 1

if /I "%ACTION%"=="test" (
  for %%f in (bin\*.exe) do (
    echo [RUN] %%f
    "%%f" --all --format=plain
    if errorlevel 1 exit /b 1
  )
)

if "%FAFAFA_INTERACTIVE%"=="1" pause
exit /b 0
