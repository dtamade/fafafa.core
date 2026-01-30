@echo off
REM Auto-run creator and opener with a random shared name
setlocal enabledelayedexpansion
set NAME=MRB_%RANDOM%_%TIME:~0,2%%TIME:~3,2%%TIME:~6,2%
echo Using shared name: %NAME%
start "creator" "%~dp0bin\example_mapped_ringbuffer_bidir.exe" creator %NAME% 65536 4 100000 32 0
ping -n 2 127.0.0.1 > nul
start "opener"  "%~dp0bin\example_mapped_ringbuffer_bidir.exe" opener  %NAME% 0 0 100000 32 0
endlocal

