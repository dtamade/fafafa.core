program minimal_test;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.atomic,
  fafafa.core.sync.base,
  fafafa.core.sync.mutex.base,
  fafafa.core.sync.mutex.parkinglot.base;

// 简单的 Windows 实现用于测试
type
  TTestParkingLotMutex = class(TParkingLotMutexBase)
  protected
    function ParkThread(ATimeoutMs: Cardinal = INFINITE): Boolean; override;
    function UnparkOneThread: Boolean; override;
  end;

function TTestParkingLotMutex.ParkThread(ATimeoutMs: Cardinal): Boolean;
begin
  // 简单的等待实现
  if ATimeoutMs = INFINITE then
  begin
    while atomic_load(FState, mo_relaxed) and LOCKED_BIT <> 0 do
      Sleep(1);
    Result := True;
  end
  else
  begin
    var StartTime := GetTickCount64;
    while atomic_load(FState, mo_relaxed) and LOCKED_BIT <> 0 do
    begin
      if GetTickCount64 - StartTime >= ATimeoutMs then
        Exit(False);
      Sleep(1);
    end;
    Result := True;
  end;
end;

function TTestParkingLotMutex.UnparkOneThread: Boolean;
begin
  // 简单的唤醒实现 - 实际上不需要做什么，因为 ParkThread 会轮询
  Result := True;
end;

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

procedure TestBasicFunctionality;
var
  Mutex: IParkingLotMutex;
begin
  WriteLn('=== 测试基本功能 ===');
  
  // 测试创建
  Mutex := TTestParkingLotMutex.Create;
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
  TimeoutResult: Boolean;
  StartTime, ElapsedTime: QWord;
begin
  WriteLn('=== 测试超时功能 ===');
  
  Mutex := TTestParkingLotMutex.Create;
  Mutex.Acquire;
  
  StartTime := GetTickCount64;
  
  // 在同一线程中测试超时（这会立即失败，因为锁已被持有）
  TimeoutResult := Mutex.TryAcquire(50); // 50ms 超时
  
  ElapsedTime := GetTickCount64 - StartTime;
  
  AssertTrue('TryAcquire 应该因锁被占用而失败', not TimeoutResult);
  
  Mutex.Release;
  WriteLn;
end;

procedure TestFairRelease;
var
  Mutex: IParkingLotMutex;
begin
  WriteLn('=== 测试公平释放 ===');
  
  Mutex := TTestParkingLotMutex.Create;
  
  // 测试公平释放功能
  Mutex.Acquire;
  Mutex.ReleaseFair; // 使用公平释放
  
  // 测试公平释放后锁应该可以重新获取
  AssertTrue('公平释放后应该能重新获取锁', Mutex.TryAcquire);
  Mutex.Release;
  
  WriteLn;
end;

procedure TestAtomicOperations;
var
  Mutex: TTestParkingLotMutex;
  State: Int32;
begin
  WriteLn('=== 测试原子操作 ===');
  
  Mutex := TTestParkingLotMutex.Create;
  
  // 测试初始状态
  State := atomic_load(Mutex.FState, mo_relaxed);
  AssertTrue('初始状态应该为0', State = 0);
  
  // 测试快速路径
  AssertTrue('快速路径应该成功', Mutex.TryLockFast);
  State := atomic_load(Mutex.FState, mo_relaxed);
  AssertTrue('锁定后状态应该有 LOCKED_BIT', (State and LOCKED_BIT) <> 0);
  
  // 测试第二次快速路径应该失败
  AssertTrue('第二次快速路径应该失败', not Mutex.TryLockFast);
  
  Mutex.Release;
  State := atomic_load(Mutex.FState, mo_relaxed);
  AssertTrue('释放后状态应该为0', State = 0);
  
  Mutex.Free;
  WriteLn;
end;

procedure TestSpinBehavior;
var
  Mutex: TTestParkingLotMutex;
  SpinCount: Integer;
begin
  WriteLn('=== 测试自旋行为 ===');
  
  Mutex := TTestParkingLotMutex.Create;
  
  SpinCount := 0;
  
  // 测试自旋计数
  while Mutex.ShouldSpin(SpinCount) and (SpinCount < 50) do
    ; // 空循环
  
  AssertTrue('应该达到最大自旋次数', SpinCount = MAX_SPIN_COUNT);
  
  Mutex.Free;
  WriteLn;
end;

procedure RunAllTests;
begin
  WriteLn('开始 Parking Lot Mutex 基础测试...');
  WriteLn;
  
  TestBasicFunctionality;
  TestTryAcquireTimeout;
  TestFairRelease;
  TestAtomicOperations;
  TestSpinBehavior;
  
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
