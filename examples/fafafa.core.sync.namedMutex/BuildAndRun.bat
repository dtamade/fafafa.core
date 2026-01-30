@echo off
setlocal
cd /d "%~dp0"

echo [BUILD] lazbuild --build-mode=Debug *.lpi
lazbuild --build-mode=Debug *.lpi
if errorlevel 1 exit /b 1

echo [RUN] Running example...
for %%f in (bin\*.exe) do (
  echo [RUN] %%f
  "%%f"
  if errorlevel 1 exit /b 1
)

if "%FAFAFA_INTERACTIVE%"=="1" pause
exit /b 0
