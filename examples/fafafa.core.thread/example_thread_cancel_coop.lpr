program example_thread_cancel_coop;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.thread;

function Process(Data: Pointer): Boolean;
var i, n: Integer; Token: ICancellationToken;
begin
  n := NativeInt(Data);
  // 模拟一个可分批的长任务；每 100 步检查一次取消并让权
  for i := 1 to n do
  begin
    if (i mod 100) = 0 then
    begin
      // 这里假设从某处可获取 Token；演示用 Sleep 模拟片段
      SysUtils.Sleep(0);
    end;
  end;
  Result := True;
end;

var P: IThreadPool; Cts: ICancellationTokenSource; F: IFuture; ok: Boolean;
begin
  P := CreateFixedThreadPool(2);
  Cts := CreateCancellationTokenSource;
  try
    // 协作式取消的关键：
    // - 提交时传入 Token（若预取消将返回 nil）
    // - 运行中任务应定期检查 IsCancelled(Token) 并尽早返回
    F := P.Submit(@Process, Cts.Token, Pointer(5000));
    if F = nil then
    begin
      Writeln('Pre-cancelled: task not submitted');
      Halt(0);
    end;
    // 50ms 后用户取消
    SysUtils.Sleep(50);
    Cts.Cancel;
    ok := FutureWaitOrCancel(F, Cts.Token, 3000);
    Writeln('waitOrCancel ok? ', ok);
  finally
    P.Shutdown; P.AwaitTermination(2000);
  end;
end.

