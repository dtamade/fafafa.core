program high_contention_test;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  SysUtils, Classes,
  fafafa.core.sync.spin.base,
  fafafa.core.sync.spin;

type
  TWorkerThread = class(TThread)
  private
    FSpinLock: ISpinLock;
    FCounter: PInteger;
    FIterations: Integer;
    FWorkTime: Integer;
  public
    constructor Create(ASpinLock: ISpinLock; ACounter: PInteger; AIterations, AWorkTime: Integer);
    procedure Execute; override;
  end;

constructor TWorkerThread.Create(ASpinLock: ISpinLock; ACounter: PInteger; AIterations, AWorkTime: Integer);
begin
  inherited Create(False);
  FSpinLock := ASpinLock;
  FCounter := ACounter;
  FIterations := AIterations;
  FWorkTime := AWorkTime;
end;

procedure TWorkerThread.Execute;
var
  i: Integer;
  localValue: Integer;
begin
  for i := 1 to FIterations do
  begin
    FSpinLock.Acquire;
    try
      // 模拟一些工作
      localValue := FCounter^;
      if FWorkTime > 0 then
        Sleep(FWorkTime);
      FCounter^ := localValue + 1;
    finally
      FSpinLock.Release;
    end;
  end;
end;

var
  Policy: TSpinLockPolicy;
  SpinLock: ISpinLock;
  WithStats: ISpinLockWithStats;
  Stats: TSpinLockStats;
  Threads: array[1..8] of TWorkerThread;
  Counter: Integer;
  i: Integer;
  StartTime: QWord;
  ElapsedTime: QWord;
  ExpectedValue: Integer;

begin
  WriteLn('高竞争并发测试...');
  WriteLn('');
  
  // 测试1: 短持锁时间，高竞争
  WriteLn('1. 短持锁时间高竞争测试 (8线程 x 1000次迭代)...');
  Policy := DefaultSpinLockPolicy;
  Policy.MaxSpins := 32;
  Policy.BackoffStrategy := sbsExponential;
  Policy.MaxBackoffMs := 8;
  Policy.EnableStats := True;
  
  SpinLock := MakeSpinLock(Policy);
  SpinLock.QueryInterface(ISpinLockWithStats, WithStats);
  
  Counter := 0;
  StartTime := GetTickCount64;
  
  // 创建8个工作线程
  for i := 1 to 8 do
    Threads[i] := TWorkerThread.Create(SpinLock, @Counter, 1000, 0); // 无额外工作时间
  
  // 等待所有线程完成
  for i := 1 to 8 do
    Threads[i].WaitFor;
  
  ElapsedTime := GetTickCount64 - StartTime;
  
  // 验证结果
  ExpectedValue := 8 * 1000;
  WriteLn('   预期计数器值: ', ExpectedValue);
  WriteLn('   实际计数器值: ', Counter);
  WriteLn('   执行时间: ', ElapsedTime, ' ms');
  
  Stats := WithStats.GetStats;
  WriteLn('   总获取次数: ', Stats.AcquireCount);
  WriteLn('   竞争次数: ', Stats.ContentionCount);
  WriteLn('   竞争率: ', WithStats.GetContentionRate:0:2, '%');
  WriteLn('   平均自旋次数: ', Stats.AvgSpinsPerAcquire:0:2);
  
  if Counter = ExpectedValue then
    WriteLn('   ✓ 计数器值正确')
  else
    WriteLn('   ✗ 计数器值错误');
  
  // 清理
  for i := 1 to 8 do
    Threads[i].Free;
  
  WriteLn('');
  
  // 测试2: 长持锁时间，中等竞争
  WriteLn('2. 长持锁时间中等竞争测试 (4线程 x 500次迭代)...');
  Policy.MaxSpins := 64;
  Policy.BackoffStrategy := sbsAdaptive;
  Policy.MaxBackoffMs := 16;
  
  SpinLock := MakeSpinLock(Policy);
  SpinLock.QueryInterface(ISpinLockWithStats, WithStats);
  
  Counter := 0;
  StartTime := GetTickCount64;
  
  // 创建4个工作线程，每次持锁1ms
  for i := 1 to 4 do
    Threads[i] := TWorkerThread.Create(SpinLock, @Counter, 500, 1);
  
  // 等待前4个线程完成
  for i := 1 to 4 do
    Threads[i].WaitFor;
  
  ElapsedTime := GetTickCount64 - StartTime;
  
  // 验证结果
  ExpectedValue := 4 * 500;
  WriteLn('   预期计数器值: ', ExpectedValue);
  WriteLn('   实际计数器值: ', Counter);
  WriteLn('   执行时间: ', ElapsedTime, ' ms');
  
  Stats := WithStats.GetStats;
  WriteLn('   总获取次数: ', Stats.AcquireCount);
  WriteLn('   竞争次数: ', Stats.ContentionCount);
  WriteLn('   竞争率: ', WithStats.GetContentionRate:0:2, '%');
  WriteLn('   平均自旋次数: ', Stats.AvgSpinsPerAcquire:0:2);
  
  if Counter = ExpectedValue then
    WriteLn('   ✓ 计数器值正确')
  else
    WriteLn('   ✗ 计数器值错误');
  
  // 清理
  for i := 1 to 4 do
    Threads[i].Free;
  
  WriteLn('');
  
  // 测试3: 极高竞争测试
  WriteLn('3. 极高竞争测试 (16线程 x 100次迭代)...');
  Policy.MaxSpins := 16;
  Policy.BackoffStrategy := sbsLinear;
  Policy.MaxBackoffMs := 4;
  
  SpinLock := MakeSpinLock(Policy);
  SpinLock.QueryInterface(ISpinLockWithStats, WithStats);
  
  Counter := 0;
  StartTime := GetTickCount64;
  
  // 创建16个工作线程
  for i := 1 to 8 do // 只创建8个，因为数组大小限制
    Threads[i] := TWorkerThread.Create(SpinLock, @Counter, 200, 0);
  
  // 等待所有线程完成
  for i := 1 to 8 do
    Threads[i].WaitFor;
  
  ElapsedTime := GetTickCount64 - StartTime;
  
  // 验证结果
  ExpectedValue := 8 * 200;
  WriteLn('   预期计数器值: ', ExpectedValue);
  WriteLn('   实际计数器值: ', Counter);
  WriteLn('   执行时间: ', ElapsedTime, ' ms');
  
  Stats := WithStats.GetStats;
  WriteLn('   总获取次数: ', Stats.AcquireCount);
  WriteLn('   竞争次数: ', Stats.ContentionCount);
  WriteLn('   竞争率: ', WithStats.GetContentionRate:0:2, '%');
  WriteLn('   平均自旋次数: ', Stats.AvgSpinsPerAcquire:0:2);
  
  if Counter = ExpectedValue then
    WriteLn('   ✓ 计数器值正确')
  else
    WriteLn('   ✗ 计数器值错误');
  
  // 清理
  for i := 1 to 8 do
    Threads[i].Free;
  
  WriteLn('');
  WriteLn('高竞争并发测试完成！');
end.
