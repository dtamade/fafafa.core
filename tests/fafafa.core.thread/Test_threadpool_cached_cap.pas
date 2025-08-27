unit Test_threadpool_cached_cap;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.thread;

type
  { TTestCase_TThreadPool_CachedCap }
  TTestCase_TThreadPool_CachedCap = class(TTestCase)
  published
    procedure Test_Cached_Max_Capped_By_CPU;
  end;

implementation

procedure BusyWork(const AMS: Cardinal);
var T0: QWord; begin T0 := GetTickCount64; while (GetTickCount64 - T0) < AMS do ; end;

procedure TTestCase_TThreadPool_CachedCap.Test_Cached_Max_Capped_By_CPU;
var
  P: IThreadPool; M: IThreadPoolMetrics; i: Integer;
  ExpectedCap, CPU: Integer;
begin
  CPU := GetCPUCount;
  ExpectedCap := CPU * 4; if ExpectedCap < 8 then ExpectedCap := 8; if ExpectedCap > 64 then ExpectedCap := 64;
  P := CreateCachedThreadPool;
  // 尝试制造扩张：提交比上限多的任务
  for i := 1 to (ExpectedCap + 16) do
    P.Submit(function(): Boolean begin BusyWork(100); Result := True; end);
  // 等待扩张生效
  SysUtils.Sleep(150);
  // PoolSize 不应超过上限（允许少量启动延迟，容忍 <= ExpectedCap）
  AssertTrue('pool size should be <= capped max', P.PoolSize <= ExpectedCap);
  // 指标可用时，TotalSubmitted 应 >= 提交数量
  M := GetThreadPoolMetrics(P);
  if M <> nil then AssertTrue('submitted>=count', M.TotalSubmitted >= (ExpectedCap + 16));
  P.Shutdown; P.AwaitTermination(3000);
end;

initialization
  RegisterTest(TTestCase_TThreadPool_CachedCap);
end.

