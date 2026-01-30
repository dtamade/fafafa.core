@echo off
REM Run a quick set of demos for core.process (+ optional: thread/lockfree/crypto)
setlocal EnableDelayedExpansion
set ROOT=%~dp0

REM Always run a couple of process demos
call "%ROOT%fafafa.core.process\build_failfast.bat"
call "%ROOT%fafafa.core.process\run_redirect_demo.bat"

REM Optional: quick thread demos (no default run)
if /i "%1"=="thread" (
  echo Running quick thread demos...
  call "%ROOT%fafafa.core.thread\BuildOrRun.bat" run
)

REM Optional: quick lockfree demos (no default run)
if /i "%1"=="lockfree" (
  echo Running quick lockfree demos...
  call "%ROOT%fafafa.core.lockfree\BuildOrRun.bat" run
)

REM Optional: quick crypto AEAD minimal demo (no default run)
if /i "%1"=="crypto" (
  echo Running quick crypto AEAD minimal demo...
  call "%ROOT%fafafa.core.crypto\BuildOrRun_MinExample.bat"
)

REM Optional: quick crypto file encryption demo (no default run)
if /i "%1"=="fileenc" (
  echo Running quick crypto file encryption demo...
  call "%ROOT%fafafa.core.crypto\BuildOrRun_FileEncryption.bat"
)

REM Optional: quick result demos (no default run)
if /i "%1"=="result" (
  echo Running quick fafafa.core.result demos...
  call "%ROOT%fafafa.core.result\BuildOrRun.bat"
  call "%ROOT%fafafa.core.result\BuildOrRun.bat" filters
)

echo All quick demos finished.
exit /b 0
