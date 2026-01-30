@echo off
@echo off
setlocal
REM Build and run fs watch example (Windows only demo)
set LAZBUILD="D:\devtools\lazarus\trunk\lazarus\lazbuild.exe"
%LAZBUILD% examples\fafafa.core.fs\example_fs.lpi >nul 2>&1
%LAZBUILD% examples\fafafa.core.fs\example_fs_watch.lpr
if %ERRORLEVEL% NEQ 0 (
  echo Build failed.
  exit /b 1
)
examples\fafafa.core.fs\example_fs_watch.exe %*

setlocal ENABLEDELAYEDEXPANSION
cd /d "%~dp0"
set "BIN=%CD%\bin"

echo [info] Windows 提示：
echo   - Symlink 示例需管理员/开发者模式或设置 FAFAFA_TEST_SYMLINK=1
echo   - 长路径示例需开启系统 LongPathsEnabled（可选 FAFAFA_TEST_WIN_LONGPATH=1）

echo === RunExamples (fafafa.core.fs) ===
if not exist "%BIN%" (
  echo Bin not found: %BIN%
  echo Please run BuildExamples.bat first.
  exit /b 1
)

echo Running examples from %BIN%
set "PAUSE_NEXT=pause >nul"

for %%E in (^
  example_fs_basic.exe ^
  example_fs_advanced.exe ^
  example_fs_performance.exe ^
  example_fs_benchmark.exe ^
  example_fs_path.exe ^
  example_copytree_follow.exe ^
) do (
  if exist "%BIN%\%%E" (
    echo.
    echo ==== Running %%E ====
    "%BIN%\%%E"
    echo.
    echo Press any key to continue...
    %PAUSE_NEXT%
  ) else (
    echo Skipped: %%E (not built)
  )
)

echo All runnable examples done.
exit /b 0
endlocal

