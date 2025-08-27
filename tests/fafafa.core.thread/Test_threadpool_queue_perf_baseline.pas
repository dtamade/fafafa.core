unit Test_threadpool_queue_perf_baseline;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testutils, testregistry,
  fafafa.core.thread;

type
  TTestCase_ThreadPool_QueuePerf = class(TTestCase)
  published
    procedure Test_Submit_And_Wait_Many_Short_Tasks;
  end;

implementation

procedure TTestCase_ThreadPool_QueuePerf.Test_Submit_And_Wait_Many_Short_Tasks;
const
  N = 5000;
var
  P: IThreadPool;
  I: Integer;
  F: IFuture;
begin
  // 小型线程池 + 短任务，主要覆盖队列的进出性能路径
  P := CreateThreadPool(2, 4, 1000);
  try
    for I := 1 to N do
    begin
      F := P.Submit(function(Data: Pointer): Boolean
      begin
        // 极短任务，尽量触发频繁入队/出队
        Result := True;
      end);
      AssertTrue('每个 Future 应在合理时间内完成', F.WaitFor(5000));
    end;
  finally
    P.Shutdown;
    P.AwaitTermination(3000);
  end;
end;

initialization
  RegisterTest(TTestCase_ThreadPool_QueuePerf);

end.

