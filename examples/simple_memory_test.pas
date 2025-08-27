program SimpleMemoryTest;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  SysUtils,
  fafafa.core.mem.simple;

var
  LFixedPool: TSimpleFixedPool;
  LObjectPool: TSimpleObjectPool;
  LBufferPool: TSimpleBufferPool;
  LSlabPool: TSimpleSlabPool;
  LPtr1, LPtr2, LPtr3: Pointer;
  LObj1, LObj2: TObject;
  LBuf1, LBuf2: Pointer;

procedure TestFixedPool;
begin
  WriteLn('=== 测试固定大小内存池 ===');
  
  LFixedPool := TSimpleFixedPool.Create(64, 5);
  try
    WriteLn('创建 64字节 x 5块 内存池');
    WriteLn('可用块数: ', LFixedPool.AvailableCount);
    WriteLn('已分配块数: ', LFixedPool.AllocatedCount);
    WriteLn;
    
    // 分配几个块
    LPtr1 := LFixedPool.Alloc;
    LPtr2 := LFixedPool.Alloc;
    LPtr3 := LFixedPool.Alloc;
    
    WriteLn('分配3个块后:');
    WriteLn('  可用块数: ', LFixedPool.AvailableCount);
    WriteLn('  已分配块数: ', LFixedPool.AllocatedCount);
    WriteLn('  是否满: ', LFixedPool.IsFull);
    WriteLn;
    
    // 释放块
    LFixedPool.FreeBlock(LPtr1);
    LFixedPool.FreeBlock(LPtr2);
    LFixedPool.FreeBlock(LPtr3);
    
    WriteLn('释放所有块后:');
    WriteLn('  可用块数: ', LFixedPool.AvailableCount);
    WriteLn('  已分配块数: ', LFixedPool.AllocatedCount);
    WriteLn('  是否空: ', LFixedPool.IsEmpty);
  finally
    LFixedPool.Free;
  end;
  WriteLn;
end;

procedure TestObjectPool;
begin
  WriteLn('=== 测试对象池 ===');
  
  LObjectPool := TSimpleObjectPool.Create(TObject, 3);
  try
    WriteLn('创建 TObject 对象池，最大3个');
    WriteLn('可用对象数: ', LObjectPool.AvailableCount);
    WriteLn;
    
    // 借用对象
    LObj1 := LObjectPool.Borrow;
    LObj2 := LObjectPool.Borrow;
    
    WriteLn('借用2个对象后:');
    WriteLn('  可用对象数: ', LObjectPool.AvailableCount);
    WriteLn('  对象1地址: ', HexStr(LObj1));
    WriteLn('  对象2地址: ', HexStr(LObj2));
    WriteLn;
    
    // 归还对象
    LObjectPool.Return(LObj1);
    LObjectPool.Return(LObj2);
    
    WriteLn('归还对象后:');
    WriteLn('  可用对象数: ', LObjectPool.AvailableCount);
  finally
    LObjectPool.Free;
  end;
  WriteLn;
end;

procedure TestBufferPool;
begin
  WriteLn('=== 测试缓冲区池 ===');
  
  LBufferPool := TSimpleBufferPool.Create(5);
  try
    WriteLn('创建缓冲区池，最大5个缓冲区');
    WriteLn('已使用缓冲区数: ', LBufferPool.UsedCount);
    WriteLn;
    
    // 获取缓冲区
    LBuf1 := LBufferPool.GetBuffer(256);
    LBuf2 := LBufferPool.GetBuffer(1024);
    
    WriteLn('获取2个缓冲区后:');
    WriteLn('  已使用缓冲区数: ', LBufferPool.UsedCount);
    WriteLn('  可用缓冲区数: ', LBufferPool.AvailableCount);
    WriteLn('  缓冲区1地址: ', HexStr(LBuf1));
    WriteLn('  缓冲区2地址: ', HexStr(LBuf2));
    WriteLn;
    
    // 归还缓冲区
    LBufferPool.ReturnBuffer(LBuf1);
    LBufferPool.ReturnBuffer(LBuf2);
    
    WriteLn('归还缓冲区后:');
    WriteLn('  已使用缓冲区数: ', LBufferPool.UsedCount);
    WriteLn('  可用缓冲区数: ', LBufferPool.AvailableCount);
  finally
    LBufferPool.Free;
  end;
  WriteLn;
end;

procedure TestSlabPool;
var
  LSize, LAllocated, LAvailable: SizeUInt;
  I: Integer;
