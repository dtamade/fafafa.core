unit Test_threadpool_effective_queue_boundary;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.thread;

type
  TTestCase_TThreadPool_EffectiveQueue = class(TTestCase)
  published
    // 验证修复：当空闲工作线程>0时，有效队列长度不出现算术下溢，不触发 EIntOverflow
    // 复现思路：队列容量设为1，先不提交任务，直接提交一次，随后立即再提交第二次，
    // 在第一条尚未被工作线程领取前，LEffectiveQueue = LQueueLen - LIdleWorkers 可能为 0 或负，需被 clamp 为 0。
    // 任何情况下都不应抛出算术溢出异常。
    procedure Test_Submit_NoOverflow_WithIdleWorkers;
  end;

implementation

procedure TTestCase_TThreadPool_EffectiveQueue.Test_Submit_NoOverflow_WithIdleWorkers;
var
  Pool: IThreadPool;
  Done1, Done2: Boolean;
begin
  Pool := CreateThreadPool(1, 1, 60000, 1, TRejectPolicy.rpAbort);
  try
    Done1 := False; Done2 := False;
    // 第一个任务：很快完成，制造一个短暂窗口：提交-领取之间的竞态
    Pool.Submit(function(): Boolean
    begin
      Done1 := True;
      Result := True;
    end);
    // 紧接着提交第二个任务：在修复之前，可能触发 LQueueLen(=1) - LIdleWorkers(=1) 的并发读写窗口下溢问题
    Pool.Submit(function(): Boolean
    begin
      Done2 := True;
      Result := True;
    end);

    // 等待片刻让两任务都能被执行
    Sleep(50);
    AssertTrue('first task completed', Done1);
    AssertTrue('second task completed', Done2);
  finally
    if Assigned(Pool) then begin Pool.Shutdown; Pool.AwaitTermination(2000); end;
  end;
end;

initialization
  RegisterTest(TTestCase_TThreadPool_EffectiveQueue);

end.

