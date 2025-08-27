unit Test_example_cancel_io_batch;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testutils, testregistry,
  fafafa.core.thread, fafafa.core.thread.cancel, fafafa.core.thread.future,
  Test_example_tasks_impl;

Type
  TTestCase_ExampleCancelIOBatch = class(TTestCase)
  published
    procedure Test_CooperativeCancel_WaitOrCancelFalse;
  end;

implementation

procedure TTestCase_ExampleCancelIOBatch.Test_CooperativeCancel_WaitOrCancelFalse;
var
  P: IThreadPool;
  Cts: ICancellationTokenSource;
  MemIn, MemOut: TMemoryStream;
  Ctx: TIOCtx;
  FCopy, FBatch: IFuture;
  BatchCount: Integer;
begin
  MemIn := TMemoryStream.Create;
  MemOut := TMemoryStream.Create;
  try
    MemIn.Size := 1024*1024;  // 增大输入以确保取消能在复制完成前发生（避免抢跑）
    FillChar(MemIn.Memory^, MemIn.Size, 1);
    MemIn.Position := 0;
    P := CreateFixedThreadPool(2);
    Cts := CreateCancellationTokenSource;
    Ctx.InS := MemIn; Ctx.OutS := MemOut; Ctx.Token := Cts.Token;
    FCopy := P.Submit(@Task_CopyStream, @Ctx);
    BatchCount := 1000;
    FBatch := P.Submit(@Task_ProcessBatch, Cts.Token, @BatchCount);
    Sleep(5);
    Cts.Cancel;
    // 核心：WaitOrCancel 返回 False 即认为达成（取消或超时）
    AssertTrue('FCopy wait should be False (cancel/timeout)', not FutureWaitOrCancel(FCopy, Cts.Token, 2000));
    AssertTrue('FBatch wait should be False (cancel/timeout)', not FutureWaitOrCancel(FBatch, Cts.Token, 2000));
  finally
    MemIn.Free; MemOut.Free;
    if Assigned(P) then begin P.Shutdown; P.AwaitTermination(3000); end;
  end;
end;

initialization
  RegisterTest(TTestCase_ExampleCancelIOBatch);

end.

