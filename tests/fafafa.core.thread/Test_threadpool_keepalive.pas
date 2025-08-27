unit Test_threadpool_keepalive;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.thread;

type
  { TTestCase_TThreadPool_KeepAlive }
  TTestCase_TThreadPool_KeepAlive = class(TTestCase)
  published
    procedure Test_KeepAlive_Shrink_Back_To_Core;
  end;

implementation

procedure BusyWork(const AMS: Cardinal);
var
  T0: QWord;
begin
  T0 := GetTickCount64;
  while (GetTickCount64 - T0) < AMS do ;
end;

procedure TTestCase_TThreadPool_KeepAlive.Test_KeepAlive_Shrink_Back_To_Core;
var
  LPool: IThreadPool;
  I: Integer;
  LCore, LMax: Integer;
  LKeep: Cardinal;
  LPoolSize: Integer;
  T0: QWord;
  Window: Cardinal;
  ShrAttempts, ShrImm, ShrTo: Int64;
  M: IThreadPoolMetrics;
begin
  // Core=1, Max=3, keepAlive=200ms
  LCore := 1; LMax := 3; LKeep := 200;
  LPool := TThreads.CreateThreadPool(LCore, LMax, LKeep);

  // 压力：提交一批任务，促使线程数扩张
  for I := 1 to 10 do
    LPool.Submit(function(): Boolean
    begin
      BusyWork(150);
      Result := True;
    end);

  // 等待扩张生效（队列>线程数时会创建新线程，最多到 Max）
  SysUtils.Sleep(250);
  LPoolSize := LPool.PoolSize;
  AssertTrue('pool should expand beyond core', LPoolSize >= 2);

  // 等任务完成，进入空闲，然后等待超过 keepAlive 以回收多余线程
  SysUtils.Sleep(LKeep + 250);
  LPoolSize := LPool.PoolSize;
  AssertEquals('pool should shrink back to core after keepAlive', LCore, LPoolSize);

  // 指标与窗口断言：在 KeepAlive×2 内应回落到 Core（给予合理余量）
  Window := LKeep * 2;
  T0 := GetTickCount64;
  while (GetTickCount64 - T0) <= Window do
  begin
    if LPool.PoolSize = LCore then Break;
    SysUtils.Sleep(10);
  end;
  AssertEquals('pool should shrink to core within window', LCore, LPool.PoolSize);

  // 指标检查（可选）
  M := GetThreadPoolMetrics(LPool);
  if M <> nil then
  begin
    ShrAttempts := M.KeepAliveShrinkAttempts;
    ShrImm := M.KeepAliveShrinkImmediate;
    ShrTo := M.KeepAliveShrinkTimeout;
    AssertTrue('KeepAliveShrinkAttempts>0', ShrAttempts > 0);
    AssertTrue('Shrink success (immediate|timeout)>0', (ShrImm > 0) or (ShrTo > 0));
  end;


  // 优雅关闭
  LPool.Shutdown;
  LPool.AwaitTermination(3000);
end;

initialization
  RegisterTest(TTestCase_TThreadPool_KeepAlive);

end.

