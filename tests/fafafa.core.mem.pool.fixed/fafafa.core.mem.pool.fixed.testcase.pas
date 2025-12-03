unit fafafa.core.mem.pool.fixed.testcase;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testutils, testregistry,
  fafafa.core.mem.pool.base,   // IPool interface only, avoid pulling facade deps
  fafafa.core.mem.pool.fixed,
  fafafa.core.mem.allocator;

type
  // 全局函数测试收纳（若未来有）
  TTestCase_Global = class(TTestCase)
  published
    procedure Test_Placeholder; // 保留占位，避免空单元
  end;

  // 类对象测试：TFixedPool
  TTestCase_TFixedPool = class(TTestCase)
  private
    FPool: TFixedPool;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure Test_Acquire_UntilFull;
    procedure Test_Acquire_AfterFull_ReturnsFalse;
    procedure Test_Release_Then_Acquire_SamePtr;
    procedure Test_Release_Nil_NoOp;
    procedure Test_DoubleFree_Raises;
    procedure Test_Release_InvalidPointer_Raises;
    procedure Test_Reset_RestoresCapacity;
    procedure Test_IPool_Interface_Compliance;
    procedure Test_ZeroOnAlloc_ClearsMemory;
    // 新增测试
    procedure Test_TryAlloc_Success;
    procedure Test_TryAlloc_Failure;
    procedure Test_Create_InvalidBlockSize_Zero_Raises;
    procedure Test_Create_InvalidBlockSize_Unaligned_Raises;
    procedure Test_Create_InvalidCapacity_Raises;
    procedure Test_Release_MisalignedPointer_Raises;
    procedure Test_Release_AlignedOtherBlock_DoubleFree_Raises;
    procedure Test_Release_Aligned_OutOfRange_Raises;
    procedure Test_Create_BlockSize_PtrSize_Aligned_OK;
    procedure Test_DefaultAlignment_Applies_And_PtrAligned;
    procedure Test_Create_LargeBlock4096_OK;
    procedure Test_Create_TotalSizeOverflow_Raises;
    procedure Test_Boundary_LargeBlock_Capacity1_OK;
    procedure Test_Stress_AcquireRelease_10k_OK;
    procedure Test_Aligned32_Aligned64_OK;
    procedure Test_Shuffle_Release_Reacquire_Rounds_OK;
  end;

procedure RegisterTests;

implementation

procedure RegisterTests;
begin
  RegisterTest('Global', TTestCase_Global.Suite);
  RegisterTest('TFixedPool', TTestCase_TFixedPool.Suite);
end;

{ TTestCase_Global }

procedure TTestCase_Global.Test_Placeholder;
begin
  // Fixed memory pool tests are implemented in TTestCase_TFixedPool
  // This placeholder ensures the test file structure is complete
  AssertTrue('Fixed memory pool module structure is valid', True);
end;

{ TTestCase_TFixedPool }

procedure TTestCase_TFixedPool.SetUp;
begin
  inherited SetUp;
  // BlockSize 16, Capacity 8，使用默认 allocator（rtl）
  FPool := TFixedPool.Create(16, 8);
end;

procedure TTestCase_TFixedPool.TearDown;
begin
  FreeAndNil(FPool);
  inherited TearDown;
end;

procedure TTestCase_TFixedPool.Test_Acquire_UntilFull;
var
  i: Integer; p: Pointer;
begin
  for i := 1 to 8 do begin
    CheckTrue(FPool.Acquire(p));
    CheckTrue(p <> nil);
  end;
end;

procedure TTestCase_TFixedPool.Test_Acquire_AfterFull_ReturnsFalse;
var
  i: Integer; p: Pointer;
begin
  for i := 1 to 8 do CheckTrue(FPool.Acquire(p));
  CheckFalse(FPool.Acquire(p));
end;

procedure TTestCase_TFixedPool.Test_Release_Then_Acquire_SamePtr;
var
  p1, p2: Pointer;
begin
  CheckTrue(FPool.Acquire(p1));
  FPool.Release(p1);
  CheckTrue(FPool.Acquire(p2));
  CheckEquals(PtrUInt(p1), PtrUInt(p2));
end;

procedure TTestCase_TFixedPool.Test_Release_Nil_NoOp;
begin
  FPool.Release(nil);
  // 不抛异常即为通过
  CheckTrue(True);
