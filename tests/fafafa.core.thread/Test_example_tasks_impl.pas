unit Test_example_tasks_impl;

{$mode objfpc}{$H+}

interface

uses Classes, SysUtils, fafafa.core.thread;

// 供测试使用的最小任务实现（拷贝/批处理），与示例一致但去掉 UI/IO 依赖

type
  PIOCtx = ^TIOCtx;
  TIOCtx = record
    InS, OutS: TStream;
    Token: ICancellationToken;
  end;

function Task_CopyStream(Data: Pointer): Boolean;
function Task_ProcessBatch(Data: Pointer): Boolean;

implementation

function Task_CopyStream(Data: Pointer): Boolean;
var Ctx: PIOCtx; Buf: array[0..4095] of Byte; n: Integer;
begin
  Ctx := PIOCtx(Data);
  repeat
    if IsCancelled(Ctx^.Token) then Exit(False);
    n := Ctx^.InS.Read(Buf, SizeOf(Buf));
    if n<=0 then Break;
    if IsCancelled(Ctx^.Token) then Exit(False);
    Ctx^.OutS.WriteBuffer(Buf, n);
    // 小幅放慢以确保测试中的 Cancel 先于完成发生
    SysUtils.Sleep(1);
  until False;
  Result := True;
end;

function Task_ProcessBatch(Data: Pointer): Boolean;
var i, batch: Integer; Token: ICancellationToken; Count: ^Integer;
begin
  // Data 传入计数指针，模拟批处理迭代
  Count := Data;
  Token := nil; // 故意设置为 nil，以模拟无 Token 情形（测试批处理取消由 Sleep/外层 Token 控制）
  i := 0;
  while i<Count^ do
  begin
    if IsCancelled(Token) then Exit(False);
    for batch := 1 to 64 do
    begin
      if i>=Count^ then Break;
      Inc(i);
    end;
    // 轻微放缓，确保取消先发生
    SysUtils.Sleep(1);
  end;
  Result := True;
end;

end.

