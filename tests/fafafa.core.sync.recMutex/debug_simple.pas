program debug_simple;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  SysUtils,
  fafafa.core.sync.recMutex;

var
  RecMutex: IRecMutex;
  CurrentThread: TThreadID;
begin
  WriteLn('=== Simple Debug Test ===');
  
  RecMutex := MakeRecMutex;
  CurrentThread := GetCurrentThreadId;
  
  WriteLn('Current Thread ID: ', CurrentThread);
  WriteLn('Initial Owner: ', RecMutex.OwnerThreadId);
  WriteLn('Initial Count: ', RecMutex.RecursionCount);
  WriteLn('Initial IsOwned: ', RecMutex.IsOwnedByCurrentThread);
  WriteLn;
  
  WriteLn('Calling TryAcquire(0)...');
  if RecMutex.TryAcquire(0) then
  begin
    WriteLn('TryAcquire(0) succeeded');
    WriteLn('After TryAcquire(0):');
    WriteLn('  Owner: ', RecMutex.OwnerThreadId);
    WriteLn('  Count: ', RecMutex.RecursionCount);
    WriteLn('  IsOwned: ', RecMutex.IsOwnedByCurrentThread);
    WriteLn;
    
    WriteLn('Calling Release...');
    try
      RecMutex.Release;
      WriteLn('Release succeeded');
    except
      on E: Exception do
      begin
        WriteLn('Release failed: ', E.Message);
        WriteLn('State after failed Release:');
        WriteLn('  Owner: ', RecMutex.OwnerThreadId);
        WriteLn('  Count: ', RecMutex.RecursionCount);
        WriteLn('  IsOwned: ', RecMutex.IsOwnedByCurrentThread);
      end;
    end;
  end
  else
  begin
    WriteLn('TryAcquire(0) failed');
  end;
  
  WriteLn;
  WriteLn('=== Test Complete ===');
end.
