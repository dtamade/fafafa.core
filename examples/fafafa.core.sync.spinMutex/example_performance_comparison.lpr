program example_performance_comparison;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  SysUtils,
  fafafa.core.sync.spinMutex,
  fafafa.core.sync.namedMutex;

const
  TEST_ITERATIONS = 1000;
  MUTEX_NAME = 'PerformanceTestMutex';

// ===== 性能测试辅助函数 =====
function GetTimeMs: QWord;
begin
  Result := GetTickCount64;
end;

// ===== 自旋互斥锁性能测试 =====
procedure TestSpinMutexPerformance;
var
  LMutex: ISpinMutex;
  LGuard: ISpinMutexGuard;
  LConfig: TSpinMutexConfig;
  LStats: TSpinMutexStats;
  LStartTime, LEndTime: QWord;
  i: Integer;
begin
  WriteLn('=== 自旋互斥锁性能测试 ===');
  
  // 配置高性能自旋互斥锁
  LConfig := HighPerformanceSpinMutexConfig;
  LMutex := CreateSpinMutex(MUTEX_NAME + '_Spin', LConfig);
  
  // 重置统计
  LMutex.ResetStats;
  
  LStartTime := GetTimeMs;
  
  // 执行测试
  for i := 1 to TEST_ITERATIONS do
  begin
    LGuard := LMutex.Lock;
    // 模拟极短的临界区
    LGuard := nil;
  end;
  
  LEndTime := GetTimeMs;
  
  // 输出结果
  LStats := LMutex.GetStats;
  WriteLn('测试迭代次数: ', TEST_ITERATIONS);
  WriteLn('总耗时: ', LEndTime - LStartTime, ' 毫秒');
  WriteLn('平均每次操作: ', (LEndTime - LStartTime) / TEST_ITERATIONS:0:3, ' 毫秒');
  WriteLn('自旋效率: ', LMutex.GetSpinEfficiency:0:2);
  WriteLn('平均自旋次数: ', LStats.AvgSpinsPerAcquire:0:2);
  WriteLn;
end;

// ===== 命名互斥锁性能测试 =====
procedure TestNamedMutexPerformance;
var
  LMutex: INamedMutex;
  LGuard: INamedMutexGuard;
  LStartTime, LEndTime: QWord;
  i: Integer;
begin
  WriteLn('=== 命名互斥锁性能测试 ===');
  
  LMutex := CreateNamedMutex(MUTEX_NAME + '_Named');
  
  LStartTime := GetTimeMs;
  
  // 执行测试
  for i := 1 to TEST_ITERATIONS do
  begin
    LGuard := LMutex.Lock;
    // 模拟极短的临界区
    LGuard := nil;
  end;
  
  LEndTime := GetTimeMs;
  
  // 输出结果
  WriteLn('测试迭代次数: ', TEST_ITERATIONS);
  WriteLn('总耗时: ', LEndTime - LStartTime, ' 毫秒');
  WriteLn('平均每次操作: ', (LEndTime - LStartTime) / TEST_ITERATIONS:0:3, ' 毫秒');
  WriteLn;
end;

// ===== 不同自旋策略性能对比 =====
procedure TestSpinStrategies;
var
  LMutex: ISpinMutex;
  LGuard: ISpinMutexGuard;
  LConfig: TSpinMutexConfig;
  LStats: TSpinMutexStats;
  LStartTime, LEndTime: QWord;
  LStrategy: TSpinBackoffStrategy;
  i: Integer;
begin
  WriteLn('=== 不同自旋策略性能对比 ===');
  
  for LStrategy := sbsNone to sbsAdaptive do
  begin
    case LStrategy of
      sbsNone: WriteLn('测试策略: 无退避');
      sbsLinear: WriteLn('测试策略: 线性退避');
      sbsExponential: WriteLn('测试策略: 指数退避');
      sbsAdaptive: WriteLn('测试策略: 自适应退避');
    end;
    
    // 配置策略
    LConfig := DefaultSpinMutexConfig;
    LConfig.BackoffStrategy := LStrategy;
    LConfig.MaxSpinCount := 500;
    LConfig.EnableStats := True;
    
    LMutex := CreateSpinMutex(MUTEX_NAME + '_Strategy_' + IntToStr(Ord(LStrategy)), LConfig);
    LMutex.ResetStats;
    
    LStartTime := GetTimeMs;
    
    // 执行测试
    for i := 1 to TEST_ITERATIONS div 2 do
    begin
      LGuard := LMutex.Lock;
      LGuard := nil;
    end;
    
    LEndTime := GetTimeMs;
    
    // 输出结果
    LStats := LMutex.GetStats;
    WriteLn('  耗时: ', LEndTime - LStartTime, ' 毫秒');
    WriteLn('  自旋效率: ', LMutex.GetSpinEfficiency:0:2);
    WriteLn('  平均自旋次数: ', LStats.AvgSpinsPerAcquire:0:2);
    WriteLn;
  end;
end;

// ===== 不同自旋次数性能对比 =====
procedure TestSpinCounts;
var
  LMutex: ISpinMutex;
  LGuard: ISpinMutexGuard;
  LConfig: TSpinMutexConfig;
  LStats: TSpinMutexStats;
  LStartTime, LEndTime: QWord;
  LSpinCount: Cardinal;
  i: Integer;
