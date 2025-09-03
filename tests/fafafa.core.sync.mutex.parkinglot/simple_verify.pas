program simple_verify;

{$mode objfpc}{$H+}

uses
  SysUtils, Classes,
  fafafa.core.sync.base,
  fafafa.core.sync.mutex.base,
  fafafa.core.sync.mutex.parkinglot;

var
  LogFile: TextFile;

procedure Log(const AMessage: string);
begin
  WriteLn(AMessage);
  WriteLn(LogFile, AMessage);
  Flush(LogFile);
end;

procedure TestBasicFunctionality;
var
  Mutex: IParkingLotMutex;
begin
  Log('=== 测试基本功能 ===');
  
  try
    // 测试创建
    Mutex := MakeParkingLotMutex;
    if Mutex <> nil then
      Log('✓ PASS: 成功创建 ParkingLot Mutex')
    else
      Log('✗ FAIL: 无法创建 ParkingLot Mutex');
    
    // 测试基本锁定
    Mutex.Acquire;
    Log('✓ PASS: Acquire 成功');
    
    Mutex.Release;
    Log('✓ PASS: Release 成功');
    
    // 测试 TryAcquire
    if Mutex.TryAcquire then
    begin
      Log('✓ PASS: TryAcquire 成功');
      Mutex.Release;
    end
    else
      Log('✗ FAIL: TryAcquire 失败');
    
    // 测试 GetHandle
    if Mutex.GetHandle <> nil then
      Log('✓ PASS: GetHandle 返回有效句柄')
    else
      Log('✗ FAIL: GetHandle 返回空句柄');
    
    // 测试公平释放
    Mutex.Acquire;
    Mutex.ReleaseFair;
    Log('✓ PASS: ReleaseFair 成功');
    
  except
    on E: Exception do
      Log('✗ EXCEPTION: ' + E.Message);
  end;
  
  Log('');
end;

procedure TestConcurrency;
var
  Mutex: IParkingLotMutex;
  Counter: Integer;
  Threads: array[1..4] of TThread;
  i: Integer;
const
  ITERATIONS = 100; // 减少迭代次数以便快速测试
begin
  Log('=== 测试并发正确性 ===');
  
  try
    Mutex := MakeParkingLotMutex;
    Counter := 0;
    
    // 创建4个线程，每个增加计数器100次
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
    
    if Counter = ITERATIONS * 4 then
      Log('✓ PASS: 并发计数正确 (' + IntToStr(Counter) + ')')
    else
      Log('✗ FAIL: 并发计数错误，期望 ' + IntToStr(ITERATIONS * 4) + '，实际 ' + IntToStr(Counter));
    
  except
    on E: Exception do
      Log('✗ EXCEPTION: ' + E.Message);
  end;
  
  Log('');
end;

procedure TestLockGuard;
var
  Mutex: IParkingLotMutex;
  Guard: ILockGuard;
begin
  Log('=== 测试锁守卫 ===');
  
  try
    Mutex := MakeParkingLotMutex;
    
    // 测试 RAII 守护功能
    Guard := Mutex.LockGuard;
    if Guard <> nil then
      Log('✓ PASS: LockGuard 创建成功')
    else
      Log('✗ FAIL: LockGuard 创建失败');
    
    // 守护会自动管理锁，无需手动释放
    Guard := nil; // 释放守卫，应该自动释放锁
    
    // 验证锁已被释放
    if Mutex.TryAcquire then
    begin
      Log('✓ PASS: 守卫释放后锁可用');
      Mutex.Release;
    end
    else
      Log('✗ FAIL: 守卫释放后锁不可用');
    
  except
    on E: Exception do
      Log('✗ EXCEPTION: ' + E.Message);
  end;
  
  Log('');
end;

begin
  AssignFile(LogFile, 'tests\fafafa.core.sync.mutex.parkinglot\test_results.txt');
  Rewrite(LogFile);
  
  try
    Log('开始 Parking Lot Mutex 验证测试...');
    Log('时间: ' + DateTimeToStr(Now));
    Log('');
    
    TestBasicFunctionality;
    TestConcurrency;
    TestLockGuard;
    
    Log('=== 验证测试完成 ===');
    
  except
    on E: Exception do
    begin
      Log('测试过程中发生异常: ' + E.Message);
      ExitCode := 1;
    end;
  end;
  
  CloseFile(LogFile);
  WriteLn('测试结果已保存到: tests\fafafa.core.sync.mutex.parkinglot\test_results.txt');
end.