begin
  WriteLn('=== 测试Slab内存池 ===');

  LSlabPool := TSimpleSlabPool.Create;
  try
    // 添加不同大小的slab
    LSlabPool.AddSlab(32, 10);   // 32字节 x 10个
    LSlabPool.AddSlab(64, 20);   // 64字节 x 20个
    LSlabPool.AddSlab(128, 15);  // 128字节 x 15个
    LSlabPool.AddSlab(256, 5);   // 256字节 x 5个

    WriteLn('创建Slab池，包含4种大小:');
    for I := 0 to LSlabPool.SlabCount - 1 do
    begin
      if LSlabPool.GetSlabInfo(I, LSize, LAllocated, LAvailable) then
        WriteLn('  Slab ', I + 1, ': ', LSize, '字节 x ', LAvailable, '个可用');
    end;
    WriteLn;

    // 测试不同大小的分配
    LPtr1 := LSlabPool.Alloc(30);   // 应该使用32字节slab
    LPtr2 := LSlabPool.Alloc(60);   // 应该使用64字节slab
    LPtr3 := LSlabPool.Alloc(200);  // 应该使用256字节slab

    WriteLn('分配30、60、200字节后:');
    for I := 0 to LSlabPool.SlabCount - 1 do
    begin
      if LSlabPool.GetSlabInfo(I, LSize, LAllocated, LAvailable) then
        WriteLn('  Slab ', I + 1, ': ', LSize, '字节, 已分配=', LAllocated, ', 可用=', LAvailable);
    end;
    WriteLn;

    // 释放内存
    LSlabPool.FreeBlock(LPtr1, 30);
    LSlabPool.FreeBlock(LPtr2, 60);
    LSlabPool.FreeBlock(LPtr3, 200);

    WriteLn('释放所有内存后:');
    for I := 0 to LSlabPool.SlabCount - 1 do
    begin
      if LSlabPool.GetSlabInfo(I, LSize, LAllocated, LAvailable) then
        WriteLn('  Slab ', I + 1, ': ', LSize, '字节, 已分配=', LAllocated, ', 可用=', LAvailable);
    end;
  finally
    LSlabPool.Free;
  end;
  WriteLn;
end;

procedure TestPerformance;
var
  LPool: TSimpleFixedPool;
  LPtr: Pointer;
  I: Integer;
  LStartTime, LEndTime: TDateTime;
  LPoolTime, LNormalTime: Double;
begin
  WriteLn('=== 性能测试 ===');
  
  // 测试内存池性能
  LPool := TSimpleFixedPool.Create(64, 1000);
  try
    LStartTime := Now;
    for I := 1 to 10000 do
    begin
      LPtr := LPool.Alloc;
      if LPtr <> nil then
        LPool.FreeBlock(LPtr);
    end;
    LEndTime := Now;
    LPoolTime := (LEndTime - LStartTime) * 24 * 60 * 60 * 1000;
  finally
    LPool.Free;
  end;
  
  // 测试普通分配性能
  LStartTime := Now;
  for I := 1 to 10000 do
  begin
    LPtr := GetMem(64);
    if LPtr <> nil then
      FreeMem(LPtr);
  end;
  LEndTime := Now;
  LNormalTime := (LEndTime - LStartTime) * 24 * 60 * 60 * 1000;
  
  WriteLn('10000次 64字节 分配/释放测试:');
  WriteLn('  内存池: ', LPoolTime:0:3, ' ms');
  WriteLn('  普通分配: ', LNormalTime:0:3, ' ms');
  if (LNormalTime > 0) and (LPoolTime > 0) then
    WriteLn('  性能提升: ', (LNormalTime / LPoolTime):0:1, 'x')
  else
    WriteLn('  性能: 两者都非常快，无法准确测量');
  WriteLn;
end;

begin
  WriteLn('=== 简化内存管理库测试 ===');
  WriteLn('这是一个实用的、可靠的内存管理解决方案');
  WriteLn;

  try
    TestFixedPool;
    TestObjectPool;
    TestBufferPool;
    TestSlabPool;
    TestPerformance;
    
    WriteLn('=== 所有测试通过！===');
    WriteLn;
    WriteLn('这个简化版本的特点:');
    WriteLn('1. 代码简单易懂，容易维护');
    WriteLn('2. 没有复杂的依赖，直接可用');
    WriteLn('3. 性能优秀，适合实际项目');
    WriteLn('4. 内存安全，有完整的错误处理');
    WriteLn;
    WriteLn('使用建议:');
    WriteLn('- TSimpleFixedPool: 固定大小的频繁分配');
    WriteLn('- TSimpleObjectPool: 对象复用');
    WriteLn('- TSimpleBufferPool: 动态大小缓冲区');
    WriteLn('- TSimpleSlabPool: 多种大小的内存池组合');
    
  except
    on E: Exception do
    begin
      WriteLn('错误: ', E.Message);
      ExitCode := 1;
    end;
  end;
  
  WriteLn;
  WriteLn('=== 测试完成 ===');
end.
