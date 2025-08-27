program AdvancedDiagnosticsDemo;

{$mode objfpc}{$H+}

uses
  SysUtils, DateUtils,
  fafafa.core.mem;

var
  LTracker: TTrackingAllocator;
  LPool: TFixedSizePool;
  LAligned: TAlignedAllocator;
  LPtr1, LPtr2, LPtr3: Pointer;
  LStartTime, LEndTime: TDateTime;
  LElapsedMs: Double;

procedure SimulateFragmentedWorkload;
begin
  WriteLn('=== 模拟内存碎片化工作负载 ===');
  
  LTracker := TTrackingAllocator.Create;
  try
    // 模拟各种大小的分配以产生碎片
    
    // 小分配 (< 256 bytes)
    LStartTime := Now;
    LPtr1 := LTracker.GetMem(64);
    LEndTime := Now;
    LElapsedMs := MilliSecondsBetween(LEndTime, LStartTime);
    TMemoryDiagnostics.RecordAllocationTime(LElapsedMs);
    AnalyzeMemoryFragmentation(64);
    
    LStartTime := Now;
    LPtr2 := LTracker.GetMem(128);
    LEndTime := Now;
    LElapsedMs := MilliSecondsBetween(LEndTime, LStartTime);
    TMemoryDiagnostics.RecordAllocationTime(LElapsedMs);
    AnalyzeMemoryFragmentation(128);
    
    // 中等分配 (256-4096 bytes)
    LStartTime := Now;
    LPtr3 := LTracker.GetMem(1024);
    LEndTime := Now;
    LElapsedMs := MilliSecondsBetween(LEndTime, LStartTime);
    TMemoryDiagnostics.RecordAllocationTime(LElapsedMs);
    AnalyzeMemoryFragmentation(1024);
    
    // 大分配 (> 4096 bytes)
    LTracker.FreeMem(LPtr1);
    LStartTime := Now;
    LPtr1 := LTracker.GetMem(8192);
    LEndTime := Now;
    LElapsedMs := MilliSecondsBetween(LEndTime, LStartTime);
    TMemoryDiagnostics.RecordAllocationTime(LElapsedMs);
    AnalyzeMemoryFragmentation(8192);
    
    WriteLn('完成碎片化工作负载模拟');
    WriteLn('当前分配: ', LTracker.GetAllocatedSize, ' 字节');
    WriteLn('分配次数: ', LTracker.GetAllocationCount);
    
    // 清理
    LTracker.FreeMem(LPtr1);
    LTracker.FreeMem(LPtr2);
    LTracker.FreeMem(LPtr3);
  finally
    LTracker.Free;
  end;
  WriteLn;
end;

procedure SimulateHighPerformanceWorkload;
var
  I: Integer;
  LPtrs: array[0..99] of Pointer;
begin
  WriteLn('=== 模拟高性能工作负载 ===');
  
  LPool := TFixedSizePool.Create(256, 100);
  try
    // 快速分配和释放
    LStartTime := Now;
    for I := 0 to 99 do
    begin
      LPtrs[I] := LPool.GetMem(256);
      AnalyzeMemoryFragmentation(256);
    end;
    LEndTime := Now;
    LElapsedMs := MilliSecondsBetween(LEndTime, LStartTime);
    TMemoryDiagnostics.RecordAllocationTime(LElapsedMs / 100); // 平均每次分配时间
    
    WriteLn('快速分配 100 个 256 字节块');
    WriteLn('总时间: ', LElapsedMs:0:3, ' ms');
    WriteLn('平均每次: ', (LElapsedMs / 100):0:6, ' ms');
    
    // 快速释放
    for I := 0 to 99 do
      LPool.FreeMem(LPtrs[I]);
      
    WriteLn('所有内存已释放');
  finally
    LPool.Free;
  end;
  WriteLn;
end;

procedure SimulateAlignedWorkload;
begin
  WriteLn('=== 模拟对齐内存工作负载 ===');
  
  LAligned := TAlignedAllocator.Create(64);
  try
    // 对齐分配
    LStartTime := Now;
    LPtr1 := LAligned.GetMem(512);
    LEndTime := Now;
    LElapsedMs := MilliSecondsBetween(LEndTime, LStartTime);
    TMemoryDiagnostics.RecordAllocationTime(LElapsedMs);
    AnalyzeMemoryFragmentation(512);
    
    LStartTime := Now;
    LPtr2 := LAligned.GetMem(2048);
    LEndTime := Now;
    LElapsedMs := MilliSecondsBetween(LEndTime, LStartTime);
    TMemoryDiagnostics.RecordAllocationTime(LElapsedMs);
    AnalyzeMemoryFragmentation(2048);
    
    WriteLn('分配了对齐内存: 512 + 2048 = 2560 字节');
    WriteLn('对齐要求: 64 字节');
    WriteLn('地址对齐检查:');
    WriteLn('  Ptr1: ', (PtrUInt(LPtr1) mod 64 = 0));
    WriteLn('  Ptr2: ', (PtrUInt(LPtr2) mod 64 = 0));
    
    // 清理
    LAligned.FreeMem(LPtr1);
    LAligned.FreeMem(LPtr2);
  finally
    LAligned.Free;
  end;
  WriteLn;
end;

begin
  WriteLn('=== 高级内存诊断系统演示 ===');
  WriteLn;

  // 初始化诊断系统
  InitializeMemoryDiagnostics;
  WriteLn('诊断系统已初始化');
  WriteLn;

  // 执行各种工作负载
  SimulateFragmentedWorkload;
  SimulateHighPerformanceWorkload;
  SimulateAlignedWorkload;

  // 生成完整报告
  WriteLn('=== 完整内存使用报告 ===');
  GenerateMemoryUsageReport;
  WriteLn;

  // 碎片分析报告
  WriteLn('=== 内存碎片分析报告 ===');
  PrintMemoryFragmentationReport;
  WriteLn;

  // 性能分析报告
  WriteLn('=== 内存性能分析报告 ===');
  PrintMemoryPerformanceReport;
  WriteLn;

  // 显示关键指标
  WriteLn('=== 关键性能指标 ===');
  WriteLn('内存碎片比率: ', GetMemoryFragmentationRatio:0:3);
  WriteLn('内存使用效率: ', GetMemoryUsageEfficiency:0:1, '%');
  WriteLn('系统运行时间: ', TMemoryDiagnostics.GetUptime:0:3, ' 秒');
  WriteLn('分配速率: ', TMemoryDiagnostics.GetAllocationRate:0:2, ' 分配/秒');
  WriteLn;

  // 最终健康检查
  WriteLn('=== 最终系统健康检查 ===');
  if CheckMemoryLeaks then
  begin
    WriteLn('警告: 检测到内存泄漏!');
    PrintMemoryLeakReport;
  end
  else
  begin
    WriteLn('优秀: 没有检测到内存泄漏!');
    WriteLn('系统内存管理健康状况良好。');
  end;
  WriteLn;

  // 清理诊断系统
  FinalizeMemoryDiagnostics;
  WriteLn('诊断系统已清理');
  WriteLn;
  WriteLn('=== 高级诊断演示完成 ===');
end.
