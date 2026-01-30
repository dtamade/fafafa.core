@echo off
setlocal ENABLEDELAYEDEXPANSION
cd /d "%~dp0"
for %%D in (bin lib) do if exist "%%D" rmdir /s /q "%%D"
echo Cleaned example outputs.
exit /b 0

