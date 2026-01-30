program PracticalMemoryPoolsDemo;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  SysUtils,
  fafafa.core.mem;

var
  // 实用的内存池示例
  LNodePool: TFixedSizePool;      // 用于链表节点
  LStringPool: TFixedSizePool;    // 用于小字符串缓冲区
  LObjectPool: TObjectPool;       // 用于对象复用
  LBufferPool: TBufferPool;       // 用于动态缓冲区
  
  // 测试指针
  LNode1, LNode2, LNode3: Pointer;
  LStr1, LStr2: Pointer;
  LObj1, LObj2: TObject;
  LBuffer1, LBuffer2: TBufferInfo;

procedure DemoFixedSizePool;
begin
  WriteLn('=== 固定大小内存池演示 ===');
  WriteLn('用途：链表节点、小对象等固定大小的频繁分配');
  WriteLn;
  
  // 创建一个用于64字节节点的内存池
  LNodePool := TFixedSizePool.Create(64, 10);
  try
    WriteLn('创建64字节 x 10个节点的内存池');
    WriteLn('可用块数: ', LNodePool.AvailableCount);
    WriteLn;
    
    // 分配几个节点
    LNode1 := LNodePool.GetMem(64);
    LNode2 := LNodePool.GetMem(64);
    LNode3 := LNodePool.GetMem(64);
    
    WriteLn('分配3个节点后:');
    WriteLn('  可用块数: ', LNodePool.AvailableCount);
    WriteLn('  已分配块数: ', LNodePool.GetAllocatedCount);
    WriteLn;
    
    // 释放节点
    LNodePool.FreeMem(LNode1);
    LNodePool.FreeMem(LNode2);
    LNodePool.FreeMem(LNode3);
    
    WriteLn('释放所有节点后:');
    WriteLn('  可用块数: ', LNodePool.AvailableCount);
    WriteLn('  已分配块数: ', LNodePool.GetAllocatedCount);
  finally
    LNodePool.Free;
  end;
  WriteLn;
end;

procedure DemoObjectPool;
begin
  WriteLn('=== 对象池演示 ===');
  WriteLn('用途：频繁创建和销毁的对象复用');
  WriteLn;
  
  // 创建对象池
  LObjectPool := TObjectPool.Create(TObject, 5);
  try
    WriteLn('创建TObject对象池，容量5个');
    WriteLn('池中对象数: ', LObjectPool.GetPoolCount);
    WriteLn;

    // 借用对象
    LObj1 := LObjectPool.Borrow;
    LObj2 := LObjectPool.Borrow;

    WriteLn('借用2个对象后:');
    WriteLn('  池中对象数: ', LObjectPool.GetPoolCount);
    WriteLn('  借出对象数: ', LObjectPool.GetBorrowedCount);
    WriteLn('  对象1地址: ', HexStr(LObj1));
    WriteLn('  对象2地址: ', HexStr(LObj2));
    WriteLn;

    // 归还对象
    LObjectPool.Return(LObj1);
    LObjectPool.Return(LObj2);

    WriteLn('归还对象后:');
    WriteLn('  池中对象数: ', LObjectPool.GetPoolCount);
    WriteLn('  借出对象数: ', LObjectPool.GetBorrowedCount);
  finally
    LObjectPool.Free;
  end;
  WriteLn;
end;

procedure DemoBufferPool;
begin
  WriteLn('=== 缓冲区池演示 ===');
  WriteLn('用途：动态大小的缓冲区管理，如字符串、数组等');
  WriteLn;
  
  // 创建缓冲区池
  LBufferPool := TBufferPool.Create(3);
  try
    WriteLn('创建缓冲区池，每桶最多3个缓冲区');
    WriteLn('总缓冲区数: ', LBufferPool.TotalBuffers);
    WriteLn;
    
    // 获取不同大小的缓冲区
    LBuffer1 := LBufferPool.GetBuffer(256);
    LBuffer2 := LBufferPool.GetBuffer(1024);
    
    WriteLn('获取缓冲区后:');
    WriteLn('  缓冲区1: ', LBuffer1.Capacity, ' 字节');
    WriteLn('  缓冲区2: ', LBuffer2.Capacity, ' 字节');
    WriteLn('  借出缓冲区数: ', LBufferPool.BorrowedBuffers);
    WriteLn('  总缓冲区数: ', LBufferPool.TotalBuffers);
    WriteLn;
    
    // 归还缓冲区
    LBufferPool.ReturnBuffer(LBuffer1);
    LBufferPool.ReturnBuffer(LBuffer2);
    
    WriteLn('归还缓冲区后:');
    WriteLn('  借出缓冲区数: ', LBufferPool.BorrowedBuffers);
    WriteLn('  总缓冲区数: ', LBufferPool.TotalBuffers);
  finally
    LBufferPool.Free;
  end;
  WriteLn;
end;

procedure DemoPerformanceComparison;
var
  LTracker: TTrackingAllocator;
  LPool: TFixedSizePool;
  LPtr: Pointer;
  I: Integer;
  LStartTime, LEndTime: TDateTime;
  LNormalTime, LPoolTime: Double;
begin
  WriteLn('=== 性能对比演示 ===');
  WriteLn('对比普通分配器 vs 内存池的性能');
  WriteLn;
  
  // 测试普通分配器
  LTracker := TTrackingAllocator.Create;
  try
    LStartTime := Now;
    for I := 1 to 1000 do
    begin
      LPtr := LTracker.GetMem(64);
      LTracker.FreeMem(LPtr);
    end;
    LEndTime := Now;
    LNormalTime := (LEndTime - LStartTime) * 24 * 60 * 60 * 1000; // 毫秒
  finally
    LTracker.Free;
  end;
  
  // 测试内存池
  LPool := TFixedSizePool.Create(64, 100);
  try
    LStartTime := Now;
    for I := 1 to 1000 do
    begin
      LPtr := LPool.GetMem(64);
      LPool.FreeMem(LPtr);
    end;
    LEndTime := Now;
    LPoolTime := (LEndTime - LStartTime) * 24 * 60 * 60 * 1000; // 毫秒
  finally
    LPool.Free;
  end;
  
  WriteLn('1000次 64字节 分配/释放测试:');
  WriteLn('  普通分配器: ', LNormalTime:0:3, ' ms');
  WriteLn('  内存池:     ', LPoolTime:0:3, ' ms');
  if LNormalTime > 0 then
    WriteLn('  性能提升:   ', (LNormalTime / LPoolTime):0:1, 'x');
  WriteLn;
end;

begin
  WriteLn('=== 实用内存池演示 ===');
  WriteLn('展示真正有用的内存管理功能');
  WriteLn;

  // 演示各种内存池
  DemoFixedSizePool;
  DemoObjectPool;
  DemoBufferPool;
  DemoPerformanceComparison;

  WriteLn('=== 实用建议 ===');
  WriteLn('1. 对于固定大小的频繁分配（如链表节点），使用 TFixedSizePool');
  WriteLn('2. 对于对象的频繁创建销毁，使用 TObjectPool');
  WriteLn('3. 对于动态大小的缓冲区，使用 TBufferPool');
  WriteLn('4. 对于需要对齐的内存，使用 TAlignedAllocator');
  WriteLn('5. 对于需要统计内存使用，使用 TTrackingAllocator');
  WriteLn;
  WriteLn('=== 演示完成 ===');
end.