end;

procedure TTestCase_TFixedPool.Test_DoubleFree_Raises;
var
  p: Pointer;
begin
  CheckTrue(FPool.Acquire(p));
  FPool.Release(p);
  try
    FPool.Release(p);
    Fail('Expected double free exception');
  except
    on E: Exception do
      CheckTrue(Pos('Double free', E.Message) > 0);
  end;
end;

procedure TTestCase_TFixedPool.Test_Release_InvalidPointer_Raises;
var
  bad: Pointer;
begin
  bad := GetMem(16);
  try
    try
      FPool.Release(bad);
      Fail('Expected invalid pointer exception');
    except
      on E: Exception do
        CheckTrue(Pos('belong to this pool', E.Message) > 0);
    end;
  finally
    FreeMem(bad);
  end;
end;

procedure TTestCase_TFixedPool.Test_Reset_RestoresCapacity;
var
  i: Integer; p: Pointer;
begin
  for i := 1 to 8 do CheckTrue(FPool.Acquire(p));
  FPool.Reset;
  // 再次获取 8 次
  for i := 1 to 8 do begin
    CheckTrue(FPool.Acquire(p));
    CheckTrue(p <> nil);
  end;
end;

procedure TTestCase_TFixedPool.Test_ZeroOnAlloc_ClearsMemory;
var
  cfg: TFixedPoolConfig;
  pool: TFixedPool;
  p: PByte;
  i: SizeInt;
begin
  cfg.BlockSize := 16;
  cfg.Capacity := 2;
  cfg.Alignment := 0; // use default alignment

  cfg.ZeroOnAlloc := True;
  cfg.Allocator := GetRtlAllocator;
  pool := TFixedPool.Create(cfg);
  try
    CheckTrue(pool.Acquire(Pointer(p)));
    // 第一次分配应为全零
    for i := 0 to pool.BlockSize - 1 do
      CheckEquals(0, Ord(p[i]));
    // 写入非零并释放
    for i := 0 to pool.BlockSize - 1 do
      p[i] := $AA;
    pool.Release(p);
    // 再次获取，应被清零
    CheckTrue(pool.Acquire(Pointer(p)));
    for i := 0 to pool.BlockSize - 1 do
      CheckEquals(0, Ord(p[i]));
  finally
    pool.Free;
  end;
end;

procedure TTestCase_TFixedPool.Test_IPool_Interface_Compliance;
var
  P: IPool;
  i: Integer;
  u: Pointer;
  arr: array[0..7] of Pointer;
begin
  // 获取 IPool 接口并按接口语义操作
  P := FPool as IPool;
  // 注意：TInterfacedObject + 类引用并存会导致双重释放；此处转为接口后，置空 FPool，交由接口生命周期管理
  FPool := nil;
  for i := 0 to 7 do begin
    CheckTrue(P.Acquire(arr[i]));
    CheckTrue(arr[i] <> nil);
  end;
  // 满载后 Acquire 应返回 False，且 out 置为 nil
  u := Pointer(1);
  CheckFalse(P.Acquire(u));
  CheckTrue(u = nil);
  // 释放一个真实块，再次获取应成功
  P.Release(arr[0]);
  CheckTrue(P.Acquire(u));
  CheckTrue(u <> nil);
  // 再释放获取到的，并验证 Reset 恢复容量
  P.Release(u);
  P.Reset;
  for i := 0 to 7 do begin
    CheckTrue(P.Acquire(u));
    CheckTrue(u <> nil);
  end;
end;

procedure TTestCase_TFixedPool.Test_TryAlloc_Success;
var
  p: Pointer;
begin
  CheckTrue(FPool.TryAlloc(p));
  CheckTrue(p <> nil);
end;

procedure TTestCase_TFixedPool.Test_TryAlloc_Failure;
var
  i: Integer; p,u: Pointer;
begin
  for i := 1 to 8 do CheckTrue(FPool.Acquire(p));
  u := Pointer(1);
  CheckFalse(FPool.TryAlloc(u));
  CheckTrue(u = nil);
end;

