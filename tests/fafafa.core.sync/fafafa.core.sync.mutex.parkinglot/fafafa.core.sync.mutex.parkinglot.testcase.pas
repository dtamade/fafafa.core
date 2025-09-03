unit fafafa.core.sync.mutex.parkinglot.testcase;

{
──────────────────────────────────────────────────────────────
   ______   ______     ______   ______     ______   ______
  /\  ___\ /\  __ \   /\  ___\ /\  __ \   /\  ___\ /\  __ \
  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \
   \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\
    \/_/     \/_/\/_/   \/_/     \/_/\/_/   \/_/     \/_/\/_/
                          Studio
──────────────────────────────────────────────────────────────
📦 项目：fafafa.core.sync.mutex.parkinglot - 单元测试用例
📖 概述：Parking Lot Mutex 的完整单元测试套件
🧵 测试覆盖：全部公开接口的显式测试
──────────────────────────────────────────────────────────────
}

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../../src/fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testutils, testregistry,
  fafafa.core.sync.mutex.parkinglot,
  fafafa.core.thread,
  fafafa.core.time.tick;

type
  { 全局函数测试 }
  TTestCase_Global = class(TTestCase)
  published
    procedure Test_MakeParkingLotMutex;
  end;

  { TParkingLotMutexBase 类测试 }
  TTestCase_TParkingLotMutexBase = class(TTestCase)
  private
    FMutex: IParkingLotMutex;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    // 基础接口测试
    procedure Test_Create;
    procedure Test_Acquire;
    procedure Test_Release;
    procedure Test_ReleaseFair;
    procedure Test_TryAcquire;
    procedure Test_TryAcquire_Timeout;
    procedure Test_GetHandle;
    
    // 组合操作测试
    procedure Test_Acquire_Release_Cycle;
    procedure Test_TryAcquire_Multiple;
    procedure Test_Timeout_Behavior;
    procedure Test_Fair_Release_Behavior;
  end;

  { 并发安全测试 }
  TTestCase_Concurrency = class(TTestCase)
  private
    FMutex: IParkingLotMutex;
    FSharedCounter: Integer;
    FThreadCount: Integer;
    FIterationsPerThread: Integer;
    procedure ThreadWorker;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure Test_Concurrent_Access;
    procedure Test_High_Contention;
    procedure Test_Fair_Unfair_Mix;
  end;

implementation

{ TTestCase_Global }

procedure TTestCase_Global.Test_MakeParkingLotMutex;
var
  Mutex: IParkingLotMutex;
begin
  // 测试全局函数 MakeParkingLotMutex
  Mutex := MakeParkingLotMutex;
  AssertNotNull('MakeParkingLotMutex should return valid interface', Mutex);
  
  // 验证返回的接口可用
  AssertTrue('Created mutex should be acquirable', Mutex.TryAcquire);
  Mutex.Release;
end;

{ TTestCase_TParkingLotMutexBase }

procedure TTestCase_TParkingLotMutexBase.SetUp;
begin
  inherited SetUp;
  FMutex := MakeParkingLotMutex;
end;

procedure TTestCase_TParkingLotMutexBase.TearDown;
begin
  FMutex := nil;
  inherited TearDown;
end;

procedure TTestCase_TParkingLotMutexBase.Test_Create;
begin
  // 测试对象创建
  AssertNotNull('Mutex should be created successfully', FMutex);
end;

procedure TTestCase_TParkingLotMutexBase.Test_Acquire;
begin
  // 测试 Acquire 方法
  FMutex.Acquire;
  
  // 验证锁已被获取（通过 TryAcquire 失败来验证）
  AssertFalse('Mutex should be locked after Acquire', FMutex.TryAcquire);
  
  FMutex.Release;
end;

procedure TTestCase_TParkingLotMutexBase.Test_Release;
begin
  // 测试 Release 方法
  FMutex.Acquire;
  FMutex.Release;
  
  // 验证锁已被释放
  AssertTrue('Mutex should be unlocked after Release', FMutex.TryAcquire);
  FMutex.Release;
end;

