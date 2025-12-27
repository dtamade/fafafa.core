{$CODEPAGE UTF8}
unit Test_fafafa_core_mem;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, fafafa.core.base,
  fafafa.core.mem,
  fafafa.core.mem.memPool,
  fafafa.core.mem.stackPool,
  fafafa.core.mem.ringBuffer;

type
  {**
   * TTestCase_CoreMem
   *
   * @desc 测试 fafafa.core.mem 核心功能
   *}
  TTestCase_CoreMem = class(TTestCase)
  published
    procedure Test_CoreMem_ReExports;
    procedure Test_CoreMem_MemoryOperations;
    procedure Test_CoreMem_MemoryOperations_Extended;
    procedure Test_CoreMem_UnChecked_Functions;
    procedure Test_CoreMem_Exception_Cases;
    procedure Test_CoreMem_Allocators;
  end;

  {**
   * TTestCase_MemPool
   *
   * @desc 测试 TMemPool 功能
   *}
  TTestCase_MemPool = class(TTestCase)
  published
    procedure Test_MemPool_Create;
    procedure Test_MemPool_BasicAllocation;
    procedure Test_MemPool_FullPool;
    procedure Test_MemPool_Reset;
  end;

  {**
   * TTestCase_StackPool
   *
   * @desc 测试 TStackPool 功能
   *}
  TTestCase_StackPool = class(TTestCase)
  published
    procedure Test_StackPool_Create;
    procedure Test_StackPool_BasicAllocation;
    procedure Test_StackPool_StateManagement;
    procedure Test_StackPool_Reset;
    procedure Test_StackPool_AllocAligned;
    procedure Test_StackPool_TryAllocAligned;

  end;

  {**
   * TTestCase_RingBuffer
   *
   * @desc 测试 TRingBuffer 功能
   *}
  TTestCase_RingBuffer = class(TTestCase)
  published
    procedure Test_RingBuffer_Create;
    procedure Test_RingBuffer_BasicOperations;
    procedure Test_RingBuffer_FullBuffer;
    procedure Test_RingBuffer_Resize;
  end;

  {**
   * TTestCase_FacadeOnly
   *
   * @desc 验证仅 uses fafafa.core.mem 门面即可访问三类核心池类型
   *}
  TTestCase_FacadeOnly = class(TTestCase)
  published
    procedure Test_Facade_Exports_Pools;
    procedure Test_Facade_Exceptions_With_AssertException;
  end;


implementation

{ TTestCase_CoreMem }

procedure TTestCase_CoreMem.Test_CoreMem_ReExports;
var
  LAllocator: IAllocator;
begin
  // 测试分配器重新导出
  LAllocator := GetRtlAllocator;
  AssertNotNull('GetRtlAllocator 应该返回有效分配器', LAllocator);

  {$IFDEF FAFAFA_CORE_CRT_ALLOCATOR}
  LAllocator := GetCrtAllocator;
  AssertNotNull('GetCrtAllocator 应该返回有效分配器', LAllocator);
  {$ENDIF}
end;

procedure TTestCase_CoreMem.Test_CoreMem_MemoryOperations;
var
  LPtr1, LPtr2, LPtr3: Pointer;
  LAllocator: IAllocator;
