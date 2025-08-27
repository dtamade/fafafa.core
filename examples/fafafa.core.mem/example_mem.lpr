{$CODEPAGE UTF8}
program example_mem;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.mem;

{**
 * 演示 fafafa.core.mem 模块的基本使用
 * Demonstrates basic usage of fafafa.core.mem module
 *}

procedure DemoMemoryOperations;
var
  LBuffer1, LBuffer2: Pointer;
  LSize: SizeUInt;
begin
  WriteLn('=== 内存操作演示 Memory Operations Demo ===');
  
  LSize := 256;
  LBuffer1 := GetMem(LSize);
  LBuffer2 := GetMem(LSize);
  
  try
    WriteLn('1. 分配了两个 ', LSize, ' 字节的内存块');
    WriteLn('   Allocated two memory blocks of ', LSize, ' bytes');
    
    // 填充内存
    Fill(LBuffer1, LSize, $AA);
    WriteLn('2. 用 $AA 填充第一个内存块');
    WriteLn('   Filled first buffer with $AA');
    
    // 复制内存
    Copy(LBuffer1, LBuffer2, LSize);
    WriteLn('3. 将第一个内存块复制到第二个');
    WriteLn('   Copied first buffer to second');
    
    // 比较内存
    if Equal(LBuffer1, LBuffer2, LSize) then
    begin
      WriteLn('4. ✓ 两个内存块内容相同');
      WriteLn('   ✓ Both buffers have identical content');
    end
    else
    begin
      WriteLn('4. ✗ 内存块内容不同');
      WriteLn('   ✗ Buffers have different content');
    end;
    
    // 清零第一个内存块
    Zero(LBuffer1, LSize);
    WriteLn('5. 清零第一个内存块');
    WriteLn('   Zeroed first buffer');
    
    // 再次比较
    if not Equal(LBuffer1, LBuffer2, LSize) then
    begin
      WriteLn('6. ✓ 清零后两个内存块内容不同');
      WriteLn('   ✓ After zeroing, buffers have different content');
    end;
    
    // 检查重叠
    if not IsOverlap(LBuffer1, LBuffer2, LSize) then
    begin
      WriteLn('7. ✓ 两个内存块没有重叠');
      WriteLn('   ✓ No overlap between buffers');
    end;
    
  finally
    FreeMem(LBuffer1);
    FreeMem(LBuffer2);
    WriteLn('8. 释放内存完成');
    WriteLn('   Memory freed');
  end;
  
  WriteLn;
end;

procedure DemoAllocators;
var
  LAllocator: IAllocator;
  LPtr: Pointer;
  LSize: SizeUInt;
begin
  WriteLn('=== 分配器演示 Allocator Demo ===');

  // 获取 RTL 分配器（接口风格）
  LAllocator := GetRtlAllocator;
  WriteLn('1. 获取 RTL 分配器');
  WriteLn('   Got RTL allocator');

  LSize := 1024;
  LPtr := LAllocator.GetMem(LSize);

  if LPtr <> nil then
  begin
    WriteLn('2. ✓ 使用分配器分配了 ', LSize, ' 字节');
    WriteLn('   ✓ Allocated ', LSize, ' bytes using allocator');
    
    // 填充一些数据
    Fill(LPtr, LSize, $55);
    WriteLn('3. 填充数据完成');
    WriteLn('   Data filled');
    
    // 重新分配
    LPtr := LAllocator.ReallocMem(LPtr, LSize * 2);
    if LPtr <> nil then
    begin
      WriteLn('4. ✓ 重新分配到 ', LSize * 2, ' 字节');
      WriteLn('   ✓ Reallocated to ', LSize * 2, ' bytes');
    end;
    
    // 释放内存
    LAllocator.FreeMem(LPtr);
    WriteLn('5. 释放内存完成');
    WriteLn('   Memory freed');
  end
  else
  begin
    WriteLn('2. ✗ 内存分配失败');
    WriteLn('   ✗ Memory allocation failed');
  end;
  
  WriteLn;
end;

procedure DemoAlignment;
var
  LPtr: Pointer;
  LAlignedPtr: Pointer;
begin
  WriteLn('=== 内存对齐演示 Memory Alignment Demo ===');
  
  LPtr := GetMem(100);
  try
    WriteLn(Format('1. 分配的内存地址: %p', [LPtr]));
    WriteLn(Format('   Allocated memory address: %p', [LPtr]));
    
    if IsAligned(LPtr) then
    begin
      WriteLn('2. ✓ 内存已对齐');
      WriteLn('   ✓ Memory is aligned');
    end
    else
    begin
      WriteLn('2. ✗ 内存未对齐');
      WriteLn('   ✗ Memory is not aligned');
      
      LAlignedPtr := AlignUp(LPtr);
      WriteLn(Format('3. 对齐后地址: %p', [LAlignedPtr]));
      WriteLn(Format('   Aligned address: %p', [LAlignedPtr]));
    end;
    
  finally
    FreeMem(LPtr);
  end;
  
  WriteLn;
end;

begin
  WriteLn('fafafa.core.mem 模块使用示例');
  WriteLn('fafafa.core.mem Module Usage Example');
  WriteLn('=====================================');
  WriteLn;
  
  try
    DemoMemoryOperations;
    DemoAllocators;
    DemoAlignment;
    
    WriteLn('=== 演示完成 Demo Complete ===');
    WriteLn('所有功能演示成功！');
    WriteLn('All features demonstrated successfully!');
    
  except
    on E: Exception do
    begin
      WriteLn('错误 Error: ', E.Message);
      ExitCode := 1;
    end;
  end;
  
  WriteLn;
  WriteLn('按回车键退出 Press Enter to exit...');
  ReadLn;
end.
