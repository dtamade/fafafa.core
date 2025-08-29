program stress_test;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  SysUtils, Classes,
  fafafa.core.sync.spin.base,
  fafafa.core.sync.spin;

type
  TStressTestThread = class(TThread)
  private
    FSpinLock: ISpinLock;
    FWithStats: ISpinLockWithStats;
    FCounter: PInteger;
    FIterations: Integer;
    FMyThreadId: Integer;
    FErrors: Integer;
  public
    constructor Create(ASpinLock: ISpinLock; ACounter: PInteger; 
                      AIterations, AThreadId: Integer);
    procedure Execute; override;
    property Errors: Integer read FErrors;
  end;

constructor TStressTestThread.Create(ASpinLock: ISpinLock; ACounter: PInteger; 
                                    AIterations, AThreadId: Integer);
begin
  FSpinLock := ASpinLock;
  FSpinLock.QueryInterface(ISpinLockWithStats, FWithStats);
  FCounter := ACounter;
  FIterations := AIterations;
  FMyThreadId := AThreadId;
  FErrors := 0;
  inherited Create(False);
end;

procedure TStressTestThread.Execute;
var
  i: Integer;
  localValue: Integer;
begin
  try
    for i := 1 to FIterations do
    begin
      // 测试基本获取/释放
      FSpinLock.Acquire;
      try
        localValue := FCounter^;
        // 模拟一些计算工作
        Inc(localValue);
        FCounter^ := localValue;
      finally
        FSpinLock.Release;
      end;
      
      // 测试 TryAcquire
      if FSpinLock.TryAcquire then
      begin
        try
          localValue := FCounter^;
          Inc(localValue);
          FCounter^ := localValue;
        finally
          FSpinLock.Release;
        end;
      end;
      
      // 测试带超时的 TryAcquire
      if FSpinLock.TryAcquire(1) then // 1ms 超时
      begin
        try
          localValue := FCounter^;
          Inc(localValue);
          FCounter^ := localValue;
        finally
          FSpinLock.Release;
        end;
      end;
      
      // 偶尔让出 CPU
      if (i mod 100) = 0 then
        Sleep(0);
    end;
  except
    on E: Exception do
    begin
      Inc(FErrors);
      WriteLn('Thread ', FMyThreadId, ' error: ', E.Message);
    end;
  end;
end;

var
  Policy: TSpinLockPolicy;
  SpinLock: ISpinLock;
  WithStats: ISpinLockWithStats;
  Threads: array[1..8] of TStressTestThread;
  Counter: Integer;
  i: Integer;
  StartTime, EndTime: QWord;
  Stats: TSpinLockStats;
  TotalErrors: Integer;
  ExpectedValue: Integer;

begin
  WriteLn('SpinLock Stress Test');
  WriteLn('===================');
  
  // 创建启用统计的自旋锁
  Policy := DefaultSpinLockPolicy;
  Policy.EnableStats := True;
  Policy.MaxSpins := 32; // 减少自旋以增加竞争
  
  SpinLock := MakeSpinLock(Policy);
  SpinLock.QueryInterface(ISpinLockWithStats, WithStats);
  
  Counter := 0;
  TotalErrors := 0;
  
  WriteLn('Starting stress test with 8 threads, 1000 iterations each...');
  StartTime := GetTickCount64;
  
  // 创建并启动线程
  for i := 1 to 8 do
  begin
    Threads[i] := TStressTestThread.Create(SpinLock, @Counter, 1000, i);
  end;
  
  // 等待所有线程完成
  for i := 1 to 8 do
  begin
    Threads[i].WaitFor;
    Inc(TotalErrors, Threads[i].Errors);
    Threads[i].Free;
  end;
  
  EndTime := GetTickCount64;
  
  // 检查结果
  ExpectedValue := 8 * 1000 * 3; // 8线程 * 1000次迭代 * 3次操作
  
  WriteLn;
  WriteLn('Stress Test Results:');
  WriteLn('-------------------');
  WriteLn('Duration: ', EndTime - StartTime, ' ms');
  WriteLn('Total Errors: ', TotalErrors);
  WriteLn('Expected Counter Value: ', ExpectedValue);
  WriteLn('Actual Counter Value: ', Counter);
  if Counter = ExpectedValue then
    WriteLn('Data Integrity: PASS')
  else
    WriteLn('Data Integrity: FAIL');
  
  // 显示统计信息
  Stats := WithStats.GetStats;
  WriteLn;
  WriteLn('Statistics:');
  WriteLn('----------');
  WriteLn('Total Acquires: ', Stats.AcquireCount);
  WriteLn('Contentions: ', Stats.ContentionCount);
  WriteLn('Contention Rate: ', WithStats.GetContentionRate:0:3);
  WriteLn('Total Spins: ', Stats.TotalSpinCount);
  WriteLn('Avg Spins/Acquire: ', Stats.AvgSpinsPerAcquire:0:2);
  WriteLn('Avg Hold Time: ', WithStats.GetAvgHoldTimeUs:0:1, ' μs');
  WriteLn('Max Hold Time: ', Stats.MaxHoldTimeUs, ' μs');
  
  if (TotalErrors = 0) and (Counter = ExpectedValue) then
    WriteLn('✅ STRESS TEST PASSED')
  else
    WriteLn('❌ STRESS TEST FAILED');
end.
