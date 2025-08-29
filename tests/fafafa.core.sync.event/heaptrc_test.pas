program heaptrc_test;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  SysUtils, fafafa.core.sync.event;

var
  E: IEvent;
  i: Integer;
begin
  WriteLn('=== HeapTrc 内存泄漏测试 ===');
  WriteLn('创建和销毁 100 个事件对象...');
  
  for i := 1 to 100 do
  begin
    E := fafafa.core.sync.event.CreateEvent(i mod 2 = 0, i mod 3 = 0);
    E.SetEvent;
    E.WaitFor(0);
    E.ResetEvent;
    E := nil; // 显式释放引用
  end;
  
  WriteLn('测试完成。检查下方 HeapTrc 报告...');
end.
