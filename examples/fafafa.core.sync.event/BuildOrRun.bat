@echo off
setlocal
cd /d "%~dp0"

set ACTION=%1
if "%ACTION%"=="" set ACTION=run

echo === Building fafafa.core.sync.event Examples ===
echo.

echo [BUILD] lazbuild --build-mode=Default example_auto_vs_manual.lpi
lazbuild --build-mode=Default example_auto_vs_manual.lpi
if errorlevel 1 exit /b 1

echo [BUILD] lazbuild --build-mode=Default example_basic_usage.lpi
lazbuild --build-mode=Default example_basic_usage.lpi
if errorlevel 1 exit /b 1

echo [BUILD] lazbuild --build-mode=Default example_producer_consumer.lpi
lazbuild --build-mode=Default example_producer_consumer.lpi
if errorlevel 1 exit /b 1

echo [BUILD] lazbuild --build-mode=Default example_thread_coordination.lpi
lazbuild --build-mode=Default example_thread_coordination.lpi
if errorlevel 1 exit /b 1

echo [BUILD] lazbuild --build-mode=Default example_timeout_handling.lpi
lazbuild --build-mode=Default example_timeout_handling.lpi
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

if exist "bin\example_auto_vs_manual.exe" (
  echo [RUN] bin\example_auto_vs_manual.exe
  bin\example_auto_vs_manual.exe
  echo.
)

if exist "bin\example_basic_usage.exe" (
  echo [RUN] bin\example_basic_usage.exe
  bin\example_basic_usage.exe
  echo.
)

if exist "bin\example_producer_consumer.exe" (
  echo [RUN] bin\example_producer_consumer.exe
  bin\example_producer_consumer.exe
  echo.
)

if exist "bin\example_thread_coordination.exe" (
  echo [RUN] bin\example_thread_coordination.exe
  bin\example_thread_coordination.exe
  echo.
)

if exist "bin\example_timeout_handling.exe" (
  echo [RUN] bin\example_timeout_handling.exe
  bin\example_timeout_handling.exe
  echo.
)

echo === All examples completed! ===

if "%FAFAFA_INTERACTIVE%"=="1" pause
