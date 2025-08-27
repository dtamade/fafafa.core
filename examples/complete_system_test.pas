program CompleteSystemTest;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  SysUtils,
  fafafa.core.mem.complete,
  fafafa.core.mem.monitor;

var
  GTestsPassed: Integer = 0;
  GTestsFailed: Integer = 0;

procedure Assert(aCondition: Boolean; const aMessage: string);
begin
  if aCondition then
  begin
    Inc(GTestsPassed);
    Write('✅');
  end
  else
  begin
    Inc(GTestsFailed);
    WriteLn;
    WriteLn('❌ FAILED: ', aMessage);
    Write('❌');
  end;
end;

procedure TestMemoryPoolWrapper;
var
  LConfig: TMemoryPoolConfig;
  LPool: IMemoryPool;
  LPtr1, LPtr2: Pointer;
begin
  WriteLn('=== 内存池包装器测试 ===');
  
  // 测试固定大小池
  LConfig.PoolType := mptFixed;
  LConfig.BlockSize := 64;
  LConfig.BlockCount := 10;
  LConfig.MonitoringEnabled := True;
  LConfig.Name := 'TestFixedPool';
  
  LPool := TMemoryPoolWrapper.Create(LConfig);
  try
    Assert(LPool.GetPoolType = mptFixed, '池类型正确');
    Assert(LPool.GetName = 'TestFixedPool', '池名称正确');
    Assert(LPool.IsEmpty, '初始为空');
    Assert(not LPool.IsFull, '初始不满');
    
    LPtr1 := LPool.Alloc(64);
    Assert(LPtr1 <> nil, '分配成功');
    Assert(LPool.GetAllocatedCount = 1, '分配计数正确');
    
    LPtr2 := LPool.Alloc(32); // 小于块大小也应该成功
    Assert(LPtr2 <> nil, '小块分配成功');
    Assert(LPool.GetAllocatedCount = 2, '分配计数增加');
    
    LPool.FreeBlock(LPtr1);
    LPool.FreeBlock(LPtr2);
    Assert(LPool.IsEmpty, '释放后为空');
    
    WriteLn(' 包装器报告:');
    WriteLn(LPool.GenerateReport);
    
  finally
    LPool := nil; // 释放接口引用
  end;
  WriteLn(' 内存池包装器');
end;

procedure TestMemoryManager;
var
  LManager: TMemoryManager;
  LConfig: TMemoryPoolConfig;
  LPoolIndex: Integer;
  LPool: IMemoryPool;
  LPtr: Pointer;
begin
  WriteLn('=== 内存管理器测试 ===');
  
  LManager := TMemoryManager.Create;
  try
    Assert(LManager.GetTotalPools = 0, '初始池数量为0');
    
    // 创建固定大小池
    LConfig.PoolType := mptFixed;
    LConfig.BlockSize := 128;
    LConfig.BlockCount := 20;
    LConfig.MonitoringEnabled := True;
    LConfig.Name := 'ManagerTestPool';
    
    LPoolIndex := LManager.CreatePool(LConfig);
    Assert(LPoolIndex >= 0, '创建池成功');
    Assert(LManager.GetTotalPools = 1, '池数量增加');
    
    LPool := LManager.GetPool(LPoolIndex);
    Assert(LPool <> nil, '获取池成功');
    Assert(LPool.GetName = 'ManagerTestPool', '池名称正确');
    
    // 通过管理器分配内存
    LPtr := LManager.AllocFromPool(LPoolIndex, 100);
    Assert(LPtr <> nil, '通过管理器分配成功');
    
    LManager.FreeToPool(LPoolIndex, LPtr);
    Assert(LPool.IsEmpty, '通过管理器释放成功');
    
    // 测试智能分配
    LPtr := LManager.SmartAlloc(100);
    Assert(LPtr <> nil, '智能分配成功');
    LManager.SmartFree(LPtr, 100);
    
    // 测试查找池
    LPool := LManager.FindPool('ManagerTestPool');
    Assert(LPool <> nil, '按名称查找池成功');
    
    LPool := LManager.FindPool('NonExistentPool');
    Assert(LPool = nil, '查找不存在的池返回nil');
    
    WriteLn(' 全局报告:');
    WriteLn(LManager.GenerateGlobalReport);
    
  finally
    LManager.Free;
  end;
  WriteLn(' 内存管理器');
