@echo on
setlocal
REM Build and run tests for fafafa.core.archiver using lazbuild (in PATH)

set PROJ=fafafa.core.archiver.test.lpi

pushd %~dp0
REM build (force rebuild to avoid stale state)
lazbuild --verbose --build-all --build-mode=Debug "%PROJ%"
echo [INFO] lazbuild exit code: %errorlevel%
if errorlevel 1 goto :eof

REM run
if not exist "bin" mkdir bin
set EXE=
REM always refresh from lib output (prefer exact path)
if exist "lib\x86_64-win64\fafafa.core.archiver.test.exe" (
  set EXE=bin\tests_archiver.exe
  copy /Y "lib\x86_64-win64\fafafa.core.archiver.test.exe" "bin\tests_archiver.exe" >NUL
) else (
  for /r lib %%F in (*.exe) do (
    echo [INFO] found %%F
    set EXE=bin\tests_archiver.exe
    copy /Y "%%F" "bin\tests_archiver.exe" >NUL
    goto :run
  )
)
if not defined EXE (
  echo [ERROR] no exe found under lib
  goto :eof
)
:run
"%EXE%" --format=plain --all

popd
endlocal

