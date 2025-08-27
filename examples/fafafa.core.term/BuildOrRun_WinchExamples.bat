@echo off
setlocal ENABLEDELAYEDEXPANSION

set "ROOT=%~dp0"
set "LAZ=%ROOT%..\..\tools\lazbuild.bat"
set "SRC=%ROOT%..\..\src"
set "BIN=%ROOT%bin"

if not exist "%BIN%" mkdir "%BIN%"

REM Build all WINCH-related examples via example_term.lpi
call "%LAZ%" "%ROOT%example_term.lpi" >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
  echo [Build] Failed to run lazbuild. Please set LAZBUILD_EXE or ensure lazbuild in PATH.
  goto END
)

echo [Build] OK.

REM Optional: run one demo by name
if /I "%~1"=="run" (
  set "TARGET=%~2"
  if "%TARGET%"=="" goto LIST
  set "EXE=%BIN%\%TARGET%.exe"
  if exist "%EXE%" (
    echo [Run] %EXE%
    "%EXE%"
  ) else (
    echo [Run] Not found: %EXE%
    goto LIST
  )
  goto END
)

echo.
echo To run a demo, execute its EXE from %BIN%.
echo Examples:
echo   "%BIN%\resize_layout_demo.exe"
echo   "%BIN%\example_winch_channel.exe"
echo   "%BIN%\example_win_winch_poll.exe"
echo   "%BIN%\example_winch_portable.exe"

goto END

:LIST
echo Available targets for 'run':
echo   resize_layout_demo

echo   example_winch_channel

echo   example_win_winch_poll

echo   example_winch_portable

goto END

echo.
echo To run a demo, execute its EXE from %BIN%.
echo Examples:
echo   "%BIN%\resize_layout_demo.exe"
echo   "%BIN%\example_winch_channel.exe"
echo   "%BIN%\example_win_winch_poll.exe"
echo   "%BIN%\example_winch_portable.exe"

goto END

:USAGE
echo Usage: BuildOrRun_WinchExamples.bat

echo This script uses example_term.lpi to build WINCH-related examples into bin/.
echo If lazbuild is not on PATH, set LAZBUILD_EXE to lazbuild.exe.

echo After build, run demos from the bin folder.

echo Examples to run:
echo   bin\resize_layout_demo.exe

echo   bin\example_winch_channel.exe

echo   bin\example_win_winch_poll.exe

echo   bin\example_winch_portable.exe

:END
endlocal