begin
  WriteLn('=== 不同自旋次数性能对比 ===');
  
  for LSpinCount in [100, 500, 1000, 2000, 5000] do
  begin
    WriteLn('测试自旋次数: ', LSpinCount);
    
    // 配置自旋次数
    LConfig := DefaultSpinMutexConfig;
    LConfig.MaxSpinCount := LSpinCount;
    LConfig.EnableStats := True;
    
    LMutex := CreateSpinMutex(MUTEX_NAME + '_Count_' + IntToStr(LSpinCount), LConfig);
    LMutex.ResetStats;
    
    LStartTime := GetTimeMs;
    
    // 执行测试
    for i := 1 to TEST_ITERATIONS div 2 do
    begin
      LGuard := LMutex.Lock;
      LGuard := nil;
    end;
    
    LEndTime := GetTimeMs;
    
    // 输出结果
    LStats := LMutex.GetStats;
    WriteLn('  耗时: ', LEndTime - LStartTime, ' 毫秒');
    WriteLn('  自旋效率: ', LMutex.GetSpinEfficiency:0:2);
    WriteLn('  平均自旋次数: ', LStats.AvgSpinsPerAcquire:0:2);
    WriteLn;
  end;
end;

// ===== 内存使用对比 =====
procedure TestMemoryUsage;
var
  LSpinMutex: ISpinMutex;
  LNamedMutex: INamedMutex;
  LMemBefore, LMemAfter: PtrUInt;
begin
  WriteLn('=== 内存使用对比 ===');
  
  // 测试自旋互斥锁内存使用
  LMemBefore := GetHeapStatus.TotalAllocated;
  LSpinMutex := CreateSpinMutex('MemTestSpin');
  LMemAfter := GetHeapStatus.TotalAllocated;
  WriteLn('自旋互斥锁内存使用: ', LMemAfter - LMemBefore, ' 字节');
  LSpinMutex := nil;
  
  // 测试命名互斥锁内存使用
  LMemBefore := GetHeapStatus.TotalAllocated;
  LNamedMutex := CreateNamedMutex('MemTestNamed');
  LMemAfter := GetHeapStatus.TotalAllocated;
  WriteLn('命名互斥锁内存使用: ', LMemAfter - LMemBefore, ' 字节');
  LNamedMutex := nil;
  
  WriteLn;
end;

// ===== 竞争场景模拟 =====
procedure TestContentionScenario;
var
  LMutex: ISpinMutex;
  LGuard: ISpinMutexGuard;
  LConfig: TSpinMutexConfig;
  LStats: TSpinMutexStats;
  LStartTime, LEndTime: QWord;
  i: Integer;
begin
  WriteLn('=== 竞争场景模拟 ===');
  
  // 配置适合竞争场景的参数
  LConfig := DefaultSpinMutexConfig;
  LConfig.MaxSpinCount := 1000;
  LConfig.BackoffStrategy := sbsAdaptive;
  LConfig.EnableStats := True;
  
  LMutex := CreateSpinMutex('ContentionTest', LConfig);
  LMutex.ResetStats;
  
  LStartTime := GetTimeMs;
  
  // 模拟竞争：快速获取和释放
  for i := 1 to TEST_ITERATIONS * 2 do
  begin
    LGuard := LMutex.Lock;
    // 模拟非常短的临界区
    LGuard := nil;
  end;
  
  LEndTime := GetTimeMs;
  
  // 输出结果
  LStats := LMutex.GetStats;
  WriteLn('竞争测试结果:');
  WriteLn('  总操作次数: ', TEST_ITERATIONS * 2);
  WriteLn('  总耗时: ', LEndTime - LStartTime, ' 毫秒');
  WriteLn('  平均每次操作: ', (LEndTime - LStartTime) / (TEST_ITERATIONS * 2):0:3, ' 毫秒');
  WriteLn('  自旋效率: ', LMutex.GetSpinEfficiency:0:2);
  WriteLn('  竞争率: ', LMutex.GetContentionRate:0:2);
  WriteLn('  平均自旋次数: ', LStats.AvgSpinsPerAcquire:0:2);
  
  WriteLn;
end;

// ===== 主程序 =====
begin
  WriteLn('fafafa.core.sync.spinMutex 性能对比示例');
  WriteLn('=========================================');
  WriteLn;
  
  try
    TestSpinMutexPerformance;
    TestNamedMutexPerformance;
    TestSpinStrategies;
    TestSpinCounts;
    TestMemoryUsage;
    TestContentionScenario;
    
    WriteLn('性能测试完成！');
    WriteLn;
    WriteLn('总结:');
    WriteLn('- 自旋互斥锁在短临界区场景下通常比传统互斥锁更快');
    WriteLn('- 自适应退避策略在大多数情况下表现最佳');
    WriteLn('- 自旋次数需要根据具体应用场景调优');
    WriteLn('- 在高竞争场景下，适当的退避策略很重要');
    
  except
    on E: Exception do
    begin
      WriteLn('发生异常: ', E.ClassName, ': ', E.Message);
      ExitCode := 1;
    end;
  end;
  
  WriteLn;
  WriteLn('按回车键退出...');
  ReadLn;
end.
