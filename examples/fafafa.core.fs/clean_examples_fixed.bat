@echo off
cd /d "%~dp0"
echo === Cleaning fafafa.core.fs Examples ===
echo.

REM Set paths
set PROJECT_ROOT=%~dp0..\..
set BIN_PATH=bin
set LIB_PATH=%~dp0lib

echo Cleaning bin directory: %BIN_PATH%
if exist "%BIN_PATH%\example_fs_*.exe" (
    del /q "%BIN_PATH%\example_fs_*.exe" && echo Removed examples from bin
)

echo.
echo Cleaning lib directory: %LIB_PATH%
if exist "%LIB_PATH%\*.o" (
    del /q "%LIB_PATH%\*.o" && echo Removed object files from lib
)
if exist "%LIB_PATH%\*.ppu" (
    del /q "%LIB_PATH%\*.ppu" && echo Removed unit files from lib
)
if exist "%LIB_PATH%\*.a" (
    del /q "%LIB_PATH%\*.a" && echo Removed library files from lib
)

echo.
echo Cleaning source directory...
del /q *.exe *.o *.ppu *.a *.dbg *.compiled 2>nul && echo Removed binary files from source

echo.
echo === Clean Complete ===
echo.
echo All directories cleaned:
echo   - %BIN_PATH% (examples removed)
echo   - %LIB_PATH% (intermediate files removed)
echo   - Source directory (binary files removed)