begin
  LAllocator := GetRtlAllocator;

  // 分配内存进行测试
  LPtr1 := LAllocator.GetMem(100);
  LPtr2 := LAllocator.GetMem(100);
  LPtr3 := LAllocator.GetMem(100);

  try
    AssertNotNull('内存分配应该成功', LPtr1);
    AssertNotNull('内存分配应该成功', LPtr2);
    AssertNotNull('内存分配应该成功', LPtr3);

    // 测试 Fill 系列
    Fill(LPtr1, 100, $AA);
    AssertEquals('Fill 后第一个字节应该是 $AA', $AA, PByte(LPtr1)^);

    Fill8(LPtr2, 50, $BB);
    AssertEquals('Fill8 后第一个字节应该是 $BB', $BB, PByte(LPtr2)^);

    Fill16(LPtr3, 25, $CCDD);
    AssertEquals('Fill16 后第一个字应该是 $CCDD', $CCDD, PWord(LPtr3)^);

    // 测试 Copy 系列
    Copy(LPtr1, LPtr2, 100);
    AssertEquals('Copy 后第一个字节应该相同', PByte(LPtr1)^, PByte(LPtr2)^);

    CopyNonOverlap(LPtr1, LPtr3, 50);
    AssertEquals('CopyNonOverlap 后前50字节应该相同', PByte(LPtr1)^, PByte(LPtr3)^);

    // 测试 Equal
    AssertTrue('Equal 应该返回 True', Equal(LPtr1, LPtr2, 100));
    AssertTrue('Equal 前50字节应该相同', Equal(LPtr1, LPtr3, 50));

    // 测试 Compare 系列
    AssertEquals('Compare 相同内存应该返回 0', 0, Compare(LPtr1, LPtr2, 100));
    AssertEquals('Compare8 相同内存应该返回 0', 0, Compare8(LPtr1, LPtr2, 100));

    // 测试 Zero
    Zero(LPtr1, 100);
    AssertEquals('Zero 后第一个字节应该是 0', 0, PByte(LPtr1)^);

    // 测试 Compare 不同内存
    AssertTrue('Compare 应该显示不同', Compare(LPtr1, LPtr2, 100) <> 0);

    // 测试 IsOverlap
    AssertFalse('不同内存块不应该重叠', IsOverlap(LPtr1, LPtr2, 100));
    AssertTrue('同一内存块应该重叠', IsOverlap(LPtr1, LPtr1, 100));

    // 测试 IsAligned
    AssertTrue('分配的内存应该是对齐的', IsAligned(LPtr1));

  finally
    LAllocator.FreeMem(LPtr1);
    LAllocator.FreeMem(LPtr2);
    LAllocator.FreeMem(LPtr3);
  end;
end;

procedure TTestCase_CoreMem.Test_CoreMem_MemoryOperations_Extended;
var
  LPtr1, LPtr2: Pointer;
  LAllocator: IAllocator;
  LValue32: UInt32;
  LValue64: UInt64;
begin
  LAllocator := GetRtlAllocator;

  LPtr1 := LAllocator.GetMem(200);
  LPtr2 := LAllocator.GetMem(200);

  try
    // 测试 Fill32
    LValue32 := $12345678;
    Fill32(LPtr1, 50, LValue32);
    AssertEquals('Fill32 后第一个双字应该正确', LValue32, PUInt32(LPtr1)^);

    // 测试 Fill64
    LValue64 := $123456789ABCDEF0;
    Fill64(LPtr2, 25, LValue64);
    AssertEquals('Fill64 后第一个四字应该正确', LValue64, PUInt64(LPtr2)^);

    // 测试 Compare16
    Fill16(LPtr1, 100, $ABCD);
    Fill16(LPtr2, 100, $ABCD);
    AssertEquals('Compare16 相同内容应该返回 0', 0, Compare16(LPtr1, LPtr2, 100));

    // 测试 Compare32
    Fill32(LPtr1, 50, $12345678);
    Fill32(LPtr2, 50, $12345678);
    AssertEquals('Compare32 相同内容应该返回 0', 0, Compare32(LPtr1, LPtr2, 50));

    // 测试 AlignUp / AlignDown（门面重导出）
    AssertNotNull('AlignUp 应该返回有效指针', AlignUp(LPtr1, 8));
    AssertTrue('AlignDown 返回值应按对齐', IsAligned(AlignDown(LPtr1, 8), 8));

  finally
    LAllocator.FreeMem(LPtr1);
    LAllocator.FreeMem(LPtr2);
  end;
end;

procedure TTestCase_CoreMem.Test_CoreMem_UnChecked_Functions;
var
  LPtr1, LPtr2: Pointer;
  LAllocator: IAllocator;
begin
  LAllocator := GetRtlAllocator;

  LPtr1 := LAllocator.GetMem(100);
  LPtr2 := LAllocator.GetMem(100);

  try
    // 测试 IsOverlapUnChecked
    AssertFalse('IsOverlapUnChecked 不同内存块应该返回 False',
                IsOverlapUnChecked(LPtr1, 100, LPtr2, 100));
    AssertTrue('IsOverlapUnChecked 同一内存块应该返回 True',
               IsOverlapUnChecked(LPtr1, 100, LPtr1, 100));

    // 测试 CopyUnChecked
    Fill(LPtr1, 100, $AA);
    CopyUnChecked(LPtr1, LPtr2, 100);
    AssertTrue('CopyUnChecked 后内容应该相同', Equal(LPtr1, LPtr2, 100));

    // 测试 CopyNonOverlapUnChecked
    Fill(LPtr1, 50, $BB);
    CopyNonOverlapUnChecked(LPtr1, LPtr2, 50);
    AssertEquals('CopyNonOverlapUnChecked 后第一个字节应该相同',
                 PByte(LPtr1)^, PByte(LPtr2)^);

    // 测试 AlignUpUnChecked
    AssertNotNull('AlignUpUnChecked 应该返回有效指针', AlignUpUnChecked(LPtr1, 8));

  finally
    LAllocator.FreeMem(LPtr1);
    LAllocator.FreeMem(LPtr2);
  end;
