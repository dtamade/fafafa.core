program MemoryLeakDetectionDemo;

{$mode objfpc}{$H+}

uses
  fafafa.core.mem;

var
  LTracker: TTrackingAllocator;
  LPtr1, LPtr2, LPtr3: Pointer;

procedure TestNoLeaks;
begin
  WriteLn('=== 测试无内存泄漏场景 ===');
  
  LTracker := TTrackingAllocator.Create;
  try
    // 分配一些内存
    LPtr1 := LTracker.GetMem(1024);
    LPtr2 := LTracker.GetMem(512);
    LPtr3 := LTracker.GetMem(256);
    
    WriteLn('分配了 3 块内存: 1024 + 512 + 256 = 1792 字节');
    WriteLn('当前分配: ', LTracker.GetAllocatedSize, ' 字节');
    
    // 正确释放所有内存
    LTracker.FreeMem(LPtr1);
    LTracker.FreeMem(LPtr2);
    LTracker.FreeMem(LPtr3);
    
    WriteLn('释放所有内存后: ', LTracker.GetAllocatedSize, ' 字节');
  finally
    LTracker.Free;
  end;
  
  // 检查泄漏
  if CheckMemoryLeaks then
    WriteLn('检测到内存泄漏!')
  else
    WriteLn('没有检测到内存泄漏 - 很好!');
    
  PrintMemoryLeakReport;
  WriteLn;
end;

procedure TestWithLeaks;
begin
  WriteLn('=== 测试有内存泄漏场景 ===');
  
  LTracker := TTrackingAllocator.Create;
  try
    // 分配一些内存
    LPtr1 := LTracker.GetMem(2048);
    LPtr2 := LTracker.GetMem(1024);
    LPtr3 := LTracker.GetMem(512);
    
    WriteLn('分配了 3 块内存: 2048 + 1024 + 512 = 3584 字节');
    WriteLn('当前分配: ', LTracker.GetAllocatedSize, ' 字节');
    
    // 故意只释放部分内存，模拟泄漏
    LTracker.FreeMem(LPtr1);
    WriteLn('只释放了第一块内存，剩余: ', LTracker.GetAllocatedSize, ' 字节');
    
    // 注意：LPtr2 和 LPtr3 没有被释放，这会造成泄漏
  finally
    LTracker.Free;
  end;
  
  // 检查泄漏
  if CheckMemoryLeaks then
    WriteLn('检测到内存泄漏!')
  else
    WriteLn('没有检测到内存泄漏');
    
  PrintMemoryLeakReport;
  WriteLn;
end;

procedure TestComplexScenario;
var
  LPool: TFixedSizePool;
  LBuffer: TBufferPool;
  LAligned: TAlignedAllocator;
  LPoolPtr: Pointer;
  LBufferInfo: TBufferInfo;
  LAlignedPtr: Pointer;
begin
  WriteLn('=== 测试复杂场景 ===');
  
  // 使用多种分配器
  LPool := TFixedSizePool.Create(128, 5);
  LBuffer := TBufferPool.Create(3);
  LAligned := TAlignedAllocator.Create(64);
  
  try
    // 从不同分配器分配内存
    LPoolPtr := LPool.GetMem(128);
    LBufferInfo := LBuffer.GetBuffer(256);
    LAlignedPtr := LAligned.GetMem(512);
    
    WriteLn('从多个分配器分配了内存');
    WriteLn('固定池: 128 字节');
    WriteLn('缓冲池: ', LBufferInfo.Capacity, ' 字节容量');
    WriteLn('对齐分配器: 512 字节');
    
    // 正确清理
    LPool.FreeMem(LPoolPtr);
    LBuffer.ReturnBuffer(LBufferInfo);
    LAligned.FreeMem(LAlignedPtr);
    
    WriteLn('所有内存已正确释放');
  finally
    LPool.Free;
    LBuffer.Free;
    LAligned.Free;
  end;
  
  // 检查泄漏
  if CheckMemoryLeaks then
    WriteLn('检测到内存泄漏!')
  else
    WriteLn('没有检测到内存泄漏 - 很好!');
    
  PrintMemoryLeakReport;
  WriteLn;
end;

begin
  WriteLn('=== 内存泄漏检测系统演示 ===');
  WriteLn;

  // 初始化诊断系统
  InitializeMemoryDiagnostics;
  WriteLn('诊断系统已初始化');
  WriteLn;

  // 测试无泄漏场景
  TestNoLeaks;
  
  // 重置统计以便下一个测试
  TMemoryDiagnostics.ResetGlobalStats;
  
  // 测试有泄漏场景
  TestWithLeaks;
  
  // 重置统计以便下一个测试
  TMemoryDiagnostics.ResetGlobalStats;
  
  // 测试复杂场景
  TestComplexScenario;

  // 最终检查
  WriteLn('=== 最终内存状态检查 ===');
  if CheckMemoryLeaks then
  begin
    WriteLn('警告: 检测到内存泄漏!');
    PrintMemoryLeakReport;
  end
  else
  begin
    WriteLn('优秀: 没有检测到内存泄漏!');
    PrintMemoryLeakReport;
  end;

  // 清理诊断系统
  FinalizeMemoryDiagnostics;
  WriteLn;
  WriteLn('=== 内存泄漏检测演示完成 ===');
end.
