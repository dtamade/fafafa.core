program example_thread_select_best_practices;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.thread;

function Work(Data: Pointer): Boolean;
begin
  SysUtils.Sleep(NativeUInt(Data));
  Result := True;
end;

var
  F1,F2: IFuture;
  Idx: Integer;
  Pool: IThreadPool;
  Cts: ICancellationTokenSource;
begin
  WriteLn('example_thread_select_best_practices');
  // 背压：固定线程池 + 有界队列 + CallerRuns
  Pool := CreateThreadPool(GetCPUCount, GetCPUCount, 60000, GetCPUCount*2, TRejectPolicy.rpCallerRuns);
  try
    // 取消：预取消 -> 任务不会提交
    Cts := CreateCancellationTokenSource;
    Cts.Cancel;
    if Spawn(@Work, Pointer(10), Cts.Token) = nil then
      WriteLn('spawn cancelled as expected');

    // 明确区分先后：F1慢(150ms)，F2快(20ms)
    F1 := Pool.Submit(@Work, Pointer(150));
    F2 := Pool.Submit(@Work, Pointer(20));
    Idx := Select([F1, F2], 2000);
    WriteLn('Select result index=', Idx);

    // Join：等待全部
    if Join([F1, F2], 2000) then
      WriteLn('Join ok')
    else
      WriteLn('Join timeout');
  finally
    Pool.Shutdown;
    Pool.AwaitTermination(3000);
  end;
end.

