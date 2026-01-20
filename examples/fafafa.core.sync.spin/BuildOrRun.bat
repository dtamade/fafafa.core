@echo off
setlocal
cd /d "%~dp0"

set "ACTION=%~1"
if "%ACTION%"=="" set "ACTION=run"

echo === Building fafafa.core.sync.spin Examples ===
echo.

echo [BUILD] lazbuild --build-mode=Release example_basic_usage.lpi
lazbuild --build-mode=Release example_basic_usage.lpi
if errorlevel 1 exit /b 1

echo [BUILD] lazbuild --build-mode=Release example_use_cases.lpi
lazbuild --build-mode=Release example_use_cases.lpi
if errorlevel 1 exit /b 1

echo.
echo === Build completed successfully! ===
echo.

if /I "%ACTION%"=="build" (
  echo Build-only mode. Skipping execution.
  exit /b 0
)

echo === Running Examples ===
echo.

if exist "bin\example_basic_usage.exe" (
  echo [RUN] bin\example_basic_usage.exe
  bin\example_basic_usage.exe
  echo.
) else (
  echo [WARN] Executable not found: bin\example_basic_usage.exe
)

if exist "bin\example_use_cases.exe" (
  echo [RUN] bin\example_use_cases.exe
  bin\example_use_cases.exe
  echo.
) else (
  echo [WARN] Executable not found: bin\example_use_cases.exe
)

echo === All examples completed! ===

if "%FAFAFA_INTERACTIVE%"=="1" pause
exit /b 0
