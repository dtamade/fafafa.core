program example_thread_wait_or_cancel;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.thread;

// 一个简单任务：睡眠指定毫秒后完成
function Work(Data: Pointer): Boolean;
begin
  Sleep(NativeUInt(Data));
  Result := True;
end;

var
  F_ok, F_cancel, F_timeout: IFuture;
  Cts: ICancellationTokenSource;
  ok1, ok2, ok3: Boolean;
begin
  // 场景1：正常完成（无 Token / 1s 超时足够）
  F_ok := Spawn(@Work, Pointer(100));
  ok1 := FutureWaitOrCancel(F_ok, nil, 1000);
  Writeln('{"ok_normal":', LowerCase(BoolToStr(ok1, True)), '}');

  // 场景2：取消优先（传入 Token，先取消再等待）
  Cts := CreateCancellationTokenSource;
  try
    // 为了演示，任务本身耗时较长
    F_cancel := TThreads.Spawn(@Work, Pointer(5000), Cts.Token);
    // 50ms 之后用户取消
    SysUtils.Sleep(50);
    Cts.Cancel;
    // 等待：若任务未完成且已取消，应尽快返回 False
    ok2 := FutureWaitOrCancel(F_cancel, Cts.Token, 3000);
    Writeln('{"ok_cancel":', LowerCase(BoolToStr(ok2, True)), '}');
  finally
    Cts := nil;
  end;

  // 场景3：超时（无 Token；100ms 等待不够）
  F_timeout := Spawn(@Work, Pointer(500));
  ok3 := FutureWaitOrCancel(F_timeout, nil, 100);
  Writeln('{"ok_timeout":', LowerCase(BoolToStr(ok3, True)), '}');
end.

