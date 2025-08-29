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
  Config: TSpinMutexConfig;

begin
  WriteLn('=== Debug Test ===');

  // 检查平台定义
  WriteLn('Platform check:');
  {$IF DEFINED(UNIX)}
  WriteLn('  UNIX is defined');
  {$ENDIF}
  {$IF DEFINED(LINUX)}
  WriteLn('  LINUX is defined');
  {$ENDIF}
  {$IF DEFINED(WINDOWS)}
  WriteLn('  WINDOWS is defined');
  {$ENDIF}
  {$IF DEFINED(UNIX) OR DEFINED(LINUX)}
  WriteLn('  Unix-like platform detected');
  {$ELSE}
  WriteLn('  Non-Unix platform');
  {$ENDIF}

  try
    // 测试工厂函数
    WriteLn('Testing factory function...');
    try
      WriteLn('Calling MakeSpinMutex...');
      Mutex := fafafa.core.sync.spinMutex.MakeSpinMutex('debug_test');
      WriteLn('MakeSpinMutex returned, checking result...');
    except
      on E: Exception do
      begin
        WriteLn('EXCEPTION in MakeSpinMutex: ', E.ClassName, ': ', E.Message);
        Halt(1);
      end;
    end;

    if Mutex = nil then
    begin
      WriteLn('ERROR: MakeSpinMutex returned nil (no exception)');
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
      WriteLn('OUTER EXCEPTION: ', E.ClassName, ': ', E.Message);
      Halt(1);
    end;
  end;

  WriteLn('=== Test Complete ===');
end.
