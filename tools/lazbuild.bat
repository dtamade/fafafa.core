@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

set "SCRIPT_PATH=%~f0"
set "LAZBUILD_PATH="
set "LAZARUSDIR_PATH="
set "HAS_LAZARUSDIR=0"

if defined LAZBUILD_EXE (
  if exist "%LAZBUILD_EXE%" (
    set "LAZBUILD_PATH=%LAZBUILD_EXE%"
  )
)

if not defined LAZBUILD_PATH (
  for /f "delims=" %%P in ('where lazbuild.exe 2^>nul') do (
    if /I not "%%~fP"=="%SCRIPT_PATH%" (
      set "LAZBUILD_PATH=%%~fP"
      goto :FOUND_LAZBUILD
    )
  )
)

if not defined LAZBUILD_PATH (
  for /f "delims=" %%P in ('where lazbuild 2^>nul') do (
    if /I not "%%~fP"=="%SCRIPT_PATH%" (
      set "LAZBUILD_PATH=%%~fP"
      goto :FOUND_LAZBUILD
    )
  )
)

if not defined LAZBUILD_PATH if defined ProgramFiles (
  if exist "%ProgramFiles%\Lazarus\lazbuild.exe" set "LAZBUILD_PATH=%ProgramFiles%\Lazarus\lazbuild.exe"
)
if not defined LAZBUILD_PATH if defined ProgramFiles(x86) (
  if exist "%ProgramFiles(x86)%\Lazarus\lazbuild.exe" set "LAZBUILD_PATH=%ProgramFiles(x86)%\Lazarus\lazbuild.exe"
)
if not defined LAZBUILD_PATH if exist "C:\lazarus\lazbuild.exe" set "LAZBUILD_PATH=C:\lazarus\lazbuild.exe"
if not defined LAZBUILD_PATH if exist "C:\Lazarus\lazbuild.exe" set "LAZBUILD_PATH=C:\Lazarus\lazbuild.exe"

:FOUND_LAZBUILD
if not defined LAZBUILD_PATH (
  echo [ERROR] lazbuild not found. Set LAZBUILD_EXE or install Lazarus.
  exit /b 127
)

if defined FAFAFA_LAZARUSDIR if exist "%FAFAFA_LAZARUSDIR%\lcl" set "LAZARUSDIR_PATH=%FAFAFA_LAZARUSDIR%"
if not defined LAZARUSDIR_PATH if defined LAZARUSDIR if exist "%LAZARUSDIR%\lcl" set "LAZARUSDIR_PATH=%LAZARUSDIR%"
if not defined LAZARUSDIR_PATH if defined LAZARUS_DIR if exist "%LAZARUS_DIR%\lcl" set "LAZARUSDIR_PATH=%LAZARUS_DIR%"

if not defined LAZARUSDIR_PATH (
  for %%D in ("%LAZBUILD_PATH%") do (
    if exist "%%~dpDlcl" set "LAZARUSDIR_PATH=%%~dpD"
  )
)

echo %* | findstr /I /C:"--lazarusdir" >nul
if not errorlevel 1 set "HAS_LAZARUSDIR=1"

if defined LAZARUSDIR_PATH (
  if "!LAZARUSDIR_PATH:~-1!"=="\" set "LAZARUSDIR_PATH=!LAZARUSDIR_PATH:~0,-1!"
)

if "%HAS_LAZARUSDIR%"=="0" if defined LAZARUSDIR_PATH (
  "%LAZBUILD_PATH%" "--lazarusdir=!LAZARUSDIR_PATH!" %*
) else (
  "%LAZBUILD_PATH%" %*
)

exit /b %ERRORLEVEL%
