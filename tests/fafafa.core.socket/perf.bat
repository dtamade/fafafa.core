@echo off
setlocal ENABLEDELAYEDEXPANSION
REM Perf runner: wraps buildOrTest.bat test-perf with optional overrides
set "SCRIPT_DIR=%~dp0"
set "RUNNER=%SCRIPT_DIR%buildOrTest.bat"

REM Allow quick overrides
if not defined PERF_TCP_SHORT_CONN_C set PERF_TCP_SHORT_CONN_C=20
if not defined PERF_TCP_LONG_CLIENTS set PERF_TCP_LONG_CLIENTS=3
if not defined PERF_TCP_LONG_ITER set PERF_TCP_LONG_ITER=50
if not defined PERF_PAYLOAD_SIZE set PERF_PAYLOAD_SIZE=256
if not defined PERF_ACCEPT_TIMEOUT_MS set PERF_ACCEPT_TIMEOUT_MS=1000
if not defined PERF_UDP_PACKETS set PERF_UDP_PACKETS=200
if not defined PERF_UDP_RECV_TIMEOUT_MS set PERF_UDP_RECV_TIMEOUT_MS=10

call "%RUNNER%" test-perf
set RC=%ERRORLEVEL%
endlocal & exit /b %RC%

