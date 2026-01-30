unit Test_cancel_more_paths;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testutils, testregistry,
  fafafa.core.thread;

type
  TTestCase_CancelMorePaths = class(TTestCase)
  private
    class function SlowTask(Data: Pointer): Boolean; static;
  published
    procedure Test_PostSubmit_PreExec_Cancel;
    procedure Test_InProgress_Cooperative_Cancel;
  end;

implementation

class function TTestCase_CancelMorePaths.SlowTask(Data: Pointer): Boolean;
var i: Integer;
begin
  // 模拟耗时任务，同时周期性地查询 Token（示例中通过外部 FutureWaitOrCancel 实现）
  for i := 1 to 50 do Sleep(10); // 约 500ms
  Result := True;
end;

procedure TTestCase_CancelMorePaths.Test_PostSubmit_PreExec_Cancel;
var P: IThreadPool; Src: ICancellationTokenSource; F: IFuture;
begin
  P := CreateFixedThreadPool(1);
  Src := CreateCancellationTokenSource;
  F := P.Submit(@SlowTask, Src.Token, nil);
  AssertNotNull(F);
  Src.Cancel; // 执行前尽快取消
  // 等待取消落地（执行前取消由工作线程前置检查）
  Sleep(30);
  F.WaitFor(2000);
  AssertTrue(F.IsCancelled);
end;

procedure TTestCase_CancelMorePaths.Test_InProgress_Cooperative_Cancel;
var P: IThreadPool; Src: ICancellationTokenSource; F: IFuture; ok: Boolean;
begin
  P := CreateFixedThreadPool(1);
  Src := CreateCancellationTokenSource;
  // 这里不传 Token 进任务体，演示外部等待的协作取消帮助器
  F := P.Submit(@SlowTask, nil);
  AssertNotNull(F);
  // 外部等待：若 Token 被请求，等待立刻返回 False
  ok := FutureWaitOrCancel(F, Src.Token, 100);
  AssertFalse('未请求取消，短超时可能返回 False（未完成且未取消）或 True（很快完成）', ok);
  // 请求取消并等待
  Src.Cancel;
  ok := FutureWaitOrCancel(F, Src.Token, 2000);
  AssertTrue('请求取消后，等待应尽快退出（True 表示 Future 完成或因取消视作完成）', ok);
end;

initialization
  RegisterTest(TTestCase_CancelMorePaths);

end.

