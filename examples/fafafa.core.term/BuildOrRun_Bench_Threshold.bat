@echo off
setlocal
set EXE=bench_line_threshold.exe
set LPR=bench_line_threshold.lpr

REM Optional: set USE_MEMORY by env to use in-memory backend
REM   set FAFAFA_TERM_BENCH_USE_MEMORY=1
REM Optional: set threshold 0..1
REM   set FAFAFA_TERM_DIFF_LINE_THRESHOLD=0.35

if not exist "%EXE%" (
  echo [BUILD] fpc %LPR%
  fpc -B -Fu"..\..\src" -Fu"..\..\src\ui" %LPR%
  if errorlevel 1 goto :eof
)

echo [RUN] %EXE%
%EXE%

endlocal

