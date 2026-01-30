program HotspotOptimizationDemo;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  fafafa.core.mem;

var
  LTracker: TTrackingAllocator;
  LPtr: Pointer;
  I: Integer;

procedure SimulateRealisticWorkload;
begin
  WriteLn('=== 模拟真实工作负载 ===');
  
  LTracker := TTrackingAllocator.Create;
  try
    // 模拟常见的分配模式
    
    // 频繁的小对象分配 (64字节) - 模拟字符串或小结构体
    for I := 1 to 20 do
    begin
      LPtr := LTracker.GetMem(64);
      AnalyzeMemoryHotspots(64);
      AnalyzeMemoryFragmentation(64);
      TMemoryDiagnostics.RecordAllocationTime(0.001);
      LTracker.FreeMem(LPtr);
    end;
    
    // 中等频率的中等分配 (1024字节) - 模拟缓冲区
    for I := 1 to 10 do
    begin
      LPtr := LTracker.GetMem(1024);
      AnalyzeMemoryHotspots(1024);
      AnalyzeMemoryFragmentation(1024);
      TMemoryDiagnostics.RecordAllocationTime(0.002);
      LTracker.FreeMem(LPtr);
    end;
    
    // 少量的大分配 (8192字节) - 模拟大缓冲区
    for I := 1 to 3 do
    begin
      LPtr := LTracker.GetMem(8192);
      AnalyzeMemoryHotspots(8192);
      AnalyzeMemoryFragmentation(8192);
      TMemoryDiagnostics.RecordAllocationTime(0.005);
      LTracker.FreeMem(LPtr);
    end;
    
    // 一些其他大小的分配
    LPtr := LTracker.GetMem(256);
    AnalyzeMemoryHotspots(256);
    AnalyzeMemoryFragmentation(256);
    TMemoryDiagnostics.RecordAllocationTime(0.0015);
    LTracker.FreeMem(LPtr);
    
    LPtr := LTracker.GetMem(512);
    AnalyzeMemoryHotspots(512);
    AnalyzeMemoryFragmentation(512);
    TMemoryDiagnostics.RecordAllocationTime(0.0018);
    LTracker.FreeMem(LPtr);
    
    WriteLn('完成真实工作负载模拟');
    WriteLn('总分配次数: ', 20 + 10 + 3 + 1 + 1, ' 次');
  finally
    LTracker.Free;
  end;
  WriteLn;
end;

procedure SimulateHighFragmentationWorkload;
begin
  WriteLn('=== 模拟高碎片化工作负载 ===');
  
  LTracker := TTrackingAllocator.Create;
  try
    // 大量不同大小的小分配 - 产生高碎片化
    for I := 1 to 15 do
    begin
      LPtr := LTracker.GetMem(32 + (I * 8)); // 32, 40, 48, 56, ...
      AnalyzeMemoryHotspots(32 + (I * 8));
      AnalyzeMemoryFragmentation(32 + (I * 8));
      TMemoryDiagnostics.RecordAllocationTime(0.001 + (I * 0.0001));
      LTracker.FreeMem(LPtr);
    end;
    
    WriteLn('完成高碎片化工作负载模拟');
    WriteLn('产生了大量不同大小的小分配');
  finally
    LTracker.Free;
  end;
  WriteLn;
end;

begin
  WriteLn('=== 内存热点分析和优化建议演示 ===');
  WriteLn;

  // 初始化诊断系统
  InitializeMemoryDiagnostics;
  WriteLn('诊断系统已初始化');
  WriteLn;

  // 执行真实工作负载模拟
  SimulateRealisticWorkload;
  
  // 执行高碎片化工作负载模拟
  SimulateHighFragmentationWorkload;

  // 生成优化建议
  WriteLn('=== 生成优化建议 ===');
  GenerateMemoryOptimizationSuggestions;
  WriteLn('优化分析完成');
  WriteLn;

  // 显示热点分析
  WriteLn('=== 内存分配热点分析 ===');
  PrintMemoryHotspotAnalysis;
  WriteLn;

  // 显示优化建议
  WriteLn('=== 内存优化建议 ===');
  PrintMemoryOptimizationSuggestions;
  WriteLn;

  // 显示所有报告
  WriteLn('=== 完整诊断报告 ===');
  GenerateMemoryUsageReport;
  WriteLn;
  
  PrintMemoryFragmentationReport;
  WriteLn;
  
  PrintMemoryPerformanceReport;
  WriteLn;

  // 显示关键指标
  WriteLn('=== 关键优化指标 ===');
  WriteLn('优化评分: ', GetMemoryOptimizationScore:0:1, '/100.0');
  WriteLn('碎片比率: ', GetMemoryFragmentationRatio:0:3);
  WriteLn('内存效率: ', GetMemoryUsageEfficiency:0:1, '%');
  WriteLn('平均分配时间: ', TMemoryDiagnostics.GetAverageAllocationTime:0:6, ' ms');
  WriteLn;

  // 最终健康检查
  WriteLn('=== 最终系统评估 ===');
  if GetMemoryOptimizationScore >= 80 then
    WriteLn('系统状态: 优秀 - 内存管理非常高效')
  else if GetMemoryOptimizationScore >= 60 then
    WriteLn('系统状态: 良好 - 内存管理效率不错')
  else if GetMemoryOptimizationScore >= 40 then
    WriteLn('系统状态: 一般 - 建议进行优化')
  else
    WriteLn('系统状态: 需要优化 - 强烈建议采用优化建议');
    
  if CheckMemoryLeaks then
    WriteLn('内存泄漏: 检测到泄漏，请检查代码')
  else
    WriteLn('内存泄漏: 无泄漏检测，内存管理良好');
  WriteLn;

  // 清理诊断系统
  FinalizeMemoryDiagnostics;
  WriteLn('诊断系统已清理');
  WriteLn;
  WriteLn('=== 热点分析和优化建议演示完成 ===');
end.
