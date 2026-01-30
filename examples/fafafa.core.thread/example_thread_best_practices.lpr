program example_thread_best_practices;
{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  SysUtils,
  fafafa.core.thread;

function Work(Data: Pointer): Boolean;
var
  N: PtrInt;
begin
  // 模拟计算/短IO任务
  N := PtrInt(Data);
  Sleep(50 + (N mod 50));
  Result := True;
end;

function MetricsToJSON(const M: IThreadPoolMetrics): string;
begin
  if M=nil then Exit('{}');
  Result := Format('{"active":%d,"pool":%d,"queue":%d,"submitted":%d,"completed":%d,"rejected":%d}',
                   [M.ActiveCount, M.PoolSize, M.QueueSize, M.TotalSubmitted, M.TotalCompleted, M.TotalRejected]);
end;


function OnDone: Boolean;
begin
  WriteLn('Task done at ', GetTickCount64, ' ms');
  Result := True;
end;

var
  Pool: IThreadPool;
  F1, F2, F3: IFuture;
begin
  try
    // 按最佳实践：有界队列 + CallerRuns（自然背压），线程数≈CPU数，Max≈2×CPU
    Pool := CreateThreadPool(
      GetCPUCount,         // Core
      GetCPUCount*2,       // Max
      60000,               // KeepAliveMs
      GetCPUCount*2,       // QueueCapacity（有界队列）
      TRejectPolicy.rpCallerRuns
    );

    // 提交 3 个任务（演示函数/回调）
    F1 := Pool.Submit(@Work, Pointer(1));
    F2 := Pool.Submit(@Work, Pointer(2));
    F3 := Pool.Submit(@Work, Pointer(3));

    // 已完成时注册 OnComplete 也会立即调用一次；回调应短小
    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    F1.OnComplete(@OnDone);
    {$ENDIF}

    // 等待全部完成（总超时 5 秒）
    if not Join([F1, F2, F3], 5000) then
      WriteLn('Join timeout');

    // 输出 JSON 指标，便于前端联调
    WriteLn(MetricsToJSON(Pool.GetMetrics));

    // 关闭线程池并等待收尾
    Pool.Shutdown;
    Pool.AwaitTermination(3000);
  except
    on E: Exception do
      Writeln('Error: ', E.ClassName, ': ', E.Message);
  end;
end.