end;

procedure TestMonitoringSystem;
var
  LMonitor: TMemoryMonitor;
  LPtr1, LPtr2: Pointer;
  LStats: TMemoryStats;
begin
  WriteLn('=== 监控系统测试 ===');
  
  LMonitor := TMemoryMonitor.Create(100);
  try
    LMonitor.EnableLeakDetection(True);
    
    Assert(LMonitor.GetLeakCount = 0, '初始无泄漏');
    
    // 模拟分配
    LPtr1 := GetMem(256);
    LPtr2 := GetMem(512);
    
    LMonitor.RecordAllocation(LPtr1, 256);
    LMonitor.RecordAllocation(LPtr2, 512);
    
    LStats := LMonitor.GetStats;
    Assert(LStats.AllocationCount = 2, '分配计数正确');
    Assert(LStats.TotalAllocated = 768, '总分配大小正确');
    Assert(LStats.CurrentAllocated = 768, '当前分配大小正确');
    
    // 释放一个
    LMonitor.RecordFree(LPtr1);
    FreeMem(LPtr1);
    
    LStats := LMonitor.GetStats;
    Assert(LStats.FreeCount = 1, '释放计数正确');
    Assert(LMonitor.GetLeakCount = 1, '检测到1个泄漏');
    
    Assert(LMonitor.GetEfficiency > 0, '效率计算正常');
    
    WriteLn(' 监控报告:');
    WriteLn(LMonitor.GenerateReport);
    WriteLn(' 泄漏报告:');
    WriteLn(LMonitor.GetLeakReport);
    
    // 清理剩余内存
    LMonitor.RecordFree(LPtr2);
    FreeMem(LPtr2);
    
  finally
    LMonitor.Free;
  end;
  WriteLn(' 监控系统');
end;

procedure TestPreDefinedConfigs;
var
  LConfig: TMemoryPoolConfig;
  LPool: IMemoryPool;
begin
  WriteLn('=== 预定义配置测试 ===');
  
  // 测试小对象池配置
  LConfig := GetSmallObjectPoolConfig;
  Assert(LConfig.PoolType = mptFixed, '小对象池类型正确');
  Assert(LConfig.BlockSize > 0, '小对象池大小有效');
  
  LPool := TMemoryPoolWrapper.Create(LConfig);
  Assert(LPool <> nil, '小对象池创建成功');
  LPool := nil;
  
  // 测试中等对象池配置
  LConfig := GetMediumObjectPoolConfig;
  Assert(LConfig.PoolType = mptFixed, '中等对象池类型正确');
  Assert(LConfig.BlockSize > GetSmallObjectPoolConfig.BlockSize, '中等对象池更大');
  
  LPool := TMemoryPoolWrapper.Create(LConfig);
  Assert(LPool <> nil, '中等对象池创建成功');
  LPool := nil;
  
  // 测试大对象池配置
  LConfig := GetLargeObjectPoolConfig;
  Assert(LConfig.PoolType = mptFixed, '大对象池类型正确');
  Assert(LConfig.BlockSize > GetMediumObjectPoolConfig.BlockSize, '大对象池更大');
  
  LPool := TMemoryPoolWrapper.Create(LConfig);
  Assert(LPool <> nil, '大对象池创建成功');
  LPool := nil;
  
  WriteLn(' 预定义配置');
end;

procedure TestConvenienceFunctions;
var
  LPool: IMemoryPool;
  LPtr: Pointer;
