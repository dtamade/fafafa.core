unit Test_scheduler_order;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.thread;

type
  TTestCase_TTaskScheduler_Order = class(TTestCase)
  published
    procedure Test_Schedule_Order_ThreeTasks;
  end;

implementation

type
  TOrderRec = record
    Times: array[0..2] of QWord; // t[0]=F1(长延迟), t[1]=F2, t[2]=F3(短延迟)
  end;
  POrderRec = ^TOrderRec;

function MarkIndex(Data: Pointer): Boolean;
begin
  // 直接写入传入地址处的时间戳，避免共享标记顺序带来的歧义
  if Data <> nil then
    PQWord(Data)^ := GetTickCount64;
  Result := True;
end;

procedure TTestCase_TTaskScheduler_Order.Test_Schedule_Order_ThreeTasks;
var
  LScheduler: ITaskScheduler;
  LRec: TOrderRec;
  F1, F2, F3: IFuture;
begin
  LScheduler := CreateTaskScheduler;
  FillChar(LRec, SizeOf(LRec), 0);

  // 让调度器线程就绪，减少计时抖动
  Sleep(2);

  // 三个任务分别延迟 60/120/180ms，并将时间戳写入各自槽位
  F1 := LScheduler.Schedule(@MarkIndex, 180, @LRec.Times[0]);
  F2 := LScheduler.Schedule(@MarkIndex, 120, @LRec.Times[1]);
  F3 := LScheduler.Schedule(@MarkIndex,  60, @LRec.Times[2]);

  AssertTrue(F1.WaitFor(3000));
  AssertTrue(F2.WaitFor(3000));
  AssertTrue(F3.WaitFor(3000));

  // 检查执行顺序（F3 最先，F2 其次，F1 最后）
  // 允许 5ms 容差以降低 TickCount 抖动影响
  AssertTrue('F3 should be first', (LRec.Times[2] <= LRec.Times[1] + 5) and (LRec.Times[2] <= LRec.Times[0] + 5));
  AssertTrue('F2 should be second', (LRec.Times[1] <= LRec.Times[0] + 5));

  LScheduler.Shutdown;
end;

initialization
  RegisterTest(TTestCase_TTaskScheduler_Order);

end.

