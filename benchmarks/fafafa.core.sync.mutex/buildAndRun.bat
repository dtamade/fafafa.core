@echo off
setlocal
cd /d "%~dp0"

echo === Building fafafa.core.sync.mutex Benchmark ===
echo.

echo [BUILD] lazbuild --build-mode=Default fafafa.core.sync.mutex.benchmark.parkinglot.lpi
lazbuild --build-mode=Default fafafa.core.sync.mutex.benchmark.parkinglot.lpi
if errorlevel 1 exit /b 1

echo.
echo === Benchmark built successfully! ===
echo.

echo === Running Benchmark ===
echo.

if not exist "results" mkdir results

for /f "tokens=2-4 delims=/ " %%a in ('date /t') do (set mydate=%%c%%a%%b)
for /f "tokens=1-2 delims=/:" %%a in ('time /t') do (set mytime=%%a%%b)
set timestamp=%mydate%_%mytime%

if exist "bin\fafafa.core.sync.mutex.benchmark.parkinglot.exe" (
  echo [RUN] bin\fafafa.core.sync.mutex.benchmark.parkinglot.exe
  bin\fafafa.core.sync.mutex.benchmark.parkinglot.exe > results\benchmark_%timestamp%.txt
  type results\benchmark_%timestamp%.txt
) else (
  echo [ERROR] Benchmark executable not found
  exit /b 1
)

echo.
echo === Benchmark completed! ===
echo Results saved to: results\
echo.

if "%FAFAFA_INTERACTIVE%"=="1" pause