procedure TTestCase_TParkingLotMutexBase.Test_ReleaseFair;
begin
  // 测试 ReleaseFair 方法
  FMutex.Acquire;
  FMutex.ReleaseFair;
  
  // 验证锁已被释放
  AssertTrue('Mutex should be unlocked after ReleaseFair', FMutex.TryAcquire);
  FMutex.Release;
end;

procedure TTestCase_TParkingLotMutexBase.Test_TryAcquire;
begin
  // 测试 TryAcquire 方法（无参数版本）
  AssertTrue('TryAcquire should succeed on unlocked mutex', FMutex.TryAcquire);
  AssertFalse('TryAcquire should fail on locked mutex', FMutex.TryAcquire);
  FMutex.Release;
end;

procedure TTestCase_TParkingLotMutexBase.Test_TryAcquire_Timeout;
var
  StartTime, EndTime: QWord;
begin
  // 测试 TryAcquire 方法（带超时参数版本）
  
  // 测试无竞争情况
  AssertTrue('TryAcquire with timeout should succeed immediately', 
             FMutex.TryAcquire(1000));
  
  // 测试超时情况
  StartTime := GetTickCount64;
  AssertFalse('TryAcquire with timeout should fail when locked', 
              FMutex.TryAcquire(100));
  EndTime := GetTickCount64;
  
  // 验证确实等待了指定时间
  AssertTrue('Should wait approximately the timeout duration', 
             (EndTime - StartTime) >= 90);
  AssertTrue('Should not wait much longer than timeout', 
             (EndTime - StartTime) <= 200);
  
  FMutex.Release;
end;

procedure TTestCase_TParkingLotMutexBase.Test_GetHandle;
var
  Handle: Pointer;
begin
  // 测试 GetHandle 方法
  Handle := FMutex.GetHandle;
  AssertNotNull('GetHandle should return non-null pointer', Handle);
end;

procedure TTestCase_TParkingLotMutexBase.Test_Acquire_Release_Cycle;
var
  i: Integer;
begin
  // 测试多次获取-释放循环
  for i := 1 to 100 do
  begin
    FMutex.Acquire;
    try
      // 模拟一些工作
      if i mod 10 = 0 then
        Sleep(1);
    finally
      FMutex.Release;
    end;
  end;
  
  // 最后应该能够成功获取锁
  AssertTrue('Should be able to acquire after multiple cycles', 
             FMutex.TryAcquire);
  FMutex.Release;
end;

procedure TTestCase_TParkingLotMutexBase.Test_TryAcquire_Multiple;
begin
  // 测试多次 TryAcquire 调用
  AssertTrue('First TryAcquire should succeed', FMutex.TryAcquire);
  AssertFalse('Second TryAcquire should fail', FMutex.TryAcquire);
  AssertFalse('Third TryAcquire should fail', FMutex.TryAcquire);
  
  FMutex.Release;
  
  AssertTrue('TryAcquire after release should succeed', FMutex.TryAcquire);
  FMutex.Release;
end;

procedure TTestCase_TParkingLotMutexBase.Test_Timeout_Behavior;
begin
  // 测试各种超时值
  AssertTrue('Zero timeout should succeed when unlocked', 
             FMutex.TryAcquire(0));
  
  AssertFalse('Zero timeout should fail when locked', 
              FMutex.TryAcquire(0));
  
  FMutex.Release;
  
  // 测试很长的超时（但实际立即成功）
  var StartTime := GetTickCount64;
  AssertTrue('Long timeout should succeed immediately when unlocked', 
             FMutex.TryAcquire(60000));
  var EndTime := GetTickCount64;
  
  AssertTrue('Should return immediately when unlocked', 
             (EndTime - StartTime) < 100);
  
  FMutex.Release;
end;

procedure TTestCase_TParkingLotMutexBase.Test_Fair_Release_Behavior;
begin
  // 测试公平释放和普通释放的基本行为
  FMutex.Acquire;
  FMutex.Release; // 普通释放
  
  AssertTrue('Should be able to acquire after normal release', 
             FMutex.TryAcquire);
  FMutex.ReleaseFair; // 公平释放
  
  AssertTrue('Should be able to acquire after fair release',
             FMutex.TryAcquire);
  FMutex.Release;
