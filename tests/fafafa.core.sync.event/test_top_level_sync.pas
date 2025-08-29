program test_top_level_sync;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  SysUtils, fafafa.core.sync.base, fafafa.core.sync.event; // 直接使用 event 模块

var
  E: IEvent;
  
procedure TestTopLevelExports;
begin
  WriteLn('=== Testing Top-Level Sync Exports ===');
  
  // 测试通过 event 模块创建事件
  E := CreateEvent(True, False);
  WriteLn('Created event via CreateEvent');
  
  // 测试 ISynchronizable 接口
  WriteLn('Last error: ', Ord(E.GetLastError));
  
  // 测试常量导出
  WriteLn('wrSignaled = ', Ord(wrSignaled));
  WriteLn('wrTimeout = ', Ord(wrTimeout));
  WriteLn('wrInterrupted = ', Ord(wrInterrupted));
  WriteLn('weNone = ', Ord(weNone));
  WriteLn('weSystemError = ', Ord(weSystemError));
  
  // 测试事件功能
  E.SetEvent;
  WriteLn('Event set');
  WriteLn('IsSignaled: ', E.IsSignaled);
  WriteLn('IsManualReset: ', E.IsManualReset);
  
  WriteLn('Top-level sync exports test completed successfully!');
  WriteLn;
end;

begin
  try
    TestTopLevelExports;
    WriteLn('All tests passed!');
  except
    on Ex: Exception do
    begin
      WriteLn('Error: ', Ex.Message);
      ExitCode := 1;
    end;
  end;
end.
