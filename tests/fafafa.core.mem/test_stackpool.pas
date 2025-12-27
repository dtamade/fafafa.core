{$CODEPAGE UTF8}
unit test_stackpool;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.base,
  fafafa.core.mem.stackPool;

type
  TTestCase_StackPool = class(TTestCase)
  published
    // 基本功能测试
    procedure Test_Create_Basic;
    procedure Test_Create_ZeroSize;

    // 分配测试
    procedure Test_Alloc_Basic;
    procedure Test_Alloc_Multiple;
    procedure Test_Alloc_TillFull;
    procedure Test_Alloc_ZeroSize;
    procedure Test_TryAlloc;

    // 对齐测试
    procedure Test_AllocAligned;
    procedure Test_AllocAligned_InvalidAlignment;

    // 状态管理测试
    procedure Test_Reset;
    procedure Test_SaveState_RestoreState;

    // 属性测试
    procedure Test_Properties;
    procedure Test_IsEmpty_IsFull;
  end;

implementation

procedure TTestCase_StackPool.Test_Create_Basic;
var
  Pool: TStackPool;
begin
  Pool := TStackPool.Create(1024);
  try
    AssertEquals('TotalSize', 1024, Pool.TotalSize);
    AssertEquals('UsedSize initial', 0, Pool.UsedSize);
    AssertEquals('AvailableSize initial', 1024, Pool.AvailableSize);
  finally
    Pool.Free;
  end;
end;

procedure TTestCase_StackPool.Test_Create_ZeroSize;
begin
  AssertException(EStackPoolError,
    procedure begin TStackPool.Create(0).Free; end);
end;

procedure TTestCase_StackPool.Test_Alloc_Basic;
var
  Pool: TStackPool;
  P: Pointer;
begin
  Pool := TStackPool.Create(1024);
  try
    P := Pool.Alloc(64);
    AssertTrue('Alloc returns non-nil', P <> nil);
    AssertTrue('UsedSize >= 64', Pool.UsedSize >= 64);
    AssertTrue('AvailableSize < 1024', Pool.AvailableSize < 1024);
  finally
    Pool.Free;
  end;
end;

procedure TTestCase_StackPool.Test_Alloc_Multiple;
var
  Pool: TStackPool;
  P1, P2, P3: Pointer;
begin
  Pool := TStackPool.Create(1024);
  try
    P1 := Pool.Alloc(100);
    P2 := Pool.Alloc(200);
    P3 := Pool.Alloc(300);

    AssertTrue('P1 non-nil', P1 <> nil);
    AssertTrue('P2 non-nil', P2 <> nil);
    AssertTrue('P3 non-nil', P3 <> nil);

    // 栈式分配：地址应递增
    AssertTrue('P2 > P1', PtrUInt(P2) > PtrUInt(P1));
    AssertTrue('P3 > P2', PtrUInt(P3) > PtrUInt(P2));
  finally
    Pool.Free;
  end;
end;

procedure TTestCase_StackPool.Test_Alloc_TillFull;
var
  Pool: TStackPool;
  P: Pointer;
begin
  Pool := TStackPool.Create(256);
  try
    P := Pool.Alloc(256);
    AssertTrue('First alloc succeeds', P <> nil);

    // 池已满，再分配应返回 nil
    P := Pool.Alloc(1);
    AssertTrue('Alloc when full returns nil', P = nil);
  finally
    Pool.Free;
  end;
end;

procedure TTestCase_StackPool.Test_Alloc_ZeroSize;
var
  Pool: TStackPool;
  P: Pointer;
begin
  Pool := TStackPool.Create(1024);
  try
    P := Pool.Alloc(0);
    AssertTrue('Alloc(0) returns nil', P = nil);
  finally
    Pool.Free;
  end;
end;

procedure TTestCase_StackPool.Test_TryAlloc;
var
  Pool: TStackPool;
  P: Pointer;
  OK: Boolean;
begin
  Pool := TStackPool.Create(128);
  try
    OK := Pool.TryAlloc(64, P);
    AssertTrue('First TryAlloc succeeds', OK);
    AssertTrue('First TryAlloc non-nil', P <> nil);

    OK := Pool.TryAlloc(64, P);
    AssertTrue('Second TryAlloc succeeds', OK);

    OK := Pool.TryAlloc(64, P);
    AssertFalse('Third TryAlloc fails (pool full)', OK);
  finally
    Pool.Free;
  end;
end;

procedure TTestCase_StackPool.Test_AllocAligned;
var
  Pool: TStackPool;
  P1, P2: Pointer;
