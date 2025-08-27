@echo off
setlocal ENABLEDELAYEDEXPANSION
cd /d %~dp0
call ..\..\tools\lazbuild.bat play_bench_ids.lpi || exit /b 1
.\bin\play_bench_ids.exe

