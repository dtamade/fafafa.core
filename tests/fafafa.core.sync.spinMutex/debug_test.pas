program debug_test;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  SysUtils,
  fafafa.core.sync.spinMutex, fafafa.core.sync.spinMutex.base;

var
  Mutex: ISpinMutex;

begin
  WriteLn('=== Debug Test ===');
  
  try
    WriteLn('Creating SpinMutex...');
    Mutex := CreateSpinMutex('debug_test');
    
    if Mutex = nil then
    begin
      WriteLn('ERROR: CreateSpinMutex returned nil');
      Halt(1);
    end
    else
    begin
      WriteLn('SUCCESS: SpinMutex created');
      WriteLn('Name: ', Mutex.GetName);
      WriteLn('IsLocked: ', Mutex.IsLocked);
    end;
    
  except
    on E: Exception do
    begin
      WriteLn('EXCEPTION: ', E.ClassName, ': ', E.Message);
      Halt(1);
    end;
  end;
  
  WriteLn('=== Test Complete ===');
end.
