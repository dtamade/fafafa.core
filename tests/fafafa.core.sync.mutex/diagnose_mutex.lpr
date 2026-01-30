program diagnose_mutex;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  SysUtils,
  fafafa.core.sync.base,  // 包含 EDeadlockError 定义
  fafafa.core.sync.mutex;

var
  m: IMutex;
begin
  WriteLn('=== Mutex Reentry Detection Diagnostic ===');
  WriteLn;
  
  WriteLn('Step 1: Creating mutex...');
  m := MakeMutex;
  WriteLn('  OK: Mutex created');
  WriteLn;
  
  WriteLn('Step 2: First Acquire...');
  m.Acquire;
  WriteLn('  OK: First acquire succeeded');
  WriteLn;
  
  WriteLn('Step 3: Second Acquire (should raise EDeadlockError)...');
  try
    m.Acquire;
    WriteLn('  FAIL: Second acquire did NOT raise exception!');
    WriteLn('  This indicates reentry detection is NOT working.');
    Halt(1);
  except
    on E: EDeadlockError do
    begin
      WriteLn('  OK: Caught EDeadlockError as expected');
      WriteLn('  Message: ', E.Message);
    end;
    on E: Exception do
    begin
      WriteLn('  FAIL: Caught unexpected exception: ', E.ClassName);
      WriteLn('  Message: ', E.Message);
      Halt(1);
    end;
  end;
  
  WriteLn;
  WriteLn('=== Diagnostic Complete: PASS ===');
end.
