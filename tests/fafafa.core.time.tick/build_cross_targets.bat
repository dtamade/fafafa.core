@echo off
setlocal enabledelayedexpansion

REM Cross-platform builders for fafafa.core.time.tick tests
REM Prereq: lazbuild in PATH and corresponding FPC cross compilers installed

set PROJ=%~dp0fafafa.core.time.tick.test.lpi
set OUTDIR=%~dp0bin
if not exist "%OUTDIR%" mkdir "%OUTDIR%"

REM Windows targets
call :build_one win32  i386     .exe
call :build_one win64  x86_64   .exe
call :build_one win32  arm      .exe
call :build_one win64  aarch64  .exe
call :build_one win32  riscv32  .exe
call :build_one win64  riscv64  .exe

REM Linux targets
call :build_one linux  i386
call :build_one linux  x86_64
call :build_one linux  arm
call :build_one linux  aarch64
call :build_one linux  riscv32
call :build_one linux  riscv64

echo. & echo Done.
goto :eof

:build_one
REM Args: %1=os %2=cpu %3=ext (optional)
set TOS=%1
set TCPU=%2
set EXT=%3

echo. & echo ===== Building --os=%TOS% --cpu=%TCPU% =====
lazbuild %PROJ% --os=%TOS% --cpu=%TCPU% --build-mode=Debug
if errorlevel 1 (
  echo [SKIP] Build failed for %TCPU%-%TOS% (missing cross or compile error)
  goto :eof
)

set BUILT=%OUTDIR%\%TCPU%-%TOS%\fafafa.core.time.tick.test%EXT%
if exist "%BUILT%" (
  echo [OK] %BUILT%
) else (
  echo [WARN] Expected output not found: %BUILT%
)
goto :eof

