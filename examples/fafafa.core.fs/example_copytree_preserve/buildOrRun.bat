@echo off
setlocal
cd /d "%~dp0"
echo [info] PreserveTimes/Perms 示例：POSIX 有效；Windows 仅时间戳 best-effort（权限模型不同）


set SRC=..\..\..\src
set BIN=.\bin
set LIB=.\lib

if not exist "%BIN%" mkdir "%BIN%"
if not exist "%LIB%" mkdir "%LIB%"

set FPC_FLAGS=-Mobjfpc -Scghi -gl -O1 -Fu%SRC% -FE%BIN% -FU%LIB% -dUseCThreads

fpc %FPC_FLAGS% example_copytree_preserve.lpr
if %ERRORLEVEL% NEQ 0 (
  echo Build failed
  exit /b 1
)

"%BIN%\example_copytree_preserve.exe"
exit /b %ERRORLEVEL%

