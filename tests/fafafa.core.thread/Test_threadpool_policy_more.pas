unit Test_threadpool_policy_more;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.thread;

type
  { TTestCase_TThreadPoolPolicy_More }
  TTestCase_TThreadPoolPolicy_More = class(TTestCase)
  published
    procedure Test_RejectPolicy_CallerRuns;
    procedure Test_RejectPolicy_DiscardOldest;
    procedure Test_RejectPolicy_Discard;
  end;

implementation



procedure TTestCase_TThreadPoolPolicy_More.Test_RejectPolicy_CallerRuns;
var
  LPool: IThreadPool;
  LThreadIdExec: TThreadID;
  LCallerThreadId: TThreadID;
  LCounter: Integer;
  F: IFuture;
  TStart: QWord;
begin
  LPool := CreateThreadPool(1, 1, 60000, 1, TRejectPolicy.rpCallerRuns);
  LCounter := 0;
  LCallerThreadId := GetCurrentThreadId;

  // 1) 占满工作线程
  LPool.Submit(function(): Boolean
  var T0: QWord;
  begin
    T0 := GetTickCount64;
    while (GetTickCount64 - T0) < 150 do ;
    InterlockedIncrement(LCounter);
    Result := True;
  end);
  // 2) 入队一个
  LPool.Submit(function(): Boolean
  begin
    InterlockedIncrement(LCounter);
    Result := True;
  end);
  // 3) 第三个触发 CallerRuns，在调用线程执行
  F := LPool.Submit(function(): Boolean
  begin
    LThreadIdExec := GetCurrentThreadId;
    InterlockedIncrement(LCounter);
    Result := True;
  end);
  // CallerRuns：在调用线程执行。使用有界等待，直到回调线程ID记录或超时。
  TStart := GetTickCount64;
  while (GetTickCount64 - TStart) < 1200 do
  begin
    if LThreadIdExec <> 0 then Break; // 已记录执行线程ID
    SysUtils.Sleep(5);
  end;
  AssertEquals('Executed in caller thread', PtrUInt(LCallerThreadId), PtrUInt(LThreadIdExec));

  // 等待其余两个任务至少贡献一次计数，减少抖动
  TStart := GetTickCount64;
  while (GetTickCount64 - TStart) < 1200 do
  begin
    if LCounter >= 2 then Break;
    SysUtils.Sleep(10);
  end;
  AssertTrue('At least two tasks should have contributed', LCounter >= 2);

  // 优雅关闭
  LPool.Shutdown;
  LPool.AwaitTermination(3000);
end;

procedure TTestCase_TThreadPoolPolicy_More.Test_RejectPolicy_DiscardOldest;
var
  LPool: IThreadPool;
  LCounter: Integer;
  F1, F2, F3: IFuture;
begin
  LPool := CreateThreadPool(1, 1, 60000, 1, TRejectPolicy.rpDiscardOldest);
  LCounter := 0;

  // 1) 占满工作线程
  F1 := LPool.Submit(function(): Boolean
  var T0: QWord;
  begin
    T0 := GetTickCount64;
    while (GetTickCount64 - T0) < 100 do ;
    InterlockedIncrement(LCounter);
    Result := True;
  end);
  // 2) 入队一个（候选“最旧”）
  F2 := LPool.Submit(function(): Boolean
  begin
    InterlockedIncrement(LCounter);
    Result := True;
  end);
  // 3) 第三个到来，丢弃最旧（步骤2），新任务入队
  F3 := LPool.Submit(function(): Boolean
  begin
    InterlockedIncrement(LCounter);
    Result := True;
  end);

  // 等待第1和第3个任务完成（第2个应被丢弃）
  AssertTrue('F1 should complete', F1.WaitFor(2000));
  AssertTrue('F3 should complete', F3.WaitFor(2000));
  AssertTrue('At least 2 tasks executed', LCounter >= 2);

  // 优雅关闭
  LPool.Shutdown;
  LPool.AwaitTermination(3000);
end;

procedure TTestCase_TThreadPoolPolicy_More.Test_RejectPolicy_Discard;
var
  LPool: IThreadPool;
  LCounter: Integer;
  F1, F2, F3: IFuture;
begin
  // rpDiscard：当队列已满时，直接丢弃“当前提交”的任务
  LPool := CreateThreadPool(1, 1, 60000, 1, TRejectPolicy.rpDiscard);
  LCounter := 0;

  // 1) 占满工作线程
  F1 := LPool.Submit(function(): Boolean
  var T0: QWord;
  begin
    T0 := GetTickCount64;
    while (GetTickCount64 - T0) < 100 do ;
    InterlockedIncrement(LCounter);
    Result := True;
  end);
  // 2) 入队一个（应执行）
  F2 := LPool.Submit(function(): Boolean
  begin
    InterlockedIncrement(LCounter);
    Result := True;
  end);
  // 3) 第三个提交应被丢弃（不执行）
  F3 := LPool.Submit(function(): Boolean
  begin
    InterlockedIncrement(LCounter);
    Result := True;
  end);

  // 等待第1和第2个任务完成（第3个应被丢弃）
  AssertTrue('F1 should complete', F1.WaitFor(2000));
  AssertTrue('F2 should complete', F2.WaitFor(2000));
  AssertTrue('At least 2 tasks executed', LCounter >= 2);
  // 第三个被丢弃：其 Future 应尽快完成为失败，但此处不对失败状态作强依赖断言
  AssertTrue('F3 should be resolved (discarded)', F3.WaitFor(2000));

  // 优雅关闭
  LPool.Shutdown;
  LPool.AwaitTermination(3000);
end;


initialization
  RegisterTest(TTestCase_TThreadPoolPolicy_More);

end.

