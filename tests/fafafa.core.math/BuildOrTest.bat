@echo off
setlocal
cd /d "%~dp0"

:: 编译
echo Building tests...
lazbuild *.lpi
if errorlevel 1 exit /b 1

:: 运行测试
echo Running tests...
for %%f in (bin\*.exe) do "%%f"