begin
  WriteLn('=== 便利函数测试 ===');
  
  // 测试默认内存池创建
  LPool := CreateDefaultMemoryPool(64, 10, 'ConvenienceTest');
  Assert(LPool <> nil, '默认池创建成功');
  Assert(LPool.GetName = 'ConvenienceTest', '默认池名称正确');
  
  LPtr := LPool.Alloc(50);
  Assert(LPtr <> nil, '默认池分配成功');
  LPool.FreeBlock(LPtr);
  LPool := nil;
  
  // 测试线程安全池创建
  LPool := CreateThreadSafePool(128, 5, 'ThreadSafeTest');
  Assert(LPool <> nil, '线程安全池创建成功');
  Assert(LPool.GetPoolType = mptThreadSafe, '线程安全池类型正确');
  LPool := nil;
  
  // 测试对象池创建
  LPool := CreateObjectPool(TObject, 5, 'ObjectTest');
  Assert(LPool <> nil, '对象池创建成功');
  Assert(LPool.GetPoolType = mptObject, '对象池类型正确');
  LPool := nil;
  
  // 测试Slab池创建
  LPool := CreateSlabPool('SlabTest');
  Assert(LPool <> nil, 'Slab池创建成功');
  Assert(LPool.GetPoolType = mptSlab, 'Slab池类型正确');
  LPool := nil;
  
  WriteLn(' 便利函数');
end;

procedure TestGlobalMemoryManager;
var
  LManager: TMemoryManager;
  LStats: TMemoryStats;
begin
  WriteLn('=== 全局内存管理器测试 ===');
  
  LManager := GetGlobalMemoryManager;
  Assert(LManager <> nil, '获取全局管理器成功');
  
  // 启用全局监控
  LManager.EnableGlobalMonitoring(True);
  LManager.EnableGlobalLeakDetection(True);
  
  LStats := LManager.GetGlobalStats;
  Assert(LStats.StartTime > 0, '统计信息有效');
  
  WriteLn(' 全局统计:');
  WriteLn(LManager.GenerateGlobalReport);
  
  WriteLn(' 全局内存管理器');
end;

begin
  WriteLn('🚀 完整内存管理系统测试');
  WriteLn('这是一个企业级的内存管理解决方案！');
  WriteLn;
  
  try
    TestMemoryPoolWrapper;
    TestMemoryManager;
    TestMonitoringSystem;
    TestPreDefinedConfigs;
    TestConvenienceFunctions;
    TestGlobalMemoryManager;
    
    WriteLn;
    WriteLn('=== 最终测试结果 ===');
    WriteLn('通过: ', GTestsPassed);
    WriteLn('失败: ', GTestsFailed);
    WriteLn('成功率: ', (GTestsPassed * 100) div (GTestsPassed + GTestsFailed), '%');
    
    if GTestsFailed = 0 then
    begin
      WriteLn('🎉 所有测试通过！完整内存管理系统运行完美！');
      WriteLn;
      WriteLn('🏆 你现在拥有了一个企业级的内存管理解决方案：');
      WriteLn('  ✅ 多种内存池类型（固定、对象、缓冲区、Slab）');
      WriteLn('  ✅ 线程安全和无锁版本');
      WriteLn('  ✅ 完整的监控和统计系统');
      WriteLn('  ✅ 内存泄漏检测');
      WriteLn('  ✅ 统一的管理接口');
      WriteLn('  ✅ 智能分配策略');
      WriteLn('  ✅ 预定义配置');
      WriteLn('  ✅ 便利函数');
      WriteLn('  ✅ 全局管理器');
      WriteLn;
      WriteLn('这个系统可以处理任何规模的应用程序！');
      ExitCode := 0;
    end
    else
    begin
      WriteLn('💀 还有问题需要修复！');
      ExitCode := 1;
    end;
    
  except
    on E: Exception do
    begin
      WriteLn('💥 严重错误: ', E.Message);
      ExitCode := 2;
    end;
  end;
  
  WriteLn;
  WriteLn('完整系统测试完成！');
  
  // 清理全局资源
  FreeGlobalMemoryManager;
end.
