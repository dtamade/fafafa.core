unit Test_threadpool_effective_queue_overflow_regression;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.thread;

type
  { TTestCase_TThreadPool_EffectiveQueue_Overflow }
  TTestCase_TThreadPool_EffectiveQueue_Overflow = class(TTestCase)
  published
    procedure Test_Submit_NoIntOverflow_HighConcurrency_WithRangeChecks;
  end;

implementation

procedure __YieldShort;
begin
  // 稍作让步，扩大竞态窗口但不占用 CPU
  Sleep(1);
end;

procedure TTestCase_TThreadPool_EffectiveQueue_Overflow.Test_Submit_NoIntOverflow_HighConcurrency_WithRangeChecks;
const
  Core = 2; MaxThreads = 4; KeepMs = 1000; QueueCap = 8;
var
  P: IThreadPool;
  I: Integer;
  Futures: array of IFuture;
begin
  // 建立小而有竞争的线程池与有限队列（使用 Abort，以便更快触发拒绝分支，但我们会捕获并忽略 EThreadPoolError）
  P := CreateThreadPool(Core, MaxThreads, KeepMs, QueueCap, TRejectPolicy.rpAbort);
  try
    // 占用部分工作线程，剩余产生 Idle 波动
    for I := 1 to Core do
      P.Submit(function(): Boolean
      begin
        Sleep(10);
        Result := True;
      end);

    // 高并发快速提交，历史上此处可能触发有效队列长度计算的溢出或负值误判
    SetLength(Futures, 0);
    for I := 1 to 512 do
    begin
      try
        // 若被拒绝（rpAbort），会抛出 EThreadPoolError；此用例只关注“不溢出/不抛出错误类型”，故忽略该异常
        SetLength(Futures, Length(Futures)+1);
        Futures[High(Futures)] := P.Submit(function(): Boolean
        begin
          __YieldShort;
          Result := True;
        end);
      except
        on E: EThreadPoolError do ; // OK: 可被拒绝
      end;
    end;

    // 等待已接受的任务完成或超时
    if Length(Futures) > 0 then
      Join(Futures, 5000);
    // 未发生整数溢出或异常类型偏差即视为通过
    CheckTrue(True);
  finally
    P.Shutdown;
    P.AwaitTermination(3000);
  end;
end;

initialization
  RegisterTest(TTestCase_TThreadPool_EffectiveQueue_Overflow);

end.

