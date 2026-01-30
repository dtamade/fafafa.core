@echo off
setlocal enabledelayedexpansion

echo ========================================
echo fafafa.core.socket Example Build Script
echo ========================================
echo.

set PROJECT_ROOT=%~dp0..\..
set EXAMPLES_DIR=%~dp0
set BIN_DIR=%EXAMPLES_DIR%bin
set LIB_DIR=%EXAMPLES_DIR%lib

echo Project Root: %PROJECT_ROOT%
echo Examples Dir: %EXAMPLES_DIR%
echo Output Dir: %BIN_DIR%
echo Lib Dir: %LIB_DIR%
echo.

REM Use tools\lazbuild.bat wrapper which falls back to PATH lazbuild
set "LAZBUILD=%PROJECT_ROOT%\tools\lazbuild.bat"
if not exist "%LAZBUILD%" (
    echo Error: tools\lazbuild.bat not found
    pause
    exit /b 1
)

REM Create output directories
if not exist "%BIN_DIR%" (
    echo Creating output directory: %BIN_DIR%
    mkdir "%BIN_DIR%"
)

if not exist "%LIB_DIR%" (
    echo Creating lib directory: %LIB_DIR%
    mkdir "%LIB_DIR%"
)

echo ========================================
echo Building Debug Version
echo ========================================

call "%LAZBUILD%" --build-mode=Debug "%EXAMPLES_DIR%example_socket.lpi"
if %ERRORLEVEL% neq 0 (
    echo Error: Debug build failed
    pause
    exit /b 1
)
call "%LAZBUILD%" --build-mode=Debug "%EXAMPLES_DIR%echo_server.lpi"
if %ERRORLEVEL% neq 0 (
    echo Debug mode missing for echo_server, trying default mode...
    call "%LAZBUILD%" "%EXAMPLES_DIR%echo_server.lpi"
    if %ERRORLEVEL% neq 0 (
        echo Error: Build failed (echo_server)
        pause
        exit /b 1
    )
)
call "%LAZBUILD%" --build-mode=Debug "%EXAMPLES_DIR%echo_client.lpi"
if %ERRORLEVEL% neq 0 (
    echo Debug mode missing for echo_client, trying default mode...
    call "%LAZBUILD%" "%EXAMPLES_DIR%echo_client.lpi"
    if %ERRORLEVEL% neq 0 (
        echo Error: Build failed (echo_client)
        pause
        exit /b 1
    )
)
call "%LAZBUILD%" --build-mode=Debug "%EXAMPLES_DIR%udp_server.lpi"
if %ERRORLEVEL% neq 0 (
    echo Debug mode missing for udp_server, trying default mode...
    call "%LAZBUILD%" "%EXAMPLES_DIR%udp_server.lpi"
    if %ERRORLEVEL% neq 0 (
        echo Error: Build failed (udp_server)
        pause
        exit /b 1
    )
)
call "%LAZBUILD%" --build-mode=Debug "%EXAMPLES_DIR%udp_client.lpi"
if %ERRORLEVEL% neq 0 (
    echo Debug mode missing for udp_client, trying default mode...
    call "%LAZBUILD%" "%EXAMPLES_DIR%udp_client.lpi"
    if %ERRORLEVEL% neq 0 (
        echo Error: Build failed (udp_client)
        pause
        exit /b 1
    )
)
call "%LAZBUILD%" --build-mode=Debug "%EXAMPLES_DIR%best_practices_nonblocking.pas"
if %ERRORLEVEL% neq 0 (
    echo Debug: falling back to default build for best_practices_nonblocking...
    call "%LAZBUILD%" "%EXAMPLES_DIR%best_practices_nonblocking.pas"
    if %ERRORLEVEL% neq 0 (
        echo Error: Build failed (best_practices_nonblocking)
        pause
        exit /b 1
    )
)

REM Build minimal nonblocking poller echo example (Debug)
call "%LAZBUILD%" --build-mode=Debug "%EXAMPLES_DIR%example_echo_min_poll_nb.pas"
if %ERRORLEVEL% neq 0 (
    echo Debug: falling back to default build for example_echo_min_poll_nb...
    call "%LAZBUILD%" "%EXAMPLES_DIR%example_echo_min_poll_nb.pas"
    if %ERRORLEVEL% neq 0 (
        echo Error: Build failed (example_echo_min_poll_nb)
        pause
        exit /b 1
    )
)



