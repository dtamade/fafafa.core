program test_stats_interfaces;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  SysUtils,
  fafafa.core.sync.spin.base,
  fafafa.core.sync.spin;

var
  L: ISpinLock;
  LWithStats: ISpinLockWithStats;
  LDebug: ISpinLockDebug;
  Policy: TSpinLockPolicy;
  Stats: TSpinLockStats;
  i: Integer;

begin
  WriteLn('测试 SpinLock 统计和调试接口...');
  
  // 创建启用统计的自旋锁
  WriteLn('1. 创建启用统计的 SpinLock...');
  Policy := DefaultSpinLockPolicy;
  Policy.EnableStats := True;
  
  L := MakeSpinLock(Policy);
  
  // 获取统计接口
  if L.QueryInterface(ISpinLockWithStats, LWithStats) = S_OK then
    WriteLn('   OK: 成功获取 ISpinLockWithStats 接口')
  else
  begin
    WriteLn('   ERROR: 无法获取 ISpinLockWithStats 接口');
    Exit;
  end;
  
  // 获取 Debug 接口
  if L.QueryInterface(ISpinLockDebug, LDebug) = S_OK then
    WriteLn('   OK: 成功获取 ISpinLockDebug 接口')
  else
  begin
    WriteLn('   ERROR: 无法获取 ISpinLockDebug 接口');
    Exit;
  end;
  
  // 测试初始统计
  WriteLn('2. 测试初始统计...');
  Stats := LWithStats.GetStats;
  WriteLn('   获取次数: ', Stats.AcquireCount);
  WriteLn('   竞争次数: ', Stats.ContentionCount);
  WriteLn('   总自旋次数: ', Stats.TotalSpinCount);
  WriteLn('   竞争率: ', LWithStats.GetContentionRate:0:3, '%');
  
  // 执行一些锁操作
  WriteLn('3. 执行锁操作...');
  for i := 1 to 10 do
  begin
    L.Acquire;
    // 模拟一些工作
    Sleep(1);
    L.Release;
  end;
  
  // 查看更新后的统计
  WriteLn('4. 查看更新后的统计...');
  Stats := LWithStats.GetStats;
  WriteLn('   获取次数: ', Stats.AcquireCount);
  WriteLn('   竞争次数: ', Stats.ContentionCount);
  WriteLn('   总自旋次数: ', Stats.TotalSpinCount);
  WriteLn('   竞争率: ', LWithStats.GetContentionRate:0:3, '%');
  WriteLn('   自旋效率: ', LWithStats.GetSpinEfficiency:0:3, '%');
  WriteLn('   平均等待时间: ', LWithStats.GetAverageWaitTime:0:3, ' 微秒');
  
  // 测试调试接口
  WriteLn('5. 测试调试接口...');
  WriteLn('   调试信息: ', LDebug.GetDebugInfo);
  WriteLn('   持有计数: ', LDebug.GetHoldCount);
  WriteLn('   上次获取自旋次数: ', LDebug.GetLastAcquireSpins);
  WriteLn('   上次获取耗时: ', LDebug.GetLastAcquireTimeUs, ' 微秒');
  WriteLn('   死锁信息: ', LDebug.GetDeadlockInfo);
  
  // 测试统计重置
  WriteLn('6. 测试统计重置...');
  LWithStats.ResetStats;
  Stats := LWithStats.GetStats;
  WriteLn('   重置后获取次数: ', Stats.AcquireCount);
  WriteLn('   重置后竞争次数: ', Stats.ContentionCount);
  
  WriteLn('');
  WriteLn('所有测试完成！');
end.
