program example_semaphore;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils,
  fafafa.core.sync;

procedure DemoSemaphoreBasic;
var
  S: ISemaphore;
  ok: Boolean;
begin
  WriteLn('=== 信号量基础演示 ===');
  S := TSemaphore.Create(1, 3); // 初始1，可达3

  // 获取一次（应成功，剩余0）
  S.Acquire;
  WriteLn('Acquire 1 次: OK');

  // TryAcquire(0ms)（应失败）
  ok := S.TryAcquire(0);
  WriteLn('TryAcquire(0): ', BoolToStr(ok, '成功', '失败'));

  // 释放2次（总计到2）
  S.Release(2);
  WriteLn('Release(2) 后可用计数: ', S.GetAvailableCount);

  // 一次获取两票（循环内部逐个获取）
  ok := S.TryAcquire(2, 50);
  WriteLn('TryAcquire(2,50ms): ', BoolToStr(ok, '成功', '失败'));

  // 释放到最大
  S.Release(2);
  WriteLn('最终可用计数: ', S.GetAvailableCount, ' / 最大: ', S.GetMaxCount);
  WriteLn('');
end;

begin
  WriteLn('fafafa.core.sync - Semaphore 示例');
  WriteLn('===============================');
  try
    DemoSemaphoreBasic;
    WriteLn('示例结束');
  except
    on E: Exception do
    begin
      WriteLn('发生异常: ', E.ClassName, ' - ', E.Message);
      Halt(1);
    end;
  end;
end.

