program debug_test;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  SysUtils,
  fafafa.core.sync.recMutex;

var
  RecMutex: IRecMutex;
  Result1, Result2: Boolean;
  CurrentThread: TThreadID;
begin
  WriteLn('=== Debug Test for RecMutex TryAcquire(0) ===');

  RecMutex := MakeRecMutex;
  CurrentThread := GetCurrentThreadId;

  WriteLn('Initial state:');
  WriteLn('  CurrentThreadId: ', CurrentThread);
  WriteLn;

  WriteLn('Testing TryAcquire() without timeout...');
  Result1 := RecMutex.TryAcquire;
  WriteLn('  TryAcquire() result: ', Result1);

  if Result1 then
  begin
    WriteLn('  Calling Release...');
    try
      RecMutex.Release;
      WriteLn('  Release successful');
    except
      on E: Exception do
        WriteLn('  Release failed: ', E.Message);
    end;
  end;
  WriteLn;

  WriteLn('Testing TryAcquire(0) with zero timeout...');
  Result2 := RecMutex.TryAcquire(0);
  WriteLn('  TryAcquire(0) result: ', Result2);

  if Result2 then
  begin
    WriteLn('  Calling Release...');
    try
      RecMutex.Release;
      WriteLn('  Release successful');
    except
      on E: Exception do
        WriteLn('  Release failed: ', E.Message);
    end;
  end
  else
  begin
    WriteLn('  TryAcquire(0) failed, not calling Release');
  end;

  WriteLn;
  WriteLn('=== Debug Test Complete ===');
end.
