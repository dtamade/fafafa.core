@echo off
setlocal enabledelayedexpansion
REM One-click build and run for allocator-related tests (Windows)
REM - Builds and runs the following test projects in Debug mode:
REM   1) tests\fafafa.core.mem.manager.rtl\fafafa.core.mem.manager.rtl.test.lpi
REM   2) tests\fafafa.core.mem.manager.crt\fafafa.core.mem.manager.crt.test.lpi
REM   3) tests\fafafa.core.mem.allocator.mimalloc\fafafa.core.mem.allocator.mimalloc.test.lpi
REM   4) tests\fafafa.core.mem\tests_mem_allocator_only.lpi
REM - Automatically copies mimalloc.dll/mimalloc-redirect.dll from repo tmp_build to the mimalloc test bin if present
REM - Fails fast on first error (exit /b 1)

set ROOT=%~dp0..
cd /d "%ROOT%"

echo === Using lazbuild ===
where lazbuild >nul 2>&1
if errorlevel 1 (
  if exist tools\lazbuild.bat (
    set LAZ=tools\lazbuild.bat
  ) else (
    echo [ERROR] lazbuild not found on PATH and tools\lazbuild.bat missing.
    exit /b 1
  )
) else (
  set LAZ=lazbuild
)

echo === 1) Build & Run manager.rtl tests ===
"%LAZ%" tests\fafafa.core.mem.manager.rtl\fafafa.core.mem.manager.rtl.test.lpi --bm=Debug -B || exit /b 1
set RTL_BIN=tests\fafafa.core.mem.manager.rtl\bin\fafafa.core.mem.manager.rtl.test.exe
if not exist "%RTL_BIN%" (
  echo [ERROR] Missing output: %RTL_BIN%
  exit /b 1
)
"%RTL_BIN%" --all --format=plain || exit /b 1

echo === 2) Build & Run manager.crt tests ===
"%LAZ%" tests\fafafa.core.mem.manager.crt\fafafa.core.mem.manager.crt.test.lpi --bm=Debug -B || exit /b 1
set CRT_BIN=tests\fafafa.core.mem.manager.crt\bin\fafafa.core.mem.manager.crt.test.exe
if not exist "%CRT_BIN%" (
  echo [ERROR] Missing output: %CRT_BIN%
  exit /b 1
)
"%CRT_BIN%" --all --format=plain || exit /b 1

echo === 3) Build & Run mimalloc allocator tests ===
"%LAZ%" tests\fafafa.core.mem.allocator.mimalloc\fafafa.core.mem.allocator.mimalloc.test.lpi --bm=Debug -B || exit /b 1
REM Copy DLLs if available
if exist tmp_build\mimalloc.dll copy /Y tmp_build\mimalloc.dll tests\fafafa.core.mem.allocator.mimalloc\bin\mimalloc.dll >nul 2>&1
if exist tmp_build\mimalloc-redirect.dll copy /Y tmp_build\mimalloc-redirect.dll tests\fafafa.core.mem.allocator.mimalloc\bin\mimalloc-redirect.dll >nul 2>&1
set MI_BIN=tests\fafafa.core.mem.allocator.mimalloc\bin\fafafa.core.mem.allocator.mimalloc.test_debug.exe
if not exist "%MI_BIN%" (
  set MI_BIN=tests\fafafa.core.mem.allocator.mimalloc\bin\fafafa.core.mem.allocator.mimalloc.test.exe
)
if not exist "%MI_BIN%" (
  echo [ERROR] Missing output: mimalloc test exe
  exit /b 1
)
"%MI_BIN%" --all --format=plain || exit /b 1

echo === 4) Build & Run allocator-only tests (aligned + optional) ===
"%LAZ%" tests\fafafa.core.mem\tests_mem_allocator_only.lpi --bm=Debug -B || exit /b 1
set AO_BIN=tests\fafafa.core.mem\bin\tests_mem_allocator_only_debug.exe
if not exist "%AO_BIN%" (
  set AO_BIN=tests\fafafa.core.mem\bin\tests_mem_allocator_only.exe
)
if not exist "%AO_BIN%" (
  echo [ERROR] Missing output: allocator-only test exe
  exit /b 1
)
"%AO_BIN%" --all --format=plain || exit /b 1

echo.
echo [OK] Allocator-related tests built and executed successfully.
exit /b 0

