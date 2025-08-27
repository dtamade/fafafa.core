program SimpleMemoryReport;

{$mode objfpc}{$H+}

uses
  fafafa.core.mem;

var
  LTracker: TTrackingAllocator;
  LPtr: Pointer;

begin
  // 初始化诊断系统
  InitializeMemoryDiagnostics;
  
  // 创建跟踪分配器并分配一些内存
  LTracker := TTrackingAllocator.Create;
  try
    LPtr := LTracker.GetMem(1024);
    TMemoryDiagnostics.RecordAllocation(1024);
    
    // 生成内存使用报告
    GenerateMemoryUsageReport;
    
    // 释放内存
    LTracker.FreeMem(LPtr);
  finally
    LTracker.Free;
  end;
  
  // 检查泄漏
  if CheckMemoryLeaks then
    PrintMemoryLeakReport;
  
  // 清理诊断系统
  FinalizeMemoryDiagnostics;
end.