procedure TTestCase_TFixedPool.Test_Create_InvalidBlockSize_Zero_Raises;
begin
  try
    FPool.Free;
    FPool := nil;
    FPool := TFixedPool.Create(0, 8);
    Fail('Expected exception for zero block size');
  except
    on E: Exception do CheckTrue(Pos('Block size cannot be zero', E.Message) > 0);
  end;
end;

procedure TTestCase_TFixedPool.Test_Create_InvalidBlockSize_Unaligned_Raises;
begin
  try
    FPool.Free;
    FPool := nil;
    // 3 不是指针对齐的倍数（在 64 位下通常为 8）
    FPool := TFixedPool.Create(3, 8);
    Fail('Expected exception for unaligned block size');
  except
    on E: Exception do CheckTrue(Pos('multiple of pointer size', E.Message) > 0);
  end;
end;

procedure TTestCase_TFixedPool.Test_Create_InvalidCapacity_Raises;
begin
  try
    FPool.Free;
    FPool := nil;
    FPool := TFixedPool.Create(SizeOf(Pointer), 0);
    Fail('Expected exception for non-positive capacity');
  except
    on E: Exception do CheckTrue(Pos('Capacity must be positive', E.Message) > 0);
  end;
end;

procedure TTestCase_TFixedPool.Test_Release_MisalignedPointer_Raises;
var
  p: PByte;
begin
  CheckTrue(FPool.Acquire(Pointer(p)));
  // 制造一个错位地址（+1 字节），违反对齐
  try
    FPool.Release(p + 1);
    Fail('Expected misaligned pointer exception');
  except
    on E: Exception do CheckTrue(Pos('aligned to block size', E.Message) > 0);
  end;
  // 清理：释放合法块
  FPool.Release(p);
end;


procedure TTestCase_TFixedPool.Test_Release_AlignedOtherBlock_DoubleFree_Raises;
var
  p1, p2: PByte;
begin
  // 分配两个块，释放第一个后，再用同一对齐地址释放一次，触发 double free
  CheckTrue(FPool.Acquire(Pointer(p1)));
  CheckTrue(FPool.Acquire(Pointer(p2)));
  FPool.Release(p1);
  try
    FPool.Release(p1);
    Fail('Expected double free exception for aligned same block');
  except
    on E: Exception do CheckTrue(Pos('Double free', E.Message) > 0);
  end;
  // 清理：释放第二个块
  FPool.Release(p2);
end;

procedure TTestCase_TFixedPool.Test_Release_Aligned_OutOfRange_Raises;
var
  p: PByte;
  outPtr: PByte;
  msg: AnsiString;
begin
  // 获取一个合法块，构造“越界但对齐”的地址：FBuffer + FTotalSize
  CheckTrue(FPool.Acquire(Pointer(p)));
  try
    // 通过已知块推算块大小，并构造越界指针（此处用块起始 + BlockSize * Capacity）
    outPtr := p; // 起点对齐
    // 由于无法直接访问私有 FBuffer/FTotalSize，这里模拟越界：
    // 将 p 回收后，再构造一个对齐且超出范围的指针 = p + BlockSize*Capacity
    FPool.Release(p);
    outPtr := PByte(PtrUInt(outPtr) + PtrUInt(FPool.BlockSize) * PtrUInt(FPool.Capacity));
    FPool.Release(outPtr);

    Fail('Expected out-of-range exception for aligned pointer');
  except
    on E: Exception do
    begin
      msg := LowerCase(E.Message);
      CheckTrue( (Pos('belong to this pool', msg) > 0)
              or (Pos('out of range', msg) > 0)
              or (Pos('aligned to block size', msg) > 0) );
    end;
  end;
end;

procedure TTestCase_TFixedPool.Test_Create_BlockSize_PtrSize_Aligned_OK;
var
  pool: TFixedPool;
begin
  pool := TFixedPool.Create(SizeOf(Pointer), 4, SizeOf(Pointer));
  try
    CheckTrue(Assigned(pool));
    CheckEquals(QWord(SizeOf(Pointer)), QWord(pool.BlockSize));
    CheckEquals(4, pool.Capacity);
  finally
    pool.Free;
  end;
end;

procedure TTestCase_TFixedPool.Test_DefaultAlignment_Applies_And_PtrAligned;
var
  pool: TFixedPool;
  p: Pointer;
  align: SizeUInt;
