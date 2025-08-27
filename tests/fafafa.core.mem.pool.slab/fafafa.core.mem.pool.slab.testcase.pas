{$CODEPAGE UTF8}
unit fafafa.core.mem.pool.slab.testcase;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.mem.allocator,
  fafafa.core.mem.allocator.base,
  fafafa.core.mem.pool.slab;

type
  { TTestCase_Global }
  TTestCase_Global = class(TTestCase)
  published
    procedure Test_CreateDefaultSlabConfig;
    procedure Test_CreateSlabConfigWithPageMerging;
  end;

  { TTestCase_TSlabPool }
  TTestCase_TSlabPool = class(TTestCase)
  private
    FPool: TSlabPool;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure Test_Create_overload1;
    procedure Test_Create_overload2;
    procedure Test_GetMem_zero;
    procedure Test_GetMem_small;
    procedure Test_GetMem_oversize_defaultPolicy;
    procedure Test_FreeMem_nil;
    procedure Test_FreeMem_basic;
    procedure Test_ReallocMem_nil_to_new;
    procedure Test_ReallocMem_shrink;
    procedure Test_ReallocMem_grow_cross_segment_keeps_prefix;
    procedure Test_Acquire_Release_Reset;
    procedure Test_Compat_Alloc_Free_Warmup;
    procedure Test_Traits_AllFields;
    procedure Test_Counters_TotalAllocs_TotalFrees;
  end;

implementation

procedure TTestCase_Global.Test_CreateDefaultSlabConfig;
var C: TSlabConfig;
begin
  C := CreateDefaultSlabConfig;
  AssertEquals('MinShift default=3', 3, C.MinShift);
  AssertFalse('PageMerging default=False', C.EnablePageMerging);
end;

procedure TTestCase_Global.Test_CreateSlabConfigWithPageMerging;
var C: TSlabConfig;
begin
  C := CreateSlabConfigWithPageMerging;
  AssertTrue(C.EnablePageMerging);
end;

procedure TTestCase_TSlabPool.SetUp;
begin
  inherited SetUp;
  FPool := TSlabPool.Create(64*1024);
end;

procedure TTestCase_TSlabPool.TearDown;
begin
  FreeAndNil(FPool);
  inherited TearDown;
end;

procedure TTestCase_TSlabPool.Test_Create_overload1;
var P: TSlabPool;
begin
  P := TSlabPool.Create(32*1024);
  try
    AssertNotNull(P);
  finally
    P.Free;
  end;
end;

procedure TTestCase_TSlabPool.Test_Create_overload2;
var P: TSlabPool; C: TSlabConfig;
begin
  C := CreateDefaultSlabConfig;
  P := TSlabPool.Create(32*1024, C);
  try
    AssertNotNull(P);
  finally
    P.Free;
  end;
end;

procedure TTestCase_TSlabPool.Test_GetMem_zero;
var p: Pointer;
begin
  p := FPool.GetMem(0);
  AssertNull(p);
end;

procedure TTestCase_TSlabPool.Test_GetMem_small;
var p: Pointer;
begin
  p := FPool.GetMem(128);
  AssertNotNull(p);
  FPool.FreeMem(p);
end;

procedure TTestCase_TSlabPool.Test_GetMem_oversize_defaultPolicy;
var p: Pointer;
begin
  p := FPool.GetMem(256*1024); // > initial capacity => denied by default policy
  AssertNull(p);
end;

procedure TTestCase_TSlabPool.Test_FreeMem_nil;
begin
  FPool.FreeMem(nil);
end;

procedure TTestCase_TSlabPool.Test_FreeMem_basic;
var p: Pointer;
begin
  p := FPool.GetMem(256);
  AssertNotNull(p);
  FPool.FreeMem(p);
end;

procedure TTestCase_TSlabPool.Test_ReallocMem_nil_to_new;
var p: Pointer;
begin
  p := FPool.ReallocMem(nil, 512);
  AssertNotNull(p);
  FPool.FreeMem(p);
end;

procedure TTestCase_TSlabPool.Test_ReallocMem_shrink;
var p, q: PByte;
begin
  p := FPool.GetMem(512);
  AssertNotNull(p);
  q := FPool.ReallocMem(p, 128);
  AssertNotNull(q);
  FPool.FreeMem(q);
end;

procedure TTestCase_TSlabPool.Test_ReallocMem_grow_cross_segment_keeps_prefix;
var p, q: PByte; i: Integer;
begin
  p := FPool.GetMem(4096);
  AssertNotNull(p);
  for i:=0 to 255 do p[i] := i mod 256;
  q := FPool.ReallocMem(p, 4096*4);
  AssertNotNull(q);
  for i:=0 to 255 do AssertEquals(i mod 256, q[i]);
  FPool.FreeMem(q);
end;

procedure TTestCase_TSlabPool.Test_Acquire_Release_Reset;
var p: Pointer; ok: Boolean;
begin
  p := nil;
  ok := FPool.Acquire(p);
  AssertTrue(ok);
  AssertNotNull(p);
  FPool.Release(p);
  FPool.Reset;
end;

procedure TTestCase_TSlabPool.Test_Compat_Alloc_Free_Warmup;
var p: Pointer; n: SizeUInt;
begin
  p := FPool.Alloc(64);
  AssertNotNull(p);
  FPool.Free(p);
  n := FPool.Warmup(64, 2);
  AssertTrue(n >= 0);
end;

procedure TTestCase_TSlabPool.Test_Traits_AllFields;
var T: TAllocatorTraits;
begin
  T := FPool.Traits;
  AssertTrue(T.ZeroInitialized);
  AssertFalse(T.ThreadSafe);
  AssertTrue(T.HasMemSize);
  AssertFalse(T.SupportsAligned);
end;

procedure TTestCase_TSlabPool.Test_Counters_TotalAllocs_TotalFrees;
var p1, p2: Pointer;
begin
  p1 := FPool.GetMem(32);
  p2 := FPool.GetMem(64);
  AssertEquals(2, FPool.TotalAllocs);
  FPool.FreeMem(p1);
  FPool.FreeMem(p2);
  AssertEquals(2, FPool.TotalFrees);
end;

initialization
  RegisterTest(TTestCase_Global);
  RegisterTest(TTestCase_TSlabPool);

end.

