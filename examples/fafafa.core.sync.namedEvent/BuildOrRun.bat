@echo off
setlocal
cd /d "%~dp0"

set ACTION=%1
if "%ACTION%"=="" set ACTION=run

echo === Building fafafa.core.sync.namedEvent Examples ===
echo.

echo [BUILD] lazbuild --build-mode=Default example_basic_usage.lpi
lazbuild --build-mode=Default example_basic_usage.lpi
if errorlevel 1 exit /b 1

echo.
echo === Build completed successfully! ===
echo.

if "%ACTION%"=="build" (
  echo Build-only mode. Skipping execution.
  exit /b 0
)

echo === Running Examples ===
echo.

if exist "bin\example_basic_usage.exe" (
  echo [RUN] bin\example_basic_usage.exe
  bin\example_basic_usage.exe
  echo.
)

echo === All examples completed! ===

if "%FAFAFA_INTERACTIVE%"=="1" pause
