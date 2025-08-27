unit fafafa.core.mem.pool.fixed.growable.testcase;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.mem.pool.fixed.growable,
  fafafa.core.mem.pool.base;

type
  TTestCase_TGrowingFixedPool = class(TTestCase)
  private
    FPool: IPool;
    FGrow: TGrowingFixedPool; // concrete for ShrinkTo tests
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure Test_AutoGrowth_Geometric;
    procedure Test_IPool_Interface;
    procedure Test_InvalidPointer_Raises;
    procedure Test_Reset_RebuildsFreeStack;
    procedure Test_ShrinkTo_ReleasesTailArenas;
    procedure Test_MaxCapacity_Limit;
  end;

procedure RegisterTests;

implementation

procedure RegisterTests;
begin
  RegisterTest('TGrowingFixedPool', TTestCase_TGrowingFixedPool.Suite);
end;

procedure TTestCase_TGrowingFixedPool.SetUp;
var
  C: TGrowingFixedPoolConfig;
begin
  FillChar(C, SizeOf(C), 0);
  C.BlockSize := 16;
  C.InitialCapacity := 4;
  C.GrowthKind := gkGeometric;
  C.GrowthFactor := 2.0;
  C.ZeroOnInit := False;
  FGrow := TGrowingFixedPool.Create(C);
  FPool := FGrow as IPool;
end;

procedure TTestCase_TGrowingFixedPool.TearDown;
begin
  // 注意：FGrow 与 FPool 指向同一对象（引用计数对象）。
  // 先清理接口引用，触发引用计数释放；不要对 FGrow 再次 Free。
  FPool := nil;
  FGrow := nil;
end;

procedure TTestCase_TGrowingFixedPool.Test_AutoGrowth_Geometric;
var
  i: Integer; PArr: array[0..9] of Pointer;
begin
  // 初始容量 4，申请 10 个，至少触发两次增长
  for i := 0 to 9 do
    CheckTrue(FPool.Acquire(PArr[i]));
  // 释放 10 个（逐个释放对应指针）
  for i := 0 to 9 do
    FPool.Release(PArr[i]);
end;

procedure TTestCase_TGrowingFixedPool.Test_IPool_Interface;
var
  i: Integer; u: Pointer;
begin
  // 满容量 + 自动增长
  for i := 1 to 8 do CheckTrue(FPool.Acquire(u));
  // 再申请应触发增长
  CheckTrue(FPool.Acquire(u));
  // Reset 后可再次满载
  FPool.Reset;
  for i := 1 to 8 do CheckTrue(FPool.Acquire(u));
end;

procedure TTestCase_TGrowingFixedPool.Test_InvalidPointer_Raises;
var
  bad: Pointer; u: Pointer;
begin
  CheckTrue(FPool.Acquire(u));
  bad := GetMem(16);
  try
    try
      FPool.Release(bad);
      Fail('Expected invalid pointer');
    except
      on E: Exception do
        CheckTrue(Pos('belong to this pool', E.Message) > 0);
    end;
  finally
    FreeMem(bad);
  end;
end;

procedure TTestCase_TGrowingFixedPool.Test_Reset_RebuildsFreeStack;
var
  i: Integer; p: Pointer;
begin
  for i := 1 to 6 do CheckTrue(FPool.Acquire(p));
  FPool.Reset;
  // 应能再次获取与当前总容量等量的块
  for i := 1 to 6 do CheckTrue(FPool.Acquire(p));
end;


procedure TTestCase_TGrowingFixedPool.Test_ShrinkTo_ReleasesTailArenas;
var
  GF: TGrowingFixedPool;
  i: Integer;
  arr: array of Pointer;
  beforeCap, afterCap: SizeUInt;
  freed: SizeUInt;
begin
  // 触发扩容
  SetLength(arr, 12);
  for i := 0 to High(arr) do CheckTrue(FPool.Acquire(arr[i]));
  // 释放全部块，使末尾 Arena 空闲
  for i := 0 to High(arr) do FPool.Release(arr[i]);

  GF := FGrow;
  beforeCap := GF.TotalCapacity;
  // 收缩至不小于初始容量（4）
  freed := GF.ShrinkTo(4);
  afterCap := GF.TotalCapacity;

  CheckTrue(freed > 0);
  CheckTrue(afterCap >= 4);
  CheckEquals(beforeCap - afterCap, freed);
end;

procedure TTestCase_TGrowingFixedPool.Test_MaxCapacity_Limit;
var
  C: TGrowingFixedPoolConfig;
  P: IPool;
  u: Pointer;
  ok: Boolean;
  count: Integer;
begin
  // MaxCapacity=3，最多只能成功获取3次
  FillChar(C, SizeOf(C), 0);
  C.BlockSize := 16;
  C.InitialCapacity := 2;
  C.GrowthKind := gkGeometric;
  C.GrowthFactor := 2.0;
  C.MaxCapacity := 3;
  P := TGrowingFixedPool.Create(C) as IPool;

  count := 0;
  repeat
    ok := P.Acquire(u);
    if ok then Inc(count);
  until not ok;

  CheckEquals(3, count);
end;

end.

