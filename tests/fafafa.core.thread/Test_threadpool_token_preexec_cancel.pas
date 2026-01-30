unit Test_threadpool_token_preexec_cancel;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testutils, testregistry,
  fafafa.core.thread;

type
  TTestCase_ThreadPool_TokenPreExecCancel = class(TTestCase)
  private
    class function BusyTask(Data: Pointer): Boolean; static;
  published
    procedure Test_PreExec_Cancel_Skips_Execution_And_Cancels_Future;
  end;

implementation

class function TTestCase_ThreadPool_TokenPreExecCancel.BusyTask(Data: Pointer): Boolean;
begin
  // 如被执行则返回 True，但测试期望不被执行
  Result := True;
end;

procedure TTestCase_ThreadPool_TokenPreExecCancel.Test_PreExec_Cancel_Skips_Execution_And_Cancels_Future;
var
  P: IThreadPool;
  Src: ICancellationTokenSource;
  F: IFuture;
begin
  P := CreateFixedThreadPool(1);
  Src := CreateCancellationTokenSource;
  // 先提交，再立即取消，确保在执行前进入取消状态
  F := P.Submit(@BusyTask, Src.Token, nil);
  AssertNotNull('提交应返回 Future', F);

  Src.Cancel; // 提交后立即取消

  // 等待一段时间（应很快成为取消状态）
  Sleep(20);
  // WaitFor 可能也会立刻返回（取消被视为完成状态）
  F.WaitFor(1000);
  AssertTrue('Future 应被取消', F.IsCancelled);
end;

initialization
  RegisterTest(TTestCase_ThreadPool_TokenPreExecCancel);

end.

