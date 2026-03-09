unit Test_threadpool_reject_metrics;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.thread;

type
  { TTestCase_TThreadPool_RejectMetrics }
  TTestCase_TThreadPool_RejectMetrics = class(TTestCase)
  published
    procedure Test_Abort_Increments_Rejected;
    procedure Test_CallerRuns_Not_In_TotalRejected;
  end;

implementation

procedure BusyWork(const AMS: Cardinal);
var T0: QWord; begin T0 := GetTickCount64; while (GetTickCount64 - T0) < AMS do ; end;

procedure TTestCase_TThreadPool_RejectMetrics.Test_Abort_Increments_Rejected;
var P: IThreadPool; thrown: Boolean; M: IThreadPoolMetrics; i: Integer;
begin
  // Core=1, Max=1, queue=1, policy=Abort => 第三次提交应抛异常（第2次入队），并计入 RejectedAbort/TotalRejected
  P := TThreads.CreateThreadPool(1, 1, 60000, 1, TRejectPolicy.rpAbort);
  thrown := False;
  P.Submit(function(): Boolean begin BusyWork(200); Result := True; end);
  // 等待工作线程开始执行，避免首个提交因尚未有工作线程而被误判为满
  for i := 1 to 40 do begin
    if P.GetActiveCount > 0 then Break;
    Sleep(5);
  end;
  // 第二次提交将进入队列（容量=1）
  P.Submit(function(): Boolean begin Result := True; end);
  // 第三次提交应被拒绝
  try
    P.Submit(function(): Boolean begin Result := True; end);
  except
    on E: EThreadPoolError do thrown := True;
  end;
  AssertTrue('second submit should throw under rpAbort', thrown);
  M := GetThreadPoolMetrics(P);
  if M <> nil then begin
    AssertTrue('RejectedAbort>0', M.RejectedAbort > 0);
    AssertTrue('TotalRejected>0', M.TotalRejected > 0);
  end;
  P.Shutdown; P.AwaitTermination(3000);
end;

procedure TTestCase_TThreadPool_RejectMetrics.Test_CallerRuns_Not_In_TotalRejected;
var P: IThreadPool; M: IThreadPoolMetrics; i: Integer;
begin
  // Core=1, Max=1, queue=0, policy=CallerRuns => 第二次提交在调用线程执行，不计入 TotalRejected
  P := TThreads.CreateThreadPool(1, 1, 60000, 0, TRejectPolicy.rpCallerRuns);
  P.Submit(function(): Boolean begin BusyWork(50); Result := True; end);
  // 等待工作线程进入执行态，避免 ActiveCount 采样窗口导致第二次提交误走入队路径
  for i := 1 to 40 do begin
    if P.GetActiveCount > 0 then Break;
    Sleep(5);
  end;
  P.Submit(function(): Boolean begin BusyWork(1); Result := True; end);
  M := GetThreadPoolMetrics(P);
  if M <> nil then begin
    AssertTrue('RejectedCallerRuns>0', M.RejectedCallerRuns > 0);
    AssertTrue('TotalRejected should be 0 for pure CallerRuns path', M.TotalRejected = 0);
  end;
  P.Shutdown; P.AwaitTermination(3000);
end;

initialization
  RegisterTest(TTestCase_TThreadPool_RejectMetrics);
end.

