program stats_test;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  SysUtils,
  fafafa.core.sync.spin.base,
  fafafa.core.sync.spin;

var
  L: ISpinLock;
  LWithStats: ISpinLockWithStats;
  {$IFDEF DEBUG}
  LDebug: ISpinLockDebug;
  {$ENDIF}
  Policy: TSpinLockPolicy;
  Stats: TSpinLockStats;
  i: Integer;

begin
  WriteLn('Testing SpinLock Statistics and Debug Features...');
  
  // 创建启用统计的自旋锁
  WriteLn('1. Creating SpinLock with statistics enabled...');
  Policy := DefaultSpinLockPolicy;
  Policy.EnableStats := True;
  
  L := MakeSpinLock(Policy);
  
  // 获取统计接口
  if L.QueryInterface(ISpinLockWithStats, LWithStats) = S_OK then
    WriteLn('   OK: ISpinLockWithStats interface obtained')
  else
  begin
    WriteLn('   ERROR: Failed to get ISpinLockWithStats interface');
    Exit;
  end;
  
  {$IFDEF DEBUG}
  // 获取 Debug 接口
  if L.QueryInterface(ISpinLockDebug, LDebug) = S_OK then
    WriteLn('   OK: ISpinLockDebug interface obtained')
  else
  begin
    WriteLn('   ERROR: Failed to get ISpinLockDebug interface');
    Exit;
  end;
  {$ENDIF}
  
  // 测试初始统计
  WriteLn('2. Testing initial statistics...');
  Stats := LWithStats.GetStats;
  WriteLn('   AcquireCount: ', Stats.AcquireCount);
  WriteLn('   ContentionCount: ', Stats.ContentionCount);
  WriteLn('   TotalSpinCount: ', Stats.TotalSpinCount);
  WriteLn('   ContentionRate: ', LWithStats.GetContentionRate:0:3);
  
  // 执行一些锁操作
  WriteLn('3. Performing lock operations...');
  for i := 1 to 10 do
  begin
    L.Acquire;
    // 模拟一些工作
    Sleep(1);
    L.Release;
  end;
  
  // 检查统计信息
  WriteLn('4. Checking statistics after operations...');
  Stats := LWithStats.GetStats;
  WriteLn('   AcquireCount: ', Stats.AcquireCount);
  WriteLn('   ContentionCount: ', Stats.ContentionCount);
  WriteLn('   TotalSpinCount: ', Stats.TotalSpinCount);
  WriteLn('   ContentionRate: ', LWithStats.GetContentionRate:0:3);
  WriteLn('   AvgHoldTimeUs: ', LWithStats.GetAvgHoldTimeUs:0:1);
  WriteLn('   MaxHoldTimeUs: ', Stats.MaxHoldTimeUs);
  
  {$IFDEF DEBUG}
  // 测试 Debug 功能
  WriteLn('5. Testing Debug features...');
  WriteLn('   IsHeld: ', LDebug.IsHeld);
  WriteLn('   OwnerThread: ', LDebug.GetOwnerThread);
  
  // 测试死锁检测
  WriteLn('6. Testing deadlock detection...');
  LDebug.EnableDeadlockDetection(5000); // 5秒超时
  WriteLn('   DeadlockDetectionEnabled: ', LDebug.IsDeadlockDetectionEnabled);
  
  L.Acquire;
  WriteLn('   IsHeld: ', LDebug.IsHeld);
  WriteLn('   OwnerThread: ', LDebug.GetOwnerThread);
  WriteLn('   HoldDurationUs: ', LDebug.GetHoldDurationUs);
  L.Release;
  
  LDebug.DisableDeadlockDetection;
  WriteLn('   DeadlockDetectionEnabled: ', LDebug.IsDeadlockDetectionEnabled);
  {$ENDIF}
  
  // 重置统计
  WriteLn('7. Testing statistics reset...');
  LWithStats.ResetStats;
  Stats := LWithStats.GetStats;
  WriteLn('   AcquireCount after reset: ', Stats.AcquireCount);
  WriteLn('   ContentionCount after reset: ', Stats.ContentionCount);
  
  WriteLn('Statistics and Debug test completed successfully!');
end.
