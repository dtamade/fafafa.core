program debug_test_simple;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  SysUtils,
  fafafa.core.sync.spin.base,
  fafafa.core.sync.spin;

var
  L: ISpinLock;
  Policy: TSpinLockPolicy;

begin
  WriteLn('Simple Debug Test');
  WriteLn('=================');
  
  Policy := DefaultSpinLockPolicy;
  L := MakeSpinLock(Policy);
  
  WriteLn('Testing TryAcquire...');
  if L.TryAcquire then
  begin
    WriteLn('TryAcquire succeeded');
    L.Release;
    WriteLn('Release succeeded');
  end
  else
    WriteLn('TryAcquire failed');
  
  WriteLn('Testing TryAcquire(0)...');
  try
    if L.TryAcquire(0) then
    begin
      WriteLn('TryAcquire(0) succeeded');
      try
        L.Release;
        WriteLn('Release succeeded');
      except
        on E: Exception do
          WriteLn('Release failed: ', E.Message);
      end;
    end
    else
      WriteLn('TryAcquire(0) failed');
  except
    on E: Exception do
      WriteLn('TryAcquire(0) exception: ', E.Message);
  end;
  
  WriteLn('Test completed');
end.
