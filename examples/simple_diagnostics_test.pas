program SimpleDiagnosticsTest;

{$mode objfpc}{$H+}

uses
  fafafa.core.mem;

var
  LTracker: TTrackingAllocator;
  LPtr: Pointer;

begin
  // 测试诊断系统基本功能
  InitializeMemoryDiagnostics;
  
  // 创建跟踪分配器
  LTracker := TTrackingAllocator.Create;
  try
    // 分配内存
    LPtr := LTracker.GetMem(1024);
    
    // 释放内存
    LTracker.FreeMem(LPtr);
  finally
    LTracker.Free;
  end;
  
  // 清理诊断系统
  FinalizeMemoryDiagnostics;
end.