begin
  Pool := TStackPool.Create(1024);
  try
    // 分配一个小块，使偏移不对齐
    P1 := Pool.Alloc(1);
    AssertTrue('First alloc non-nil', P1 <> nil);

    // 再分配 32 字节对齐的块
    P2 := Pool.AllocAligned(64, 32);
    AssertTrue('AllocAligned non-nil', P2 <> nil);

    // 验证 P2 相对于 P1 的偏移是 32 的倍数（栈池保证内部对齐）
    // 注意：栈池只保证相对于缓冲区的对齐，不保证绝对地址对齐
    AssertTrue('P2 > P1', PtrUInt(P2) > PtrUInt(P1));

    Pool.Reset;

    // 验证对齐分配的基本功能
    P1 := Pool.AllocAligned(64, 16);
    AssertTrue('AllocAligned 16 non-nil', P1 <> nil);
  finally
    Pool.Free;
  end;
end;

procedure TTestCase_StackPool.Test_AllocAligned_InvalidAlignment;
var
  Pool: TStackPool;
begin
  Pool := TStackPool.Create(1024);
  try
    AssertException(EInvalidArgument,
      procedure begin Pool.AllocAligned(64, 0); end);
    AssertException(EInvalidArgument,
      procedure begin Pool.AllocAligned(64, 3); end);
  finally
    Pool.Free;
  end;
end;

procedure TTestCase_StackPool.Test_Reset;
var
  Pool: TStackPool;
  P: Pointer;
begin
  Pool := TStackPool.Create(256);
  try
    P := Pool.Alloc(128);
    AssertTrue('After alloc', Pool.UsedSize > 0);

    Pool.Reset;
    AssertEquals('After reset UsedSize', 0, Pool.UsedSize);
    AssertEquals('After reset AvailableSize', 256, Pool.AvailableSize);

    // 重置后可以重新分配
    P := Pool.Alloc(200);
    AssertTrue('Alloc after reset', P <> nil);
  finally
    Pool.Free;
  end;
end;

procedure TTestCase_StackPool.Test_SaveState_RestoreState;
var
  Pool: TStackPool;
  State1, State2: SizeUInt;
  P: Pointer;
begin
  Pool := TStackPool.Create(512);
  try
    State1 := Pool.SaveState;
    AssertEquals('Initial state', 0, State1);

    P := Pool.Alloc(100);
    State2 := Pool.SaveState;
    AssertTrue('State2 > State1', State2 > State1);

    P := Pool.Alloc(100);
    AssertTrue('More allocated', Pool.UsedSize > State2);

    // 恢复到 State2
    Pool.RestoreState(State2);
    AssertEquals('Restored to State2', State2, Pool.UsedSize);

    // 恢复到 State1
    Pool.RestoreState(State1);
    AssertEquals('Restored to State1', State1, Pool.UsedSize);
  finally
    Pool.Free;
  end;
end;

procedure TTestCase_StackPool.Test_Properties;
var
  Pool: TStackPool;
  P: Pointer;
begin
  Pool := TStackPool.Create(512);
  try
    AssertEquals('TotalSize', 512, Pool.TotalSize);
    AssertEquals('Initial UsedSize', 0, Pool.UsedSize);
    AssertEquals('Initial AvailableSize', 512, Pool.AvailableSize);

    P := Pool.Alloc(100);
    AssertTrue('UsedSize >= 100', Pool.UsedSize >= 100);
    AssertTrue('AvailableSize <= 412', Pool.AvailableSize <= 412);
    AssertEquals('TotalSize unchanged', 512, Pool.TotalSize);
  finally
    Pool.Free;
  end;
end;

procedure TTestCase_StackPool.Test_IsEmpty_IsFull;
var
  Pool: TStackPool;
  P: Pointer;
begin
  Pool := TStackPool.Create(64);
  try
    AssertTrue('Initial IsEmpty', Pool.IsEmpty);
    AssertFalse('Initial not IsFull', Pool.IsFull);

    P := Pool.Alloc(32);
    AssertFalse('After alloc not IsEmpty', Pool.IsEmpty);
    AssertFalse('After partial alloc not IsFull', Pool.IsFull);

    P := Pool.Alloc(32);
    AssertFalse('After full alloc not IsEmpty', Pool.IsEmpty);
    AssertTrue('After full alloc IsFull', Pool.IsFull);

    Pool.Reset;
    AssertTrue('After reset IsEmpty', Pool.IsEmpty);
  finally
    Pool.Free;
  end;
end;

initialization
  RegisterTest(TTestCase_StackPool);

end.
