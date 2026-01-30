@echo off
setlocal
set "SCRIPT_DIR=%~dp0"
rd /s /q "%SCRIPT_DIR%bin" 2>nul
rd /s /q "%SCRIPT_DIR%lib" 2>nul
echo Cleaned examples output folders.
endlocal

