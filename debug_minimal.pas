program debug_minimal;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  SysUtils,
  fafafa.core.sync.recMutex;

var
  RecMutex: IRecMutex;
begin
  WriteLn('=== Minimal Debug Test ===');
  
  RecMutex := MakeRecMutex;
  
  WriteLn('Testing TryAcquire(0)...');
  if RecMutex.TryAcquire(0) then
  begin
    WriteLn('TryAcquire(0) succeeded');
    try
      WriteLn('Calling Release...');
      RecMutex.Release;
      WriteLn('Release succeeded');
    except
      on E: Exception do
        WriteLn('Release failed: ', E.Message);
    end;
  end
  else
  begin
    WriteLn('TryAcquire(0) failed');
  end;
  
  WriteLn('=== Test Complete ===');
end.
