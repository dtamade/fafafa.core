program example_thread_cancel_io_batch;
{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  SysUtils, Classes,
  fafafa.core.thread;

type
  PIOCtx = ^TIOCtx;
  TIOCtx = record
    InS, OutS: TStream;
    Token: ICancellationToken;
  end;

function CopyStream(Data: Pointer): Boolean;
var Ctx: PIOCtx; Buf: array[0..8191] of Byte; n: Integer;
begin
  Ctx := PIOCtx(Data);
  repeat
    if IsCancelled(Ctx^.Token) then Exit(False);
    n := Ctx^.InS.Read(Buf, SizeOf(Buf));
    if n<=0 then Break;
    if IsCancelled(Ctx^.Token) then Exit(False);
    Ctx^.OutS.WriteBuffer(Buf, n);
  until False;
  Result := True;
end;

function ProcessBatch(Data: Pointer): Boolean;
var Items: TList; i, batch: Integer; Token: ICancellationToken;
begin
  // Data 传入 Items 指针（简单演示）
  Items := TList(Data);
  Token := nil; // 示例：实际工程中从对象字段/外层闭包注入
  i := 0;
  while i<Items.Count do
  begin
    if IsCancelled(Token) then Exit(False);
    for batch := 1 to 100 do
    begin
      if i>=Items.Count then Break;
      // ... 处理 Items[i] ...
      Inc(i);
    end;
    SysUtils.Sleep(0); // 让权
  end;
  Result := True;
end;

var
  P: IThreadPool;
  Cts: ICancellationTokenSource;
  MemIn, MemOut: TMemoryStream;
  Ctx: TIOCtx;
  Items: TList;
  Threads: Integer;
  FCopy, FBatch: IFuture;
begin
  // 准备上下文
  MemIn := TMemoryStream.Create; MemOut := TMemoryStream.Create; Items := TList.Create;
  try
    // 填充 64KB 演示数据
    MemIn.Size := 64*1024; FillChar(MemIn.Memory^, MemIn.Size, 1);
    MemIn.Position := 0;

    // 线程池与取消源
    Threads := GetCPUCount;
    if Threads<2 then Threads := 2;
    P := CreateFixedThreadPool(Threads);
    Cts := CreateCancellationTokenSource;

    // 组装 IO Ctx 并演示预取消（此处不取消，正常提交）
    Ctx.InS := MemIn; Ctx.OutS := MemOut; Ctx.Token := Cts.Token;
    FCopy := P.Submit(@CopyStream, @Ctx); // 未预取消 → 返回非 nil

    // 提交批处理任务（演示结构）
    FBatch := P.Submit(@ProcessBatch, Cts.Token, Pointer(Items)); // 传入 Items 指针；Token 用于 WaitOrCancel

    // 等待一小段时间再取消
    SysUtils.Sleep(5);
    Cts.Cancel; // 演示进行中取消（协作式）

    // 使用最佳实践等待：完成/取消/超时
    if not FutureWaitOrCancel(FCopy, Cts.Token, 2000) then
      WriteLn('Copy cancelled or timeout');
    if not FutureWaitOrCancel(FBatch, Cts.Token, 2000) then
      WriteLn('Batch cancelled or timeout');

    // 输出结果
    WriteLn('In=', MemIn.Size, ' Out=', MemOut.Size);
  finally
    Items.Free;
    MemIn.Free; MemOut.Free;
    if Assigned(P) then begin P.Shutdown; P.AwaitTermination(3000); end;
  end;
end.

