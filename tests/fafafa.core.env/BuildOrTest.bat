@echo off
setlocal

REM Wrapper to make this module discoverable by tests\run_all_tests.bat (it looks for BuildOrTest.bat)
REM Delegate to the existing buildOrTest.bat to keep backward compatibility.

pushd "%~dp0"
call buildOrTest.bat %*
set "RC=%ERRORLEVEL%"
popd
exit /b %RC%
