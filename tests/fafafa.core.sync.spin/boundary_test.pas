program boundary_test;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  SysUtils, Classes,
  fafafa.core.sync.spin.base,
  fafafa.core.sync.spin;

var
  TestsPassed: Integer = 0;
  TestsFailed: Integer = 0;

procedure TestResult(const TestName: string; Passed: Boolean);
begin
  if Passed then
  begin
    WriteLn('✅ ', TestName, ': PASS');
    Inc(TestsPassed);
  end
  else
  begin
    WriteLn('❌ ', TestName, ': FAIL');
    Inc(TestsFailed);
  end;
end;

procedure TestExtremeTimeouts;
var
  L: ISpinLock;
  Policy: TSpinLockPolicy;
  StartTime: QWord;
begin
  WriteLn('Testing extreme timeout values...');
  
  Policy := DefaultSpinLockPolicy;
  L := MakeSpinLock(Policy);
  
  // 测试零超时
  TestResult('TryAcquire(0) on free lock', L.TryAcquire(0));
  L.Release;
  
  // 测试最大超时值
  StartTime := GetTickCount64;
  TestResult('TryAcquire(High(Cardinal)) on free lock', L.TryAcquire(High(Cardinal)));
  L.Release;
  TestResult('Max timeout completed quickly', GetTickCount64 - StartTime < 100);
  
  // 测试1毫秒超时
  TestResult('TryAcquire(1) on free lock', L.TryAcquire(1));
  L.Release;
end;

procedure TestHighFrequencyOperations;
var
  L: ISpinLock;
  Policy: TSpinLockPolicy;
  i: Integer;
  StartTime, EndTime: QWord;
  Success: Boolean;
begin
  WriteLn('Testing high frequency operations...');
  
  Policy := DefaultSpinLockPolicy;
  L := MakeSpinLock(Policy);
  
  Success := True;
  StartTime := GetTickCount64;
  
  try
    // 10000次快速获取/释放
    for i := 1 to 10000 do
    begin
      L.Acquire;
      L.Release;
    end;
  except
    Success := False;
  end;
  
  EndTime := GetTickCount64;
  
  TestResult('10000 rapid acquire/release cycles', Success);
  TestResult('High frequency completed in reasonable time', EndTime - StartTime < 1000);
end;

procedure TestPolicyExtremes;
var
  L: ISpinLock;
  Policy: TSpinLockPolicy;
  Success: Boolean;
begin
  WriteLn('Testing extreme policy configurations...');
  
  // 测试最小自旋次数
  Policy := DefaultSpinLockPolicy;
  Policy.MaxSpins := 1;
  Policy.MaxBackoffMs := 1;
  
  Success := True;
  try
    L := MakeSpinLock(Policy);
    L.Acquire;
    L.Release;
  except
    Success := False;
  end;
  
  TestResult('Minimal policy (MaxSpins=1, MaxBackoff=1)', Success);
  
  // 测试最大自旋次数
  Policy.MaxSpins := 1000;
  Policy.MaxBackoffMs := 100;
  
  Success := True;
  try
    L := MakeSpinLock(Policy);
    L.Acquire;
    L.Release;
  except
    Success := False;
  end;
  
  TestResult('Maximal policy (MaxSpins=1000, MaxBackoff=100)', Success);
end;

procedure TestStatisticsOverflow;
var
  L: ISpinLock;
  LStats: ISpinLockWithStats;
  Policy: TSpinLockPolicy;
  Stats: TSpinLockStats;
  i: Integer;
  Success: Boolean;
begin
  WriteLn('Testing statistics with large numbers...');
  
  Policy := DefaultSpinLockPolicy;
  Policy.EnableStats := True;
  
  L := MakeSpinLock(Policy);
  L.QueryInterface(ISpinLockWithStats, LStats);
  
  Success := True;
  try
    // 执行大量操作
    for i := 1 to 10000 do
    begin
      L.Acquire;
      L.Release;
    end;
    
    Stats := LStats.GetStats;
    Success := (Stats.AcquireCount = 10000) and (Stats.AcquireCount > 0);
  except
    Success := False;
  end;
  
  TestResult('Statistics with 10000 operations', Success);
  
  // 测试统计重置
  Success := True;
  try
    LStats.ResetStats;
    Stats := LStats.GetStats;
    Success := (Stats.AcquireCount = 0) and (Stats.ContentionCount = 0);
  except
    Success := False;
  end;
  
  TestResult('Statistics reset functionality', Success);
end;

{$IFDEF DEBUG}
procedure TestDebugFeatures;
var
  L: ISpinLock;
  LDebug: ISpinLockDebug;
  Policy: TSpinLockPolicy;
  Success: Boolean;
begin
  WriteLn('Testing debug features...');
  
  Policy := DefaultSpinLockPolicy;
  L := MakeSpinLock(Policy);
  L.QueryInterface(ISpinLockDebug, LDebug);
  
  // 测试初始状态
  TestResult('Initial IsHeld = False', not LDebug.IsHeld);
  TestResult('Initial OwnerThread = 0', LDebug.GetOwnerThread = 0);
  
  // 测试持锁状态
  L.Acquire;
  TestResult('After Acquire IsHeld = True', LDebug.IsHeld);
  TestResult('After Acquire OwnerThread > 0', LDebug.GetOwnerThread > 0);
  TestResult('HoldDuration >= 0', LDebug.GetHoldDurationUs >= 0);
  L.Release;
  
  // 测试死锁检测开关
  LDebug.EnableDeadlockDetection(5000);
  TestResult('Deadlock detection enabled', LDebug.IsDeadlockDetectionEnabled);
  
  LDebug.DisableDeadlockDetection;
  TestResult('Deadlock detection disabled', not LDebug.IsDeadlockDetectionEnabled);
end;
{$ENDIF}

procedure TestMemoryLeaks;
var
  i: Integer;
  L: ISpinLock;
  Policy: TSpinLockPolicy;
  Success: Boolean;
begin
  WriteLn('Testing memory management...');
  
  Policy := DefaultSpinLockPolicy;
  Success := True;
  
  try
    // 创建和销毁大量锁实例
    for i := 1 to 1000 do
    begin
      L := MakeSpinLock(Policy);
      L.Acquire;
      L.Release;
      L := nil; // 显式释放引用
    end;
  except
    Success := False;
  end;
  
  TestResult('1000 lock create/destroy cycles', Success);
end;

begin
  WriteLn('SpinLock Boundary Tests');
  WriteLn('=======================');
  WriteLn;
  
  TestExtremeTimeouts;
  WriteLn;
  
  TestHighFrequencyOperations;
  WriteLn;
  
  TestPolicyExtremes;
  WriteLn;
  
  TestStatisticsOverflow;
  WriteLn;
  
  {$IFDEF DEBUG}
  TestDebugFeatures;
  WriteLn;
  {$ENDIF}
  
  TestMemoryLeaks;
  WriteLn;
  
  WriteLn('Boundary Test Summary:');
  WriteLn('=====================');
  WriteLn('Tests Passed: ', TestsPassed);
  WriteLn('Tests Failed: ', TestsFailed);
  WriteLn('Total Tests: ', TestsPassed + TestsFailed);
  
  if TestsFailed = 0 then
    WriteLn('✅ ALL BOUNDARY TESTS PASSED')
  else
    WriteLn('❌ SOME BOUNDARY TESTS FAILED');
end.
