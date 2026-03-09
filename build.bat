@echo off
REM NOTE (2026-02-06):
REM This legacy script used to compile a removed unit (fafafa.core.simd.types / simd.sync)
REM and a non-existent test folder. Keep it as a convenience wrapper and redirect to the
REM real SIMD test build script.

echo Redirecting to tests\fafafa.core.simd\buildOrTest.bat ...

pushd "%~dp0tests\fafafa.core.simd" || exit /b 1
call buildOrTest.bat %*
set EXITCODE=%errorlevel%
popd
exit /b %EXITCODE%
