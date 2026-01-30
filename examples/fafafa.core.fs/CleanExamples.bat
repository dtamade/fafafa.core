@echo off
setlocal ENABLEDELAYEDEXPANSION
cd /d "%~dp0"

echo === CleanExamples (fafafa.core.fs) ===
if exist bin (
  echo Removing bin\*
  rmdir /s /q bin 2>nul
)
if exist lib (
  echo Removing lib\*
  rmdir /s /q lib 2>nul
)
for %%F in (*.o *.ppu *.rst *.compiled) do del /q "%%F" 2>nul

echo Clean done.
exit /b 0
endlocal

