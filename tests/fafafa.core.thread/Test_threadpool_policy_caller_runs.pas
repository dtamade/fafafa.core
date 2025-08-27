unit Test_threadpool_policy_caller_runs;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.thread;

type
  { TTestCase_TThreadPoolPolicy_CallerRuns }
  TTestCase_TThreadPoolPolicy_CallerRuns = class(TTestCase)
  published
    procedure Test_RejectPolicy_CallerRuns_Backpressure;
  end;

implementation

procedure Busy(const ms: Cardinal);
var t0: QWord; begin t0 := GetTickCount64; while (GetTickCount64 - t0) < ms do ; end;

procedure TTestCase_TThreadPoolPolicy_CallerRuns.Test_RejectPolicy_CallerRuns_Backpressure;
var
  P: IThreadPool;
  ExecOnCaller: Integer;
  i: Integer;
  T0: QWord;
begin
  ExecOnCaller := 0;
  // 1 worker + queue capacity 1: 第三个提交将触发 CallerRuns 在调用线程执行
  P := CreateThreadPool(1, 1, 60000, 1, TRejectPolicy.rpCallerRuns);
  try
    // 第一个任务占满 worker
    P.Submit(function(): Boolean begin Busy(150); Result := True; end);
    // 第二个任务进入队列
    P.Submit(function(): Boolean begin Result := True; end);
    // 第三个任务在队列满时触发 CallerRuns：我们用明显的 CPU 忙等来观察阻塞
    T0 := GetTickCount64;
    P.Submit(function(): Boolean
    begin
      Busy(50);
      Inc(ExecOnCaller);
      Result := True;
    end);
    // 如果触发了 CallerRuns，这里提交调用将被同步阻塞 ~50ms
    AssertTrue('CallerRuns 应造成调用方至少阻塞 40ms', (GetTickCount64 - T0) >= 40);

    // 等待窗口内至少有一个执行完成
    i := 0;
    while (i < 30) and (ExecOnCaller = 0) do begin SysUtils.Sleep(10); Inc(i); end;
    AssertTrue('CallerRuns 任务应在调用方执行', ExecOnCaller >= 1);
  finally
    P.Shutdown; P.AwaitTermination(1000);
  end;
end;

initialization
  RegisterTest(TTestCase_TThreadPoolPolicy_CallerRuns);
end.

