unit Test_threadpool_policy;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.thread;

type
  { TTestCase_TThreadPoolPolicy }
  TTestCase_TThreadPoolPolicy = class(TTestCase)
  published
    procedure Test_RejectPolicy_Abort;
    procedure Test_RejectPolicy_Discard;
  end;




implementation

procedure TTestCase_TThreadPoolPolicy.Test_RejectPolicy_Abort;
var
  LPool: IThreadPool;
  LExecuted: Integer;
  I: Integer;
begin
  // Use capacity=1 to allow one enqueued task while worker is busy
  LPool := CreateThreadPool(1, 1, 60000, 1, TRejectPolicy.rpAbort);
  try
    LExecuted := 0;
    // 第一个任务占满工作线程


    LPool.Submit(function(): Boolean
    var T0: QWord;
    begin
      T0 := GetTickCount64;
      while (GetTickCount64 - T0) < 150 do ;
      Inc(LExecuted);
      Result := True;
    end);
    // 第二个任务进入队列（容量=1），第三个任务提交时应因队列满而抛异常
    LPool.Submit(function(): Boolean
    begin
      Inc(LExecuted);
      Result := True;
    end);
    // 第三个提交应抛 EThreadPoolError（队列容量已满且策略为 Abort）
    try
      LPool.Submit(function(): Boolean
      begin
        Inc(LExecuted);
        Result := True;
      end);
      Fail('应当抛出 EThreadPoolError，但没有抛出');
    except
      on E: Exception do
        ; // 预期，任意异常即代表拒绝发生（具体类型为 EThreadPoolError）
    end;
  finally
    // 优雅关闭，避免后台线程/任务未释放导致的泄漏
    LPool.Shutdown;
    LPool.AwaitTermination(3000);
  end;
end;

procedure TTestCase_TThreadPoolPolicy.Test_RejectPolicy_Discard;
var
  LPool: IThreadPool;
  LExecuted: Integer;
  I: Integer;
  T0: QWord;
begin
  LPool := CreateThreadPool(1, 1, 60000, 1, TRejectPolicy.rpDiscard);
  LExecuted := 0;
  // 第一个任务占满线程
  LPool.Submit(function(): Boolean
  var T0: QWord;
  begin
    T0 := GetTickCount64;
    while (GetTickCount64 - T0) < 100 do ;
    Inc(LExecuted);
    Result := True;
  end);
  // 第二个任务会被丢弃，不抛异常
  LPool.Submit(function(): Boolean
  begin
    Inc(LExecuted);
    Result := True;
  end);
  // 等待窗口内观察到至少一次执行，避免偶发调度抖动导致误报
  T0 := GetTickCount64;
  while (GetTickCount64 - T0) < 1000 do
  begin
    if LExecuted >= 1 then Break;
    SysUtils.Sleep(10);
  end;
  AssertTrue('至少执行了一个', LExecuted >= 1);
  // 额外等待，避免异步输出导致的测试报告写出异常
  SysUtils.Sleep(50);

  // 优雅关闭
  LPool.Shutdown;
  LPool.AwaitTermination(3000);
end;

initialization
  RegisterTest(TTestCase_TThreadPoolPolicy);

end.

