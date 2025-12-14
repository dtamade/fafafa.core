@echo off
REM Build and run BitSet tests
cd /d "%~dp0"

if not exist bin mkdir bin
if not exist lib mkdir lib

where lazbuild >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  lazbuild -B tests_bitset.lpi --build-mode=Debug
  echo Running BitSet tests...
  bin\tests_bitset.exe
) else (
  echo lazbuild not found. Please install Lazarus.
  exit /b 1
)

