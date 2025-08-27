@echo off

set "SCRIPT_DIR=%~dp0"
set "BIN_DIR=..\..\..\bin"
set "SRC_DIR=..\..\..\src"

echo Building fafafa.core.term integration tests...
echo =============================================

echo.
echo Building terminal_compatibility_test.lpr...
fpc -Fu%SRC_DIR% -FE%BIN_DIR% -FU..\..\..\lib terminal_compatibility_test.lpr
if %ERRORLEVEL% NEQ 0 (
    echo Build failed for terminal_compatibility_test.lpr
    goto END
)

echo.
echo Building interactive_test.lpr...
fpc -Fu%SRC_DIR% -FE%BIN_DIR% -FU..\..\..\lib interactive_test.lpr
if %ERRORLEVEL% NEQ 0 (
    echo Build failed for interactive_test.lpr
    goto END
)

echo.
echo All integration tests built successfully!
echo.
echo Available executables in %BIN_DIR%:
echo   - terminal_compatibility_test.exe  (Automated compatibility testing)
echo   - interactive_test.exe             (Interactive feature testing)
echo.
echo Usage:
echo   %BIN_DIR%\terminal_compatibility_test.exe
echo   %BIN_DIR%\interactive_test.exe
echo.
echo Note: These tests should be run in different terminal environments
echo       to verify cross-platform compatibility:
echo   - Windows Command Prompt
echo   - Windows PowerShell
echo   - Windows Terminal
echo   - Git Bash
echo   - WSL
echo   - Various Linux terminals (xterm, gnome-terminal, konsole, etc.)
echo   - macOS Terminal
echo.

:END
