program MemoryDiagnosticsDemo;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  SysUtils,
  fafafa.core.mem;

var
  LTracker: TTrackingAllocator;
  LAligned: TAlignedAllocator;
  LPool: TFixedSizePool;
  LBuffer: TBufferPool;
  LPtr1, LPtr2, LPtr3: Pointer;
  LBufferInfo: TBufferInfo;
  LAllocatedSize, LAllocationCount, LPeakSize: SizeUInt;

begin
  WriteLn('=== 内存诊断系统演示 ===');
  WriteLn;

  // 初始化诊断系统
  InitializeMemoryDiagnostics;
  WriteLn('1. 诊断系统已初始化');
  PrintMemoryDiagnostics;
  WriteLn;

  // 创建各种分配器并进行分配
  WriteLn('2. 创建跟踪分配器并分配内存:');
  LTracker := TTrackingAllocator.Create;
  try
    LPtr1 := LTracker.GetMem(1024);
    LPtr2 := LTracker.GetMem(2048);
    WriteLn('   - 分配了 1024 + 2048 = 3072 字节');
    WriteLn('   - 跟踪分配器统计:');
    WriteLn('     * 已分配: ', LTracker.GetAllocatedSize, ' 字节');
    WriteLn('     * 分配次数: ', LTracker.GetAllocationCount);
    WriteLn('     * 峰值: ', LTracker.GetPeakAllocatedSize, ' 字节');
    
    LTracker.FreeMem(LPtr1);
    WriteLn('   - 释放 1024 字节后:');
    WriteLn('     * 已分配: ', LTracker.GetAllocatedSize, ' 字节');
    WriteLn('     * 峰值: ', LTracker.GetPeakAllocatedSize, ' 字节');
    
    LTracker.FreeMem(LPtr2);
  finally
    LTracker.Free;
  end;
  WriteLn;

  // 测试对齐分配器
  WriteLn('3. 创建对齐分配器并分配内存:');
  LAligned := TAlignedAllocator.Create(64);
  try
    LPtr1 := LAligned.GetMem(512);
    LPtr2 := LAligned.GetMem(1024);
    WriteLn('   - 分配了 512 + 1024 = 1536 字节 (64字节对齐)');
    WriteLn('   - 地址对齐检查:');
    WriteLn('     * Ptr1 对齐: ', (PtrUInt(LPtr1) mod 64 = 0));
    WriteLn('     * Ptr2 对齐: ', (PtrUInt(LPtr2) mod 64 = 0));
    
    LAligned.FreeMem(LPtr1);
    LAligned.FreeMem(LPtr2);
  finally
    LAligned.Free;
  end;
  WriteLn;

  // 测试固定大小内存池
  WriteLn('4. 创建固定大小内存池:');
  LPool := TFixedSizePool.Create(256, 5);
  try
    WriteLn('   - 创建 256字节 x 5块 内存池');
    WriteLn('   - 可用块数: ', LPool.AvailableCount);
    
    LPtr1 := LPool.GetMem(256);
    LPtr2 := LPool.GetMem(256);
    LPtr3 := LPool.GetMem(256);
    WriteLn('   - 分配 3 个块后可用块数: ', LPool.AvailableCount);
    WriteLn('   - 已分配块数: ', LPool.GetAllocatedCount);
    
    LPool.FreeMem(LPtr1);
    LPool.FreeMem(LPtr2);
    LPool.FreeMem(LPtr3);
    WriteLn('   - 释放后可用块数: ', LPool.AvailableCount);
  finally
    LPool.Free;
  end;
  WriteLn;

  // 测试缓冲区池
  WriteLn('5. 创建缓冲区池:');
  LBuffer := TBufferPool.Create(3);
  try
    WriteLn('   - 创建缓冲区池 (每桶最多3个缓冲区)');
    WriteLn('   - 初始状态: 总数=', LBuffer.TotalBuffers, ', 借出=', LBuffer.BorrowedBuffers);
    
    LBufferInfo := LBuffer.GetBuffer(1024);
    WriteLn('   - 获取 1024字节 缓冲区');
    WriteLn('   - 缓冲区容量: ', LBufferInfo.Capacity);
    WriteLn('   - 当前状态: 总数=', LBuffer.TotalBuffers, ', 借出=', LBuffer.BorrowedBuffers);
    
    LBuffer.ReturnBuffer(LBufferInfo);
    WriteLn('   - 归还缓冲区后: 总数=', LBuffer.TotalBuffers, ', 借出=', LBuffer.BorrowedBuffers);
  finally
    LBuffer.Free;
  end;
  WriteLn;

  // 获取全局统计信息
  WriteLn('6. 全局内存统计:');
  GetGlobalMemoryStats(LAllocatedSize, LAllocationCount, LPeakSize);
  WriteLn('   - 全局已分配: ', LAllocatedSize, ' 字节');
  WriteLn('   - 全局分配次数: ', LAllocationCount);
  WriteLn('   - 全局峰值: ', LPeakSize, ' 字节');
  WriteLn;

  // 打印完整诊断信息
  WriteLn('7. 完整诊断信息:');
  PrintMemoryDiagnostics;
  WriteLn;

  // 重置统计信息
  WriteLn('8. 重置全局统计:');
  TMemoryDiagnostics.ResetGlobalStats;
  PrintMemoryDiagnostics;
  WriteLn;

  // 清理诊断系统
  FinalizeMemoryDiagnostics;
  WriteLn('9. 诊断系统已清理');
  WriteLn;

  WriteLn('=== 内存诊断系统演示完成 ===');
end.
