@echo off
setlocal

set "LAZBUILD=%~dp0..\..\tools\lazbuild.bat"
if not exist "%LAZBUILD%" set "LAZBUILD=lazbuild"

set "PROJECT_LPI=%~dp0tests_core_min.lpi"
set "PROJECT_LPR=%~dp0tests_core_min.lpr"
if exist "%PROJECT_LPI%" (
  set "PROJECT=%PROJECT_LPI%"
) else (
  set "PROJECT=%PROJECT_LPR%"
)
set "BIN=%~dp0bin"
set "OUT=%~dp0out"
set "LIB=%~dp0lib"
set "EXE=%BIN%\tests_core_min.exe"

if not exist "%BIN%" mkdir "%BIN%"

if /i "%1"=="build" goto :BUILD
if /i "%1"=="run" goto :RUN
if /i "%1"=="run-json" goto :RUNJSON
if /i "%1"=="run-junit" goto :RUNJUNIT
if /i "%1"=="clean" goto :CLEAN

:BUILD
"%LAZBUILD%" "%PROJECT%" > "%BIN%\__last_build.log" 2>&1
set "CODE=%ERRORLEVEL%"
if not "%CODE%"=="0" (
  echo Build failed with code %CODE%.
  rem 友好提示：捕捉 lazbuild 的常见错误 "Invalid compiler \"\""
  findstr /C:"Invalid compiler " "%BIN%\__last_build.log" >nul 2>&1
  if "%ERRORLEVEL%"=="0" (
    echo.
    echo [Hint] lazbuild 报告 Invalid compiler ""：这通常是 Lazarus/FPC 工具链未初始化。
    echo        解决方法：
    echo        1) 打开一次 Lazarus IDE，完成初始配置（会写入 config_lazarus），或
    echo        2) 先运行主套件：cmd /c tests\fafafa.core.test\BuildOrTest.bat test
    echo        然后再执行：cmd /c tests\fafafa.core.test.min\BuildOrRun.bat build
    echo.
  )
  type "%BIN%\__last_build.log"
  exit /b %CODE%
)
echo Build successful.
echo Artifacts:
if exist "%EXE%" echo   EXE: %EXE%
if exist "%BIN%\__last_build.log" echo   LOG: %BIN%\__last_build.log
if /i "%1"=="build" exit /b 0

:CLEAN
if exist "%BIN%" rmdir /s /q "%BIN%"
if exist "%OUT%" rmdir /s /q "%OUT%"
if exist "%LIB%" rmdir /s /q "%LIB%"
echo Cleaned: bin, out, lib
exit /b 0

:RUN
if not exist "%EXE%" (
  echo Executable not found: %EXE%
  echo Try: %~n0 build
  exit /b 1
)
"%EXE%" %*
set "CODE=%ERRORLEVEL%"
echo Artifacts:
if exist "%EXE%" echo   EXE: %EXE%
if exist "%OUT%\report.json" echo   JSON: %OUT%\report.json
if exist "%OUT%\junit.xml" echo   JUNIT: %OUT%\junit.xml
exit /b %CODE%

:RUNJSON
if not exist "%EXE%" (
  echo Executable not found: %EXE%
  echo Try: %~n0 build
  exit /b 1
)
if not exist "%OUT%" mkdir "%OUT%"
set "FAFAFA_TEST_USE_SINK_JSON=1"
"%EXE%" --json="%OUT%\report.json" %*
echo JSON report: %OUT%\report.json
exit /b %ERRORLEVEL%

:RUNJUNIT
if not exist "%EXE%" (
  echo Executable not found: %EXE%
  echo Try: %~n0 build
  exit /b 1
)
if not exist "%OUT%" mkdir "%OUT%"
"%EXE%" --junit="%OUT%\junit.xml" %*
echo JUnit report: %OUT%\junit.xml
exit /b %ERRORLEVEL%

