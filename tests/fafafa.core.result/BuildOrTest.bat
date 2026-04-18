@echo off
setlocal ENABLEEXTENSIONS

set "SCRIPT_DIR=%~dp0"
call "%SCRIPT_DIR%buildOrTest.bat" %*
set "RC=%ERRORLEVEL%"

endlocal & exit /b %RC%