end;

procedure TTestCase_CoreMem.Test_CoreMem_Exception_Cases;
var
  LPtr: Pointer;
  LAllocator: IAllocator;
  LExceptionRaised: Boolean;
begin
  LAllocator := GetRtlAllocator;
  LPtr := LAllocator.GetMem(100);

  try
    // 测试 nil 指针异常
    LExceptionRaised := False;
    try
      Fill(nil, 100, $AA);
    except
      on E: Exception do
        LExceptionRaised := True;
    end;
    AssertTrue('Fill nil 指针应该抛出异常', LExceptionRaised);

    // 测试 Copy nil 指针异常
    LExceptionRaised := False;
    try
      Copy(nil, LPtr, 100);
    except
      on E: Exception do
        LExceptionRaised := True;
    end;
    AssertTrue('Copy nil 源指针应该抛出异常', LExceptionRaised);

    // 测试 AlignUp nil 指针异常
    LExceptionRaised := False;
    try
      AlignUp(nil, 8);
    except
      on E: Exception do
        LExceptionRaised := True;
    end;
    AssertTrue('AlignUp nil 指针应该抛出异常', LExceptionRaised);

  finally
    LAllocator.FreeMem(LPtr);
  end;
end;

procedure TTestCase_CoreMem.Test_CoreMem_Allocators;
var
  LAllocator: IAllocator;
  LPtr: Pointer;
begin
  LAllocator := GetRtlAllocator;

  LPtr := LAllocator.GetMem(256);
  try
    AssertNotNull('RTL分配器分配应该成功', LPtr);
  finally
    LAllocator.FreeMem(LPtr);
  end;
end;

{ TTestCase_MemPool }

procedure TTestCase_MemPool.Test_MemPool_Create;
var
  LPool: TMemPool;
begin
  LPool := TMemPool.Create(64, 10);
  try
    AssertEquals('块大小应该正确', 64, LPool.BlockSize);
    AssertEquals('容量应该正确', 10, LPool.Capacity);
    AssertEquals('初始分配数量应该为0', 0, LPool.AllocatedCount);
    AssertEquals('初始可用数量应该等于容量', 10, LPool.Available);
    AssertTrue('初始应该为空', LPool.AllocatedCount = 0);
    AssertFalse('初始不应该满', LPool.Available = 0);
  finally
    LPool.Destroy;
  end;
end;

procedure TTestCase_MemPool.Test_MemPool_BasicAllocation;
var
  LPool: TMemPool;
  LPtr: Pointer;
begin
  LPool := TMemPool.Create(32, 5);
  try
    LPtr := LPool.Alloc;
    AssertNotNull('分配应该成功', LPtr);
    AssertEquals('分配后数量应该为1', 1, LPool.AllocatedCount);
    AssertFalse('分配后不应该为空', LPool.AllocatedCount = 0);

    LPool.ReleasePtr(LPtr);
    AssertEquals('释放后数量应该为0', 0, LPool.AllocatedCount);
    AssertTrue('释放后应该为空', LPool.AllocatedCount = 0);
  finally
    LPool.Destroy;
  end;
end;

procedure TTestCase_MemPool.Test_MemPool_FullPool;
var
  LPool: TMemPool;
  LPtrs: array[0..4] of Pointer;
  I: Integer;
begin
  LPool := TMemPool.Create(16, 5);
  try
    // 分配所有块
    for I := 0 to 4 do
    begin
      LPtrs[I] := LPool.Alloc;
      AssertNotNull('分配应该成功', LPtrs[I]);
    end;

    AssertTrue('池应该满了', LPool.Available = 0);
    AssertEquals('分配数量应该等于容量', 5, LPool.AllocatedCount);

    // 尝试再分配应该失败
    AssertNull('满池再分配应该失败', LPool.Alloc);

    // 释放所有块
    for I := 0 to 4 do
      LPool.ReleasePtr(LPtrs[I]);

    AssertTrue('释放后应该为空', LPool.AllocatedCount = 0);
  finally
    LPool.Destroy;
  end;
end;

procedure TTestCase_MemPool.Test_MemPool_Reset;
var
  LPool: TMemPool;
  LPtr1, LPtr2: Pointer;
