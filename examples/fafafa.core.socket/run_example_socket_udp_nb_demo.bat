@echo off
setlocal

set SCRIPT_DIR=%~dp0
set PORT=%1
if "%PORT%"=="" set PORT=9098
set MSG=%2

rem 启动UDP非阻塞服务器（后台窗口）
start "example_socket_udp_server_nb" cmd /c "%SCRIPT_DIR%\run_example_socket.bat" udp-server-nb %PORT%

rem 等待服务器就绪
timeout /t 1 >nul 2>&1

rem 运行客户端，完成一次往返交互
call "%SCRIPT_DIR%\run_example_socket.bat" udp-client-nb 127.0.0.1 %PORT% "%MSG%"

endlocal