begin
  pool := TFixedPool.Create(16, 2, 0{default align});
  try
    align := pool.Alignment;
    CheckTrue( (align=SizeOf(Pointer)) or (align=16) );
    CheckTrue(pool.Acquire(p));
    CheckEquals(0, PtrUInt(p) mod align);
    pool.Release(p);
  finally
    pool.Free;
  end;
end;

procedure TTestCase_TFixedPool.Test_Create_LargeBlock4096_OK;
var
  pool: TFixedPool;
begin
  pool := TFixedPool.Create(4096, 2);
  try
    CheckTrue(Assigned(pool));
    CheckEquals(QWord(4096), QWord(pool.BlockSize));
    CheckEquals(2, pool.Capacity);
  finally
    pool.Free;
  end;
end;

procedure TTestCase_TFixedPool.Test_Create_TotalSizeOverflow_Raises;
var
  bigBlock: SizeUInt;
begin
  // 触发 FTotalSize 乘法溢出检查：选择极大 block * capacity
  // 通过计算避免编译器常量折叠：
  bigBlock := High(SizeUInt) div 2 + 1; // 确保 bigBlock*2 溢出
  try
    FPool.Free; FPool := nil;
    FPool := TFixedPool.Create(bigBlock, 2);
    Fail('Expected total size overflow exception');
  except
    on E: Exception do CheckTrue(Pos('Total size overflow', E.Message) > 0);
  end;
end;


procedure TTestCase_TFixedPool.Test_Boundary_LargeBlock_Capacity1_OK;
var
  pool: TFixedPool;
  blk: SizeUInt;
begin
  // 使用相对较大的块（1MB）且不触发溢出，确保可分配
  blk := 1 shl 20; // 1MB
  pool := TFixedPool.Create(blk, 1);
  try
    CheckTrue(Assigned(pool));
    CheckEquals(QWord(blk), QWord(pool.BlockSize));
    CheckEquals(1, pool.Capacity);
  finally
    pool.Free;
  end;
end;

procedure TTestCase_TFixedPool.Test_Stress_AcquireRelease_10k_OK;
var
  i, cap: Integer;
  p: Pointer;
begin
  cap := FPool.Capacity;
  // 先满额
  for i := 1 to cap do begin CheckTrue(FPool.Acquire(p)); end;
  // 释放再分配循环 1 万次
  for i := 1 to 10000 do begin
    FPool.Release(p); // 释放最后一次获得的 p（可能重复释放同一逻辑位置）
    CheckTrue(FPool.Acquire(p));
  end;
  // 收尾：直接重置并验证可再次满额分配
  FPool.Reset;
  for i := 1 to cap do begin CheckTrue(FPool.Acquire(p)); end;
end;


procedure Shuffle(var A: array of Pointer);
var i,j: Integer; tmp: Pointer;
begin
  for i := High(A) downto 1 do begin
    j := Random(i+1);
    tmp := A[i]; A[i] := A[j]; A[j] := tmp;
  end;
end;

procedure TTestCase_TFixedPool.Test_Aligned32_Aligned64_OK;
var
  pool32, pool64: TFixedPool;
  p: Pointer;
begin
  pool32 := TFixedPool.Create(32, 4, 32);
  try
    CheckTrue(pool32.Acquire(p));
    CheckEquals(0, PtrUInt(p) mod 32);
    pool32.Release(p);
  finally
    pool32.Free;
  end;

  pool64 := TFixedPool.Create(64, 4, 64);
  try
    CheckTrue(pool64.Acquire(p));
    CheckEquals(0, PtrUInt(p) mod 64);
    pool64.Release(p);
  finally
    pool64.Free;
  end;
end;

procedure TTestCase_TFixedPool.Test_Shuffle_Release_Reacquire_Rounds_OK;
const
  Rounds = 8;
var
  i, r, cap: Integer;
  arr: array of Pointer;
begin
  Randomize;
  cap := FPool.Capacity;
  SetLength(arr, cap);
  // Round: 满额分配 -> 打散释放 -> 再满额分配
  for r := 1 to Rounds do begin
    for i := 0 to cap-1 do CheckTrue(FPool.Acquire(arr[i]));
    Shuffle(arr);
    for i := 0 to cap-1 do FPool.Release(arr[i]);
  end;
end;

end.

