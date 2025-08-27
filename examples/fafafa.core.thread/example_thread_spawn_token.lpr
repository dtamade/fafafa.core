program example_thread_spawn_token;
{$mode objfpc}{$H+}
{$apptype console}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  SysUtils,
  fafafa.core.thread;

// 示例：使用 TThreads.Spawn 带 ICancellationToken 的重载提交任务，演示协作式取消
// 步骤：
// 1) 创建 CancellationTokenSource
// 2) 提交若干任务，部分在运行中检查 Token 并提前返回
// 3) 触发 Cancel，并等待任务结束

function WorkFunc(Data: Pointer): Boolean;
type
  PICancellationToken = ^ICancellationToken;
var i: Integer; Token: ICancellationToken;
begin
  Result := False;
  Token := PICancellationToken(Data)^;
  for i := 1 to 1000 do
  begin
    // 模拟工作
    Sleep(1);
    // 协作式取消：主动检查 Token
    if Assigned(Token) and Token.IsCancellationRequested then
    begin
      WriteLn('[worker] cancelled at i=', i);
      Exit(False);
    end;
  end;
  WriteLn('[worker] completed');
  Result := True;
end;

var
  Cts: ICancellationTokenSource;
  F1, F2: IFuture;
  TokenPtr: ^ICancellationToken;
begin
  New(TokenPtr);
  try
    Cts := CreateCancellationTokenSource;
    TokenPtr^ := Cts.Token;

    // 通过 TThreads.Spawn 带 Token 的重载提交（函数型回调要求返回 Boolean）
    F1 := TThreads.Spawn(@WorkFunc, TokenPtr, Cts.Token);
    F2 := TThreads.Spawn(@WorkFunc, TokenPtr, Cts.Token);

    // 让任务跑一会儿
    Sleep(50);
    // 触发取消
    Cts.Cancel;

    // 等待任务结束（带超时）
    if Assigned(F1) then F1.WaitFor(1000);
    if Assigned(F2) then F2.WaitFor(1000);

    WriteLn('Done. cancelled=', Cts.Token.IsCancellationRequested);
  finally
    // 释放前清空接口，避免引用计数悬挂
    if Assigned(TokenPtr) then TokenPtr^ := nil;
    Dispose(TokenPtr);
  end;
end.

