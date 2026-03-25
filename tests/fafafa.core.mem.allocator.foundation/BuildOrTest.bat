@echo off
setlocal
call "%~dp0buildOrTest.bat" %*
exit /b %ERRORLEVEL%
