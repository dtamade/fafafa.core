@echo off
setlocal enabledelayedexpansion

echo ========================================
echo fafafa.core.socket 示例运行脚本
echo ========================================
echo.

set PROJECT_ROOT=%~dp0..\..
set BIN_DIR=%~dp0bin
set EXAMPLE_EXE=%BIN_DIR%\example_socket.exe
set ECHO_SERVER_EXE=%BIN_DIR%\echo_server.exe
set ECHO_CLIENT_EXE=%BIN_DIR%\echo_client.exe
set UDP_SERVER_EXE=%BIN_DIR%\udp_server.exe
set UDP_CLIENT_EXE=%BIN_DIR%\udp_client.exe

echo 项目根目录: %PROJECT_ROOT%
echo 可执行文件: %EXAMPLE_EXE%
echo.

REM 检查可执行文件是否存在
if not exist "%EXAMPLE_EXE%" (
    echo 错误: 找不到示例可执行文件
    echo 请先运行 build_examples.bat 构建示例
    pause
    exit /b 1
)

echo ========================================
echo 可用的示例演示
echo ========================================
echo.
echo 1. 地址解析演示
echo 2. TCP 服务器 (端口 8080)
echo 3. TCP 客户端 (连接到 localhost:8080)
echo 4. UDP 服务器 (端口 9090)
echo 5. UDP 客户端 (发送到 localhost:9090)
echo 6. TCP/UDP IPv6 注意事项 (仅提示)
echo 7. TCP 服务器 (IPv6 端口 8080)
echo 8. TCP 客户端 (IPv6 连接到 ::1:8080)
echo 9. UDP 服务器 (IPv6 端口 9090)
echo 10. UDP 客户端 (IPv6 连接到 ::1:9090)
echo 11. 显示帮助信息
echo 0. 退出
echo.

:menu
set /p choice="请选择要运行的示例 (0-11): "

if "%choice%"=="0" goto :end
if "%choice%"=="1" goto :address_demo
if "%choice%"=="2" goto :tcp_server
if "%choice%"=="3" goto :tcp_client
if "%choice%"=="4" goto :udp_server
if "%choice%"=="5" goto :udp_client
if "%choice%"=="6" goto :ipv6_note
if "%choice%"=="7" goto :tcp_server_v6
if "%choice%"=="8" goto :tcp_client_v6
if "%choice%"=="9" goto :udp_server_v6
if "%choice%"=="10" goto :udp_client_v6
if "%choice%"=="11" goto :help

echo 无效选择，请重新输入
goto :menu

:address_demo
echo.
echo ========================================
echo 运行地址解析演示
echo ========================================
"%EXAMPLE_EXE%" address-demo
echo.
pause
goto :menu

:tcp_server
echo.
echo ========================================
echo 启动 TCP 服务器 (端口 8080)
echo ========================================
echo 注意: 服务器将持续运行，按 Ctrl+C 停止
echo 在另一个终端运行客户端进行测试
echo.
"%EXAMPLE_EXE%" tcp-server 8080
echo.
pause
goto :menu

:tcp_client
echo.
echo ========================================
echo 连接 TCP 服务器 (localhost:8080)
echo ========================================
echo 注意: 请确保 TCP 服务器正在运行
echo.
"%EXAMPLE_EXE%" tcp-client localhost 8080
echo.
pause
goto :menu

:udp_server
echo.
echo ========================================
echo 启动 UDP 服务器 (端口 9090)
echo ========================================
echo 注意: 服务器将持续运行，按 Ctrl+C 停止
echo 在另一个终端运行客户端进行测试
echo.
"%EXAMPLE_EXE%" udp-server 9090
echo.
pause
goto :menu

:udp_client
echo.
echo ========================================
echo 发送 UDP 消息 (localhost:9090)
echo ========================================
echo 注意: 请确保 UDP 服务器正在运行
echo.
"%EXAMPLE_EXE%" udp-client localhost 9090
echo.
pause
goto :menu

:ipv6_note
echo.
echo ========================================
echo IPv6 注意事项（默认用 IPv4，IPv6 为可选）
echo ========================================
echo - Windows 上 IPv6 回环可能被防火墙或策略影响；建议先用 IPv4 验证
echo - 若要启用 IPv6，请参考文档：
echo   服务器：udp_server.exe --ipv6 --bind-host=::1 --port=9090
echo   客  户：udp_client.exe --ipv6 --host=::1 --port=9090 --message=hello-udp
echo - 首次运行注意放行防火墙；遇到超时请参考文档“IPv6 常见问题排查（Windows）”
echo.
pause
goto :menu

:tcp_server_v6
echo.
echo ========================================
echo 启动 TCP 服务器 (IPv6 端口 8080)
echo ========================================
echo 注意: 服务器将持续运行，按 Ctrl+C 停止
echo 如遇连接问题，请先查看菜单 6 的 IPv6 注意事项
echo.
if not exist "%ECHO_SERVER_EXE%" (
  echo 错误: 找不到 echo_server.exe ，请先运行 build_examples.bat
  pause
  goto :menu
)
"%ECHO_SERVER_EXE%" --ipv6 --port=8080
echo.
pause
goto :menu

:tcp_client_v6
echo.
echo ========================================
echo 连接 TCP 服务器 (IPv6 ::1:8080)
echo ========================================
echo 注意: 请确保 TCP 服务器 (IPv6) 正在运行
echo.
if not exist "%ECHO_CLIENT_EXE%" (
  echo 错误: 找不到 echo_client.exe ，请先运行 build_examples.bat
  pause
  goto :menu
)
"%ECHO_CLIENT_EXE%" --ipv6 --host=::1 --port=8080
echo.
pause
goto :menu

:udp_server_v6
echo.
echo ========================================
echo 启动 UDP 服务器 (IPv6 端口 9090)
echo ========================================
echo 注意: 服务器将持续运行，按 Ctrl+C 停止
echo 如遇接收问题，请先查看菜单 6 的 IPv6 注意事项
echo.
if not exist "%UDP_SERVER_EXE%" (
  echo 错误: 找不到 udp_server.exe ，请先运行 build_examples.bat
  pause
  goto :menu
)
"%UDP_SERVER_EXE%" --ipv6 --bind-host=::1 --port=9090
echo.
pause
goto :menu

:udp_client_v6
echo.
echo ========================================
echo 发送 UDP 消息 (IPv6 ::1:9090)
echo ========================================
echo 注意: 请确保 UDP 服务器 (IPv6) 正在运行
echo.
if not exist "%UDP_CLIENT_EXE%" (
  echo 错误: 找不到 udp_client.exe ，请先运行 build_examples.bat
  pause
  goto :menu
)
"%UDP_CLIENT_EXE%" --ipv6 --host=::1 --port=9090 --message=hello-udp --timeout=8000
echo.
pause
goto :menu

:help
echo.
echo ========================================
echo 显示帮助信息
echo ========================================
"%EXAMPLE_EXE%"
echo.
pause
goto :menu

:end
echo 退出示例运行脚本