begin
  LPool := TMemPool.Create(64, 3);
  try
    LPtr1 := LPool.Alloc;
    LPtr2 := LPool.Alloc;
    AssertEquals('分配后数量应该为2', 2, LPool.AllocatedCount);

    LPool.Reset;
    AssertEquals('重置后数量应该为0', 0, LPool.AllocatedCount);
    AssertTrue('重置后应该为空', LPool.AllocatedCount = 0);
  finally
    LPool.Destroy;
  end;
end;

{ TTestCase_StackPool }

procedure TTestCase_StackPool.Test_StackPool_Create;
var
  LPool: TStackPool;
begin
  LPool := TStackPool.Create(1024);
  try
    AssertEquals('总大小应该正确', 1024, LPool.TotalSize);
    AssertEquals('初始已用大小应该为0', 0, LPool.UsedSize);
    AssertEquals('初始可用大小应该等于总大小', 1024, LPool.AvailableSize);
    AssertTrue('初始应该为空', LPool.IsEmpty);
    AssertFalse('初始不应该满', LPool.IsFull);
  finally
    LPool.Destroy;
  end;
end;

procedure TTestCase_StackPool.Test_StackPool_BasicAllocation;
var
  LPool: TStackPool;
  LPtr1, LPtr2: Pointer;
begin
  LPool := TStackPool.Create(512);
  try
    LPtr1 := LPool.Alloc(100);
    AssertNotNull('第一次分配应该成功', LPtr1);
    AssertTrue('分配后已用大小应该大于0', LPool.UsedSize > 0);

    LPtr2 := LPool.Alloc(200);
    AssertNotNull('第二次分配应该成功', LPtr2);
    AssertTrue('第二次分配后已用大小应该更大', LPool.UsedSize >= 300);

    // 指针应该不同
    AssertTrue('两个指针应该不同', LPtr1 <> LPtr2);
  finally
    LPool.Destroy;
  end;
end;

procedure TTestCase_StackPool.Test_StackPool_StateManagement;
var
  LPool: TStackPool;
  LPtr1, LPtr2: Pointer;
  LState: SizeUInt;
begin
  LPool := TStackPool.Create(512);
  try
    LPtr1 := LPool.Alloc(100);
    LState := LPool.SaveState;

    LPtr2 := LPool.Alloc(200);
    AssertTrue('第二次分配后已用大小应该更大', LPool.UsedSize > LState);

    LPool.RestoreState(LState);
    AssertEquals('恢复状态后已用大小应该等于保存的状态', LState, LPool.UsedSize);
  finally
    LPool.Destroy;
  end;
end;

procedure TTestCase_StackPool.Test_StackPool_Reset;
var
  LPool: TStackPool;
  LPtr: Pointer;
begin
  LPool := TStackPool.Create(256);
  try
    LPtr := LPool.Alloc(100);
    AssertTrue('分配后已用大小应该大于0', LPool.UsedSize > 0);

    LPool.Reset;
    AssertEquals('重置后已用大小应该为0', 0, LPool.UsedSize);
    AssertTrue('重置后应该为空', LPool.IsEmpty);
  finally
    LPool.Destroy;
  end;
end;

procedure TTestCase_StackPool.Test_StackPool_AllocAligned;
var
  LPool: TStackPool;
  P1, P2: Pointer;
begin
  LPool := TStackPool.Create(512);
  try
    // 16 字节对齐分配
    P1 := LPool.AllocAligned(64, 16);
    AssertTrue('AllocAligned should return non-nil', P1 <> nil);
    // 紧接着再来一次，验证连续对齐分配
    P2 := LPool.AllocAligned(32, 32);
    AssertTrue('AllocAligned(32,32) should return non-nil', P2 <> nil);
    // 非 2 的幂：应抛 EInvalidArgument（不在此用例断言异常，仅冒烟）
  finally
    LPool.Destroy;
  end;
end;

procedure TTestCase_StackPool.Test_StackPool_TryAllocAligned;
var
  LPool: TStackPool;
  P: Pointer;
begin
  LPool := TStackPool.Create(128);
  try
    // 合法对齐，应成功
    AssertTrue('TryAllocAligned(64,16) should succeed', LPool.TryAllocAligned(64, P, 16));
    AssertTrue('P should be non-nil', P <> nil);
    // 非 2 的幂：应返回 False（内部捕获异常）
    AssertFalse('TryAllocAligned with invalid alignment should fail', LPool.TryAllocAligned(16, P, 3));
  finally
    LPool.Destroy;
  end;
end;

{ TTestCase_RingBuffer }

procedure TTestCase_RingBuffer.Test_RingBuffer_Create;
var
  LBuffer: TRingBuffer;
