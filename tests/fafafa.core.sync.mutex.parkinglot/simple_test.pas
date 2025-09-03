program simple_test;

{$mode objfpc}{$H+}

uses
  SysUtils, Classes,
  fafafa.core.sync.base,
  fafafa.core.sync.mutex.base,
  fafafa.core.sync.mutex.parkinglot;

var
  TestsPassed: Integer = 0;
  TestsFailed: Integer = 0;

procedure AssertTrue(const AMessage: string; ACondition: Boolean);
begin
  if ACondition then
  begin
    WriteLn('✓ PASS: ', AMessage);
    Inc(TestsPassed);
  end
  else
  begin
    WriteLn('✗ FAIL: ', AMessage);
    Inc(TestsFailed);
  end;
end;

procedure AssertFalse(const AMessage: string; ACondition: Boolean);
begin
  AssertTrue(AMessage, not ACondition);
end;

procedure TestBasicFunctionality;
var
  Mutex: IParkingLotMutex;
begin
  WriteLn('=== 测试基本功能 ===');
  
  // 测试创建
  Mutex := MakeParkingLotMutex;
  AssertTrue('应该能创建 ParkingLot Mutex', Mutex <> nil);
  
  // 测试基本锁定
  Mutex.Acquire;
  Mutex.Release;
  AssertTrue('基本 Acquire/Release 应该正常工作', True);
  
  // 测试 TryAcquire
  AssertTrue('TryAcquire 在锁可用时应该成功', Mutex.TryAcquire);
  Mutex.Release;
  
  // 测试 GetHandle
  AssertTrue('GetHandle 应该返回有效句柄', Mutex.GetHandle <> nil);
  
  WriteLn;
end;

procedure TestTryAcquireTimeout;
var
  Mutex: IParkingLotMutex;
  Thread: TThread;
  TimeoutResult: Boolean;
  StartTime, ElapsedTime: QWord;
begin
  WriteLn('=== 测试超时功能 ===');
  
  Mutex := MakeParkingLotMutex;
  Mutex.Acquire;
  
  StartTime := GetTickCount64;
  TimeoutResult := True;
  
  Thread := TThread.CreateAnonymousThread(
    procedure
    begin
      TimeoutResult := Mutex.TryAcquire(50); // 50ms 超时
    end);
  
  Thread.Start;
  Thread.WaitFor;
  Thread.Free;
  
  ElapsedTime := GetTickCount64 - StartTime;
  
  AssertFalse('TryAcquire 应该因超时而失败', TimeoutResult);
  AssertTrue('应该等待至少指定的超时时间', ElapsedTime >= 40); // 允许一些误差
  
  Mutex.Release;
  WriteLn;
end;

procedure TestConcurrency;
var
  Mutex: IParkingLotMutex;
  Counter: Integer;
  Threads: array[1..4] of TThread;
  i: Integer;
const
  ITERATIONS = 1000;
begin
  WriteLn('=== 测试并发正确性 ===');
  
  Mutex := MakeParkingLotMutex;
  Counter := 0;
  
  // 创建4个线程，每个增加计数器1000次
  for i := 1 to 4 do
  begin
    Threads[i] := TThread.CreateAnonymousThread(
      procedure
      var
        j: Integer;
      begin
        for j := 1 to ITERATIONS do
        begin
          Mutex.Acquire;
          try
            Inc(Counter);
          finally
            Mutex.Release;
          end;
        end;
      end);
  end;
  
  // 启动所有线程
  for i := 1 to 4 do
    Threads[i].Start;
  
  // 等待所有线程完成
  for i := 1 to 4 do
  begin
    Threads[i].WaitFor;
    Threads[i].Free;
  end;
  
  AssertTrue('并发计数应该正确', Counter = ITERATIONS * 4);
  WriteLn;
end;

procedure TestFairRelease;
var
  Mutex: IParkingLotMutex;
begin
  WriteLn('=== 测试公平释放 ===');
  
  Mutex := MakeParkingLotMutex;
  
  // 测试公平释放功能
  Mutex.Acquire;
  Mutex.ReleaseFair; // 使用公平释放
  
  // 测试公平释放后锁应该可以重新获取
  AssertTrue('公平释放后应该能重新获取锁', Mutex.TryAcquire);
  Mutex.Release;
  
  WriteLn;
end;

procedure TestLockGuard;
var
  Mutex: IParkingLotMutex;
  Guard: ILockGuard;
begin
  WriteLn('=== 测试锁守卫 ===');
  
  Mutex := MakeParkingLotMutex;
  
  // 测试 RAII 守护功能
  Guard := Mutex.LockGuard;
  AssertTrue('LockGuard 应该返回有效的守护实例', Guard <> nil);
  
  // 守护会自动管理锁，无需手动释放
  Guard := nil; // 释放守卫，应该自动释放锁
  
  // 验证锁已被释放
  AssertTrue('守卫释放后锁应该可用', Mutex.TryAcquire);
  Mutex.Release;
  
  WriteLn;
end;

procedure RunAllTests;
begin
  WriteLn('开始 Parking Lot Mutex 测试...');
  WriteLn;
  
  TestBasicFunctionality;
  TestTryAcquireTimeout;
  TestConcurrency;
  TestFairRelease;
  TestLockGuard;
  
  WriteLn('=== 测试结果 ===');
  WriteLn('通过: ', TestsPassed);
  WriteLn('失败: ', TestsFailed);
  WriteLn('总计: ', TestsPassed + TestsFailed);
  
  if TestsFailed = 0 then
    WriteLn('所有测试通过! ✓')
  else
    WriteLn('有测试失败! ✗');
end;

begin
  try
    RunAllTests;
  except
    on E: Exception do
    begin
      WriteLn('测试过程中发生异常: ', E.Message);
      ExitCode := 1;
    end;
  end;
  
  WriteLn;
  WriteLn('按回车键退出...');
  ReadLn;
end.
