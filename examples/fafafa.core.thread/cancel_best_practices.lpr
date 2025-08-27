program cancel_best_practices;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils, Classes,
  fafafa.core.base,
  fafafa.core.thread;

function BusyStep(Data: Pointer): Boolean;
begin
  // 一个很小的工作单元
  Sleep(5);
  Result := True;
end;

function CancellableTask(Data: Pointer): Boolean;
var
  Token: ICancellationToken;
  I: Integer;
begin
  // 从 Data 中取 Token（演示可将 Token 放在 Data 或 TLS 中，示例直接忽略 Data）
  // 这里取一个全局/静态 Token 的示意，实际项目中可以包装结构体传入
  Token := ICancellationToken(Pointer(PtrUInt(0))); // 示例：未设置 Token

  for I := 1 to 200 do
  begin
    // 周期性检查取消
    if Assigned(Token) and Token.IsCancellationRequested then
    begin
      // 清理并尽快退出
      Exit(False);
    end;
    // 执行小粒度工作单元
    BusyStep(nil);
  end;
  Result := True;
end;

function IOHeavyTask(Data: Pointer): Boolean;
var
  Token: ICancellationToken;
  I: Integer;
begin
  Token := ICancellationToken(Pointer(PtrUInt(0))); // 示例：未设置 Token
  // IO 分段 + 取消点
  for I := 1 to 10 do
  begin
    // I/O 模拟
    Sleep(20);
    if Assigned(Token) and Token.IsCancellationRequested then Exit(False);
  end;
  Result := True;
end;

var
  P: IThreadPool;
  F1, F2: IFuture;
  Src: ICancellationTokenSource;
begin
  Writeln('=== 取消最佳实践示例 ===');
  // 采用 CallerRuns 背压 + 有界队列（例如 2×CPU）
  P := CreateThreadPool(2, 2, 60000, 64, TRejectPolicy.rpCallerRuns);

  // 1) 执行前取消
  Src := CreateCancellationTokenSource;
  F1 := P.Submit(@CancellableTask, Src.Token, nil);
  Src.Cancel; // 立即取消
  if F1 <> nil then
    Writeln('Pre-exec cancel: Wait=', F1.WaitFor(1000), ' Cancelled=', F1.IsCancelled);

  // 2) 等待端的协作取消帮助器
  Src := CreateCancellationTokenSource;
  F2 := P.Submit(@IOHeavyTask, nil);
  Writeln('WaitOrCancel before cancel: ', FutureWaitOrCancel(F2, Src.Token, 200));
  Src.Cancel;
  Writeln('WaitOrCancel after cancel: ', FutureWaitOrCancel(F2, Src.Token, 2000));

  P.Shutdown; P.AwaitTermination(3000);
end.