begin
  LBuffer := TRingBuffer.Create(10, SizeOf(Integer));
  try
    AssertEquals('容量应该正确', SizeUInt(10), LBuffer.Capacity);
    AssertEquals('元素大小应该正确', SizeUInt(SizeOf(Integer)), LBuffer.ElementSize);
    AssertEquals('初始数量应该为0', SizeUInt(0), LBuffer.Count);
    AssertTrue('初始应该为空', LBuffer.IsEmpty);
    AssertFalse('初始不应该满', LBuffer.IsFull);
  finally
    LBuffer.Free;
  end;
end;

procedure TTestCase_RingBuffer.Test_RingBuffer_BasicOperations;
var
  LBuffer: TRingBuffer;
  LValue1, LValue2: Integer;
begin
  LBuffer := TRingBuffer.Create(5, SizeOf(Integer));
  try
    LValue1 := 42;
    LValue2 := 0;

    // 写入数据
    AssertTrue('写入应该成功', LBuffer.Push(@LValue1));
    AssertEquals('写入后数量应该增加', SizeUInt(1), LBuffer.Count);

    // 读取数据
    AssertTrue('读取应该成功', LBuffer.Pop(@LValue2));
    AssertEquals('读取的值应该正确', 42, LValue2);
    AssertEquals('读取后数量应该减少', SizeUInt(0), LBuffer.Count);
  finally
    LBuffer.Free;
  end;
end;

procedure TTestCase_RingBuffer.Test_RingBuffer_FullBuffer;
var
  LBuffer: TRingBuffer;
  LValue: Integer;
  I: Integer;
begin
  LBuffer := TRingBuffer.Create(3, SizeOf(Integer));
  try
    // 填满缓冲区
    for I := 1 to 3 do
    begin
      LValue := I;
      AssertTrue('写入应该成功', LBuffer.Push(@LValue));
    end;

    AssertTrue('缓冲区应该满', LBuffer.IsFull);

    // 尝试再写入一个（应该失败）
    LValue := 4;
    AssertFalse('满缓冲区写入应该失败', LBuffer.Push(@LValue));
  finally
    LBuffer.Free;
  end;
end;

procedure TTestCase_RingBuffer.Test_RingBuffer_Resize;
var
  LBuffer: TRingBuffer;
  LValue: Integer;
begin
  LBuffer := TRingBuffer.Create(2, SizeOf(Integer));
  try
    // 添加一些数据
    LValue := 10;
    LBuffer.Push(@LValue);
    LValue := 20;
    LBuffer.Push(@LValue);

    // 调整大小
    AssertTrue('调整大小应该成功', LBuffer.Resize(5));
    AssertEquals('新容量应该正确', SizeUInt(5), LBuffer.Capacity);

    // 验证数据仍然存在
    AssertEquals('数据数量应该保持', SizeUInt(2), LBuffer.Count);
  finally
    LBuffer.Free;
  end;
end;




procedure TTestCase_FacadeOnly.Test_Facade_Exports_Pools;
var
  LMem: TMemPool;
  LStack: TStackPool;
  LPtr: Pointer;
begin
  // 仅依赖门面导出的类型和函数
  LMem := TMemPool.Create(32, 2);
  try
    LPtr := LMem.Alloc;
    AssertNotNull('TMemPool.Alloc 应成功', LPtr);
    if LPtr <> nil then LMem.ReleasePtr(LPtr);
  finally
    LMem.Destroy;
  end;

  LStack := TStackPool.Create(256);
  try
    LPtr := LStack.Alloc(32);
    AssertNotNull('TStackPool.Alloc 应成功', LPtr);
  finally
    LStack.Destroy;
  end;
end;

procedure TTestCase_FacadeOnly.Test_Facade_Exceptions_With_AssertException;
var
  LStack: TStackPool;
begin
  // AlignUp(nil, 8) 应抛异常: 使用 AssertException 验证
  AssertException(EArgumentNil, procedure begin AlignUp(nil, 8); end);

  // TStackPool.Alloc 大小为 0 时返回 nil（当前实现为返回 nil；若未来调整为抛异常，可同步修改断言）
  LStack := TStackPool.Create(64);
  try
    AssertNull('aSize=0 应返回 nil', LStack.Alloc(0));
  finally
    LStack.Destroy;
  end;
end;

initialization
  RegisterTest(TTestCase_FacadeOnly);
  RegisterTest(TTestCase_CoreMem);
  RegisterTest(TTestCase_MemPool);
  RegisterTest(TTestCase_StackPool);
  RegisterTest(TTestCase_RingBuffer);

end.
