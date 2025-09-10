program minimal_nonreentrant_test;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

uses
  SysUtils,
  fafafa.core.sync.base,
  fafafa.core.sync.mutex;

procedure TestNonReentrantAcquire;
var
  m: IMutex;
begin
  WriteLn('Test: Non-reentrant Acquire should raise EDeadlockError...');
  m := MakeMutex;
  m.Acquire;
  try
    try
      m.Acquire; // should raise
      WriteLn('FAIL: Acquire did not raise on re-entrant call');
    except
      on E: EDeadlockError do
        WriteLn('OK: Caught EDeadlockError as expected');
      on E: Exception do
        WriteLn('FAIL: Caught unexpected exception: ', E.ClassName, ': ', E.Message);
    end;
  finally
    m.Release;
  end;
end;

procedure TestNonReentrantTryAcquire;
var
  m: IMutex;
begin
  WriteLn('Test: Non-reentrant TryAcquire should raise EDeadlockError...');
  m := MakeMutex;
  m.Acquire;
  try
    try
      if m.TryAcquire then
      begin
        WriteLn('FAIL: TryAcquire returned True on re-entrant call');
        m.Release;
      end
      else
        WriteLn('NOTE: TryAcquire returned False (expected raise in this implementation)');
    except
      on E: EDeadlockError do
        WriteLn('OK: Caught EDeadlockError as expected');
      on E: Exception do
        WriteLn('FAIL: Caught unexpected exception: ', E.ClassName, ': ', E.Message);
    end;
  finally
    m.Release;
  end;
end;

begin
  try
    TestNonReentrantAcquire;
    TestNonReentrantTryAcquire;
  except
    on E: Exception do
    begin
      WriteLn('Unhandled exception: ', E.ClassName, ': ', E.Message);
      Halt(1);
    end;
  end;
end.

