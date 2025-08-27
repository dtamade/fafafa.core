@echo off

set "SCRIPT_DIR=%~dp0"
set "ROOT_DIR=%SCRIPT_DIR%..\.."
set "LAZBUILD=%ROOT_DIR%\tools\lazbuild.bat"

set "PROJECT=tests_csv.lpi"
set "BIN_DIR=%SCRIPT_DIR%bin"
set "LIB_DIR=%SCRIPT_DIR%lib"
set "TMP_DIR=%SCRIPT_DIR%tmp"
set "TEST_EXECUTABLE=%BIN_DIR%\tests.exe"

if not exist "%BIN_DIR%" mkdir "%BIN_DIR%"
if not exist "%LIB_DIR%" mkdir "%LIB_DIR%"
if not exist "%TMP_DIR%" mkdir "%TMP_DIR%"

echo Building project: %PROJECT% ...
call "%LAZBUILD%" "%SCRIPT_DIR%%PROJECT%"
if %ERRORLEVEL% NEQ 0 (
  echo.
  echo Build failed with error code %ERRORLEVEL%.
  goto END
)

echo.
echo Build successful.
echo.

if /i "%1"=="test" (
  echo Running tests...
  rem Run tests with CWD switched to module tmp dir so relative CSV files go under tests/tmp
  pushd "%TMP_DIR%"
  rem Capture human-readable log and XML report (logs still under bin)
  "%TEST_EXECUTABLE%" --all --progress -u > "%BIN_DIR%\last-run.txt" 2>&1
  "%TEST_EXECUTABLE%" --all --format=xml > "%BIN_DIR%\results.xml" 2>&1
  popd
  rem Strip ExceptionMessage nodes from outputs to avoid server-side XML issues
  powershell -NoProfile -ExecutionPolicy Bypass -Command "$p = '%BIN_DIR%\results.xml'; if (Test-Path $p) { $xml = [xml](Get-Content -LiteralPath $p); $nodes = $xml.SelectNodes('//ExceptionMessage'); if ($nodes) { foreach ($n in @($nodes)) { $null = $n.ParentNode.RemoveChild($n) } }; $xml.Save($p) }"
  powershell -NoProfile -ExecutionPolicy Bypass -Command "$p = '%BIN_DIR%\last-run.txt'; if (Test-Path $p) { $raw = Get-Content -LiteralPath $p -Raw; $raw = [System.Text.RegularExpressions.Regex]::Replace($raw, '<ExceptionMessage>.*?</ExceptionMessage>', '', 'Singleline'); Set-Content -LiteralPath $p -Value $raw }"
  rem Fallback: regex strip ExceptionMessage from results.xml as well
  powershell -NoProfile -ExecutionPolicy Bypass -Command "$p = '%BIN_DIR%\results.xml'; if (Test-Path $p) { $raw = Get-Content -LiteralPath $p -Raw; $raw = [System.Text.RegularExpressions.Regex]::Replace($raw, '<ExceptionMessage>.*?</ExceptionMessage>', '', 'Singleline'); Set-Content -LiteralPath $p -Value $raw }"
  rem Show quick console log
  type "%BIN_DIR%\last-run.txt"
  echo ====== End of console log ======
) else (
  echo To run tests, call this script with the 'test' parameter.
)

:END

