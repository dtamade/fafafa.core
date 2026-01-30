program OverloadedConstructorsDemo;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  SysUtils,
  fafafa.core.mem;

var
  LDefaultAllocator: IAllocator;
  LCustomTracker: TTrackingAllocator;
  LCustomAligned: TAlignedAllocator;
  LCustomPool: TFixedSizePool;
  LCustomBuffer: TBufferPool;
  LPtr: Pointer;
  LBuffer: TBufferInfo;

begin
  WriteLn('=== 重载构造函数演示 ===');
  WriteLn;

  // 获取默认分配器
  LDefaultAllocator := GetRtlAllocator;
  WriteLn('获取默认 RTL 分配器: ', HexStr(LDefaultAllocator));
  WriteLn;

  // 1. TTrackingAllocator 重载构造函数演示
  WriteLn('1. TTrackingAllocator 重载构造函数:');
  
  // 使用指定的分配器创建跟踪分配器
  LCustomTracker := TTrackingAllocator.Create(LDefaultAllocator);
  try
    WriteLn('   - 使用自定义分配器创建跟踪分配器成功');
    
    // 测试分配
    LPtr := LCustomTracker.GetMem(1024);
    WriteLn('   - 分配 1024 字节: ', HexStr(LPtr));
    WriteLn('   - 当前分配大小: ', LCustomTracker.GetAllocatedSize);
    WriteLn('   - 分配次数: ', LCustomTracker.GetAllocationCount);

    LCustomTracker.FreeMem(LPtr);
    WriteLn('   - 释放后分配大小: ', LCustomTracker.GetAllocatedSize);
  finally
    LCustomTracker.Free;
  end;
  WriteLn;

  // 2. TAlignedAllocator 重载构造函数演示
  WriteLn('2. TAlignedAllocator 重载构造函数:');
  
  // 使用指定的分配器和对齐值创建对齐分配器
  LCustomAligned := TAlignedAllocator.Create(LDefaultAllocator, 64);
  try
    WriteLn('   - 使用自定义分配器创建 64 字节对齐分配器成功');
    WriteLn('   - 对齐值: ', LCustomAligned.Alignment);
    
    // 测试对齐分配
    LPtr := LCustomAligned.GetMem(100);
    WriteLn('   - 分配 100 字节: ', HexStr(LPtr));
    WriteLn('   - 地址对齐检查: ', (PtrUInt(LPtr) mod 64 = 0));
    
    LCustomAligned.FreeMem(LPtr);
  finally
    LCustomAligned.Free;
  end;
  WriteLn;

  // 3. TFixedSizePool 重载构造函数演示
  WriteLn('3. TFixedSizePool 重载构造函数:');
  
  // 使用指定的分配器创建固定大小内存池
  LCustomPool := TFixedSizePool.Create(LDefaultAllocator, 128, 10);
  try
    WriteLn('   - 使用自定义分配器创建 128 字节 x 10 块内存池成功');
    WriteLn('   - 块大小: ', LCustomPool.BlockSize);
    WriteLn('   - 块数量: ', LCustomPool.BlockCount);
    WriteLn('   - 可用块数: ', LCustomPool.AvailableCount);
    
    // 测试分配
    LPtr := LCustomPool.GetMem(128);
    WriteLn('   - 分配一个块: ', HexStr(LPtr));
    WriteLn('   - 分配后可用块数: ', LCustomPool.AvailableCount);

    LCustomPool.FreeMem(LPtr);
    WriteLn('   - 释放后可用块数: ', LCustomPool.AvailableCount);
  finally
    LCustomPool.Free;
  end;
  WriteLn;

  // 4. TBufferPool 重载构造函数演示
  WriteLn('4. TBufferPool 重载构造函数:');
  
  // 使用指定的分配器创建缓冲区池
  LCustomBuffer := TBufferPool.Create(LDefaultAllocator, 3);
  try
    WriteLn('   - 使用自定义分配器创建缓冲区池成功');
    WriteLn('   - 每桶最大缓冲区数: ', LCustomBuffer.MaxBuffersPerBucket);
    WriteLn('   - 总缓冲区数: ', LCustomBuffer.TotalBuffers);
    
    // 测试缓冲区分配
    LBuffer := LCustomBuffer.GetBuffer(256);
    WriteLn('   - 获取 256 字节缓冲区: ', HexStr(LBuffer.Buffer));
    WriteLn('   - 缓冲区容量: ', LBuffer.Capacity);
    WriteLn('   - 借出缓冲区数: ', LCustomBuffer.BorrowedBuffers);
    
    LCustomBuffer.ReturnBuffer(LBuffer);
    WriteLn('   - 归还后借出数: ', LCustomBuffer.BorrowedBuffers);
    WriteLn('   - 归还后总数: ', LCustomBuffer.TotalBuffers);
  finally
    LCustomBuffer.Free;
  end;
  WriteLn;

  WriteLn('=== 所有重载构造函数演示完成 ===');
end.
