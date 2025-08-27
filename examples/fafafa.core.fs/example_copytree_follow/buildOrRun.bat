@echo off
setlocal
cd /d "%~dp0"

REM Prefer lazbuild for consistency across examples
..\..\..\tools\lazbuild.bat example_copytree_follow.lpi
if errorlevel 1 goto :eof

REM Precondition tips for symlink on Windows
if "%FAFAFA_TEST_SYMLINK%"=="1" (
  echo [INFO] FAFAFA_TEST_SYMLINK=1 set. Attempting symlink demo.
) else (
  echo [INFO] To demo symlink behavior on Windows, run elevated or enable Developer Mode, or set FAFAFA_TEST_SYMLINK=1.
)

bin\example_copytree_follow.exe
endlocal