end;

{ TTestCase_Concurrency }

procedure TTestCase_Concurrency.SetUp;
begin
  inherited SetUp;
  FMutex := MakeParkingLotMutex;
  FSharedCounter := 0;
  FThreadCount := 4;
  FIterationsPerThread := 100;
end;

procedure TTestCase_Concurrency.TearDown;
begin
  FMutex := nil;
  inherited TearDown;
end;

procedure TTestCase_Concurrency.ThreadWorker;
var
  i: Integer;
  LocalCounter: Integer;
begin
  for i := 1 to FIterationsPerThread do
  begin
    FMutex.Acquire;
    try
      // 读取-修改-写入操作（需要原子性保护）
      LocalCounter := FSharedCounter;
      Sleep(0); // 让出时间片，增加竞争
      FSharedCounter := LocalCounter + 1;
    finally
      FMutex.Release;
    end;
  end;
end;

procedure TTestCase_Concurrency.Test_Concurrent_Access;
var
  Threads: array of TThread;
  i: Integer;
  ExpectedValue: Integer;
begin
  SetLength(Threads, FThreadCount);

  // 创建并启动线程
  for i := 0 to FThreadCount - 1 do
  begin
    Threads[i] := TThread.CreateAnonymousThread(@ThreadWorker);
    Threads[i].Start;
  end;

  // 等待所有线程完成
  for i := 0 to FThreadCount - 1 do
  begin
    Threads[i].WaitFor;
    Threads[i].Free;
  end;

  // 验证结果
  ExpectedValue := FThreadCount * FIterationsPerThread;
  AssertEquals('Shared counter should equal expected value',
               ExpectedValue, FSharedCounter);
end;

procedure TTestCase_Concurrency.Test_High_Contention;
var
  Threads: array of TThread;
  i: Integer;
begin
  FThreadCount := 8; // 更多线程
  FIterationsPerThread := 50; // 较少迭代但更高竞争

  SetLength(Threads, FThreadCount);

  // 创建线程但不立即启动
  for i := 0 to FThreadCount - 1 do
    Threads[i] := TThread.CreateAnonymousThread(@ThreadWorker);

  // 同时启动所有线程以增加竞争
  for i := 0 to FThreadCount - 1 do
    Threads[i].Start;

  // 等待完成
  for i := 0 to FThreadCount - 1 do
  begin
    Threads[i].WaitFor;
    Threads[i].Free;
  end;

  AssertEquals('High contention test should maintain correctness',
               FThreadCount * FIterationsPerThread, FSharedCounter);
end;

procedure TTestCase_Concurrency.Test_Fair_Unfair_Mix;
var
  Thread1, Thread2: TThread;
  Counter1, Counter2: Integer;
begin
  Counter1 := 0;
  Counter2 := 0;

  // 一个线程使用普通释放，一个使用公平释放
  Thread1 := TThread.CreateAnonymousThread(
    procedure
    var i: Integer;
    begin
      for i := 1 to 50 do
      begin
        FMutex.Acquire;
        try
          Inc(Counter1);
        finally
          FMutex.Release; // 普通释放
        end;
      end;
    end);

  Thread2 := TThread.CreateAnonymousThread(
    procedure
    var i: Integer;
    begin
      for i := 1 to 50 do
      begin
        FMutex.Acquire;
        try
          Inc(Counter2);
        finally
          FMutex.ReleaseFair; // 公平释放
        end;
      end;
    end);

  Thread1.Start;
  Thread2.Start;

  Thread1.WaitFor;
  Thread2.WaitFor;

  Thread1.Free;
  Thread2.Free;

  // 验证两个线程都完成了工作
  AssertEquals('Thread1 should complete all iterations', 50, Counter1);
  AssertEquals('Thread2 should complete all iterations', 50, Counter2);
end;

initialization
  RegisterTest(TTestCase_Global);
  RegisterTest(TTestCase_TParkingLotMutexBase);
  RegisterTest(TTestCase_Concurrency);

end.
