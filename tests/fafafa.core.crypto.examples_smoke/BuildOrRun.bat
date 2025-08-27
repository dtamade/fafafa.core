@echo off
setlocal ENABLEDELAYEDEXPANSION
REM Build and run minimal crypto smoke tests (non-CI)

set ROOT=%~dp0..\..\
pushd "%ROOT%" >nul

REM Try lazbuild first, then fallback to fpc
set LAZ=%LAZBUILD_EXE%
if not defined LAZ set LAZ=lazbuild

"%LAZ%" --bm=Release tests\fafafa.core.crypto.examples_smoke\tests_crypto_smoke.lpi || goto :try_fpc

:run
if exist tests\fafafa.core.crypto.examples_smoke\bin\tests_crypto_smoke.exe (
  tests\fafafa.core.crypto.examples_smoke\bin\tests_crypto_smoke.exe
) else (
  tests\fafafa.core.crypto.examples_smoke\bin\tests_crypto_smoke
)
set EC=%ERRORLEVEL%
popd >nul
exit /b %EC%

:try_fpc
fpc -Mobjfpc -Scghi -Fu"src" -Fi"src" -FE"tests\fafafa.core.crypto.examples_smoke\bin" tests\fafafa.core.crypto.examples_smoke\smoke_runner.lpr || (popd & exit /b 1)
goto :run

