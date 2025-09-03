@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo.
echo ┌──────────────────────────────────────────────────────────────────────────────┐
echo │                                                                              │
echo │          ______   ______     ______   ______     ______   ______             │
echo │         /\  ___\ /\  __ \   /\  ___\ /\  __ \   /\  ___\ /\  __ \            │
echo │         \ \  __\ \ \  __ \  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \           │
echo │          \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\          │
echo │           \/_/     \/_/\/_/   \/_/     \/_/\/_/   \/_/     \/_/\/_/          │
echo │                                                                              │
echo │                                Studio                                        │
echo └──────────────────────────────────────────────────────────────────────────────┘
echo.
echo 🧪 fafafa.core.sync.recMutex 单元测试构建脚本
echo.

:: 检查 lazbuild 是否可用
where lazbuild >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ 错误：找不到 lazbuild 命令，请确保 Lazarus 已正确安装并添加到 PATH
    pause
    exit /b 1
)

:: 创建输出目录
if not exist "bin" mkdir bin
if not exist "lib" mkdir lib

echo 🔨 正在构建测试项目...
echo.

:: 构建 Debug 版本
echo 📋 构建 Debug 版本...
lazbuild --build-mode=Debug fafafa.core.sync.recMutex.test.lpi
if %errorlevel% neq 0 (
    echo ❌ Debug 版本构建失败
    pause
    exit /b 1
)

echo ✅ Debug 版本构建成功
echo.

:: 询问是否运行测试
set /p run_test="🤔 是否运行测试？(Y/n): "
if /i "!run_test!"=="n" goto end
if /i "!run_test!"=="no" goto end

echo.
echo 🚀 运行测试...
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo.

:: 运行测试
bin\fafafa.core.sync.recMutex.test.exe
set test_result=%errorlevel%

echo.
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

if %test_result% equ 0 (
    echo ✅ 所有测试通过！
) else (
    echo ❌ 测试失败，退出代码：%test_result%
)

:end
echo.
echo 📊 构建统计：
if exist "bin\fafafa.core.sync.recMutex.test.exe" (
    for %%F in ("bin\fafafa.core.sync.recMutex.test.exe") do (
        echo    可执行文件大小：%%~zF 字节
    )
)

echo 🎯 构建完成！
echo.
pause
