@echo off
setlocal
cd /d "%~dp0"

echo Building examples...
lazbuild *.lpi
if errorlevel 1 exit /b 1

echo Running examples...
for %%f in (bin\*.exe) do (
    echo === Running %%~nxf ===
    "%%f"
    echo.
)
