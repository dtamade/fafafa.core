program SimpleAdvancedTest;

{$mode objfpc}{$H+}

uses
  fafafa.core.mem;

var
  LTracker: TTrackingAllocator;
  LPtr: Pointer;

begin
  // 初始化诊断系统
  InitializeMemoryDiagnostics;
  
  // 创建跟踪分配器
  LTracker := TTrackingAllocator.Create;
  try
    // 测试小分配
    LPtr := LTracker.GetMem(128);
    AnalyzeMemoryFragmentation(128);
    TMemoryDiagnostics.RecordAllocationTime(0.001);
    LTracker.FreeMem(LPtr);
    
    // 测试大分配
    LPtr := LTracker.GetMem(8192);
    AnalyzeMemoryFragmentation(8192);
    TMemoryDiagnostics.RecordAllocationTime(0.005);
    LTracker.FreeMem(LPtr);
  finally
    LTracker.Free;
  end;
  
  // 生成报告（简化版）
  PrintMemoryFragmentationReport;
  PrintMemoryPerformanceReport;
  
  // 清理诊断系统
  FinalizeMemoryDiagnostics;
end.