echo Debug build successful!

echo ========================================
echo Building Release Version
echo ========================================

call "%LAZBUILD%" --build-mode=Release "%EXAMPLES_DIR%example_socket.lpi"
if %ERRORLEVEL% neq 0 (
    echo Error: Release build failed
    pause
    exit /b 1
)
call "%LAZBUILD%" --build-mode=Release "%EXAMPLES_DIR%echo_server.lpi"
if %ERRORLEVEL% neq 0 (
    echo Release mode missing for echo_server, trying default mode...
    call "%LAZBUILD%" "%EXAMPLES_DIR%echo_server.lpi"
    if %ERRORLEVEL% neq 0 (
        echo Error: Build failed (echo_server)
        pause
        exit /b 1
    )
)
call "%LAZBUILD%" --build-mode=Release "%EXAMPLES_DIR%echo_client.lpi"
if %ERRORLEVEL% neq 0 (
    echo Release mode missing for echo_client, trying default mode...
    call "%LAZBUILD%" "%EXAMPLES_DIR%echo_client.lpi"
    if %ERRORLEVEL% neq 0 (
        echo Error: Build failed (echo_client)
        pause
        exit /b 1
    )
)
call "%LAZBUILD%" --build-mode=Release "%EXAMPLES_DIR%udp_server.lpi"
if %ERRORLEVEL% neq 0 (
    echo Release mode missing for udp_server, trying default mode...
    call "%LAZBUILD%" "%EXAMPLES_DIR%udp_server.lpi"
    if %ERRORLEVEL% neq 0 (
        echo Error: Build failed (udp_server)
        pause
        exit /b 1
    )
call "%LAZBUILD%" --build-mode=Release "%EXAMPLES_DIR%best_practices_nonblocking.pas"
if %ERRORLEVEL% neq 0 (
    echo Release: falling back to default build for best_practices_nonblocking...
    call "%LAZBUILD%" "%EXAMPLES_DIR%best_practices_nonblocking.pas"
    if %ERRORLEVEL% neq 0 (
        echo Error: Build failed (best_practices_nonblocking)
        pause
        exit /b 1

REM Build minimal nonblocking poller echo example (Release)
call "%LAZBUILD%" --build-mode=Release "%EXAMPLES_DIR%example_echo_min_poll_nb.pas"
if %ERRORLEVEL% neq 0 (
    echo Release: falling back to default build for example_echo_min_poll_nb...
    call "%LAZBUILD%" "%EXAMPLES_DIR%example_echo_min_poll_nb.pas"
    if %ERRORLEVEL% neq 0 (
        echo Error: Build failed (example_echo_min_poll_nb)
        pause
        exit /b 1
    )
)

    )
)

)
call "%LAZBUILD%" --build-mode=Release "%EXAMPLES_DIR%udp_client.lpi"
if %ERRORLEVEL% neq 0 (
    echo Release mode missing for udp_client, trying default mode...
    call "%LAZBUILD%" "%EXAMPLES_DIR%udp_client.lpi"
    if %ERRORLEVEL% neq 0 (
        echo Error: Build failed (udp_client)
        pause
        exit /b 1
    )
)

echo Release build successful!

echo ========================================
echo Build Complete
echo ========================================
echo.
echo Executable location:
echo   %BIN_DIR%\example_socket.exe
echo   %BIN_DIR%\echo_server.exe
echo   %BIN_DIR%\echo_client.exe
echo   %BIN_DIR%\udp_server.exe
echo   %BIN_DIR%\udp_client.exe
echo   %BIN_DIR%\best_practices_nonblocking.exe
echo   %BIN_DIR%\example_echo_min_poll_nb.exe
echo.
echo Run examples:
echo   %BIN_DIR%\example_socket.exe address-demo
echo   %BIN_DIR%\example_socket.exe tcp-server 8080
echo   %BIN_DIR%\example_socket.exe tcp-client localhost 8080
echo   %BIN_DIR%\echo_server.exe --port=8080
echo   %BIN_DIR%\echo_client.exe --host=127.0.0.1 --port=8080 --message="hello"
echo   %BIN_DIR%\udp_server.exe --port=9090
echo   %BIN_DIR%\udp_client.exe --host=127.0.0.1 --port=9090 --message="hello-udp"
echo   %BIN_DIR%\best_practices_nonblocking.exe --demo
echo   %BIN_DIR%\example_echo_min_poll_nb.exe
echo.

pause
