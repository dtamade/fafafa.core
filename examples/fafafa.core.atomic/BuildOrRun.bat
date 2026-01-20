@echo off
setlocal
cd /d "%~dp0"

set "ACTION=%~1"
if "%ACTION%"=="" set "ACTION=run"

echo === Building fafafa.core.atomic Examples ===
echo.

REM Deterministic outputs
if exist bin rmdir /s /q bin
if exist lib rmdir /s /q lib
mkdir bin
mkdir lib

set "EXAMPLES=example_basic_operations example_producer_consumer example_tagged_ptr_aba example_thread_counter"

for %%e in (%EXAMPLES%) do (
  echo [BUILD] lazbuild --build-mode=Release %%e.lpi
  lazbuild --build-mode=Release %%e.lpi
  if errorlevel 1 exit /b 1
)

echo.
echo === All examples built successfully! ===
echo.

if /I "%ACTION%"=="run" (
  echo === Running Examples ===
  echo.

  for %%e in (%EXAMPLES%) do (
    if exist "bin\%%e.exe" (
      echo [RUN] bin\%%e.exe
      "bin\%%e.exe"
      echo.
    ) else (
      echo [WARN] Executable not found: bin\%%e.exe
    )
  )
) else (
  echo [INFO] Build-only mode (%ACTION%)
  echo You can run the examples manually:
  for %%e in (%EXAMPLES%) do (
    echo   bin\%%e.exe
  )
)

if "%FAFAFA_INTERACTIVE%"=="1" pause
