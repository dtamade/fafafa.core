{$CODEPAGE UTF8}
unit fafafa.core.mem.pool.slab.testcase;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

{$PUSH}
{$WARN 4055 OFF} // pointer/ordinal conversions in alignment assertions

interface

uses
  SysUtils, Classes, fpcunit, testregistry,
  fafafa.core.mem.allocator.base,
  fafafa.core.mem.pool.slab,
  fafafa.core.mem.pool.slab.concurrent,
  fafafa.core.mem.pool.slab.sharded;

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
    FFallbackPtr: Pointer;
    procedure DoFreeFallbackPtr;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure Test_Create_overload1;
    procedure Test_Create_overload2;
    procedure Test_GetMem_zero;
    procedure Test_GetMem_small;
    procedure Test_GetMem_oversize_defaultPolicy;
    procedure Test_AllocAligned_requires_fallback_FreeMem_ok;
    procedure Test_FreeMem_nil;
    procedure Test_FreeMem_basic;
    procedure Test_ReallocMem_nil_to_new;
    procedure Test_ReallocMem_shrink;
    procedure Test_ReallocMem_grow_cross_segment_keeps_prefix;
    procedure Test_Acquire_Release_Reset;
    procedure Test_Reset_invalidates_fallback_ptr;
    procedure Test_Compat_Alloc_Free_Warmup;
    procedure Test_Traits_AllFields;
    procedure Test_Counters_TotalAllocs_TotalFrees;
  end;

  { TTestCase_TSlabPoolConcurrent }
  TTestCase_TSlabPoolConcurrent = class(TTestCase)
  private
    FPool: TSlabPoolConcurrent;
    FFallbackPtr: Pointer;
    procedure DoFreeFallbackPtr;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure Test_Basic_Alloc_Free;
    procedure Test_Traits_ThreadSafe;
    procedure Test_PerfCounters_Basic;
    procedure Test_Reset_invalidates_fallback_ptr;
  end;

  { TTestCase_TSlabPoolSharded }
  TTestCase_TSlabPoolSharded = class(TTestCase)
  private
    type
      TFreeThread = class(TThread)
      private
        FPool: TSlabPoolSharded;
        FPtrs: array of Pointer;
      public
        ErrorMessage: string;
        constructor Create(aPool: TSlabPoolSharded; const aPtrs: array of Pointer);
      protected
        procedure Execute; override;
      end;
  private
    FPool: TSlabPoolSharded;
    FFallbackPtr: Pointer;
    procedure DoFreeFallbackPtr;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure Test_Basic_Alloc_Free;
    procedure Test_Traits_ThreadSafe;
    procedure Test_PerfCounters_Basic;
    procedure Test_Reset_invalidates_fallback_ptr;
    procedure Test_CrossThread_Free_Mixed;
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
  FFallbackPtr := nil;
end;

procedure TTestCase_TSlabPool.TearDown;
begin
  FreeAndNil(FPool);
  inherited TearDown;
end;

procedure TTestCase_TSlabPool.DoFreeFallbackPtr;
begin
  FPool.FreeMem(FFallbackPtr);
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
  p := FPool.GetMem(256*1024); // > initial capacity => fallback allocation
  AssertNotNull(p);
  FPool.FreeMem(p);
end;

procedure TTestCase_TSlabPool.Test_AllocAligned_requires_fallback_FreeMem_ok;
var p: Pointer;
begin
  // 24 bytes 的自然 chunk 通常为 32，对齐 64 必须走 fallback
  p := FPool.AllocAligned(24, 64);
  AssertNotNull(p);
  AssertTrue((PtrUInt(p) and (64 - 1)) = 0);
  // 关键：即使来自 AllocAligned，也允许使用 FreeMem 释放（对齐语义由池内部追踪）
  FPool.FreeMem(p);
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

procedure TTestCase_TSlabPool.Test_Reset_invalidates_fallback_ptr;
begin
  FFallbackPtr := FPool.GetMem(256*1024);
  AssertNotNull(FFallbackPtr);
  FPool.Reset;
  AssertException(ESlabPoolCorruption, @DoFreeFallbackPtr);
end;

procedure TTestCase_TSlabPool.Test_Compat_Alloc_Free_Warmup;
var p: Pointer; n: SizeUInt;
begin
  p := FPool.Alloc(64);
  AssertNotNull(p);
  FPool.Free(p);
  n := FPool.Warmup(64, 2);
  AssertTrue(n > 0);
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

{ TTestCase_TSlabPoolConcurrent }

procedure TTestCase_TSlabPoolConcurrent.SetUp;
begin
  inherited SetUp;
  FPool := TSlabPoolConcurrent.Create(64*1024);
  FFallbackPtr := nil;
end;

procedure TTestCase_TSlabPoolConcurrent.TearDown;
begin
  FreeAndNil(FPool);
  inherited TearDown;
end;

procedure TTestCase_TSlabPoolConcurrent.DoFreeFallbackPtr;
begin
  FPool.FreeMem(FFallbackPtr);
end;

procedure TTestCase_TSlabPoolConcurrent.Test_Basic_Alloc_Free;
var
  LPtr: Pointer;
begin
  LPtr := FPool.GetMem(128);
  AssertNotNull(LPtr);
  FPool.FreeMem(LPtr);

  LPtr := FPool.AllocAligned(24, 64);
  AssertNotNull(LPtr);
  AssertTrue((PtrUInt(LPtr) and (64 - 1)) = 0);
  FPool.FreeMem(LPtr);

  LPtr := FPool.GetMem(256*1024);
  AssertNotNull(LPtr);
  FPool.FreeMem(LPtr);
end;

procedure TTestCase_TSlabPoolConcurrent.Test_Traits_ThreadSafe;
var
  T: TAllocatorTraits;
begin
  T := FPool.Traits;
  AssertTrue(T.ThreadSafe);
end;

procedure TTestCase_TSlabPoolConcurrent.Test_PerfCounters_Basic;
var
  LPtr: Pointer;
  LPerf: TSlabPerfCounters;
begin
  LPtr := FPool.GetMem(64);
  AssertNotNull(LPtr);
  FPool.FreeMem(LPtr);

  LPerf := FPool.GetPerfCounters;
  AssertTrue('AllocCalls should be > 0', LPerf.AllocCalls > 0);
  AssertTrue('FreeCalls should be > 0', LPerf.FreeCalls > 0);
end;

procedure TTestCase_TSlabPoolConcurrent.Test_Reset_invalidates_fallback_ptr;
begin
  FFallbackPtr := FPool.GetMem(256*1024);
  AssertNotNull(FFallbackPtr);
  FPool.Reset;
  AssertException(ESlabPoolCorruption, @DoFreeFallbackPtr);
end;

{ TTestCase_TSlabPoolSharded.TFreeThread }

constructor TTestCase_TSlabPoolSharded.TFreeThread.Create(aPool: TSlabPoolSharded; const aPtrs: array of Pointer);
var
  LIdx: Integer;
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FPool := aPool;
  SetLength(FPtrs, Length(aPtrs));
  for LIdx := 0 to High(aPtrs) do
    FPtrs[LIdx] := aPtrs[LIdx];
  Start;
end;

procedure TTestCase_TSlabPoolSharded.TFreeThread.Execute;
var
  LIdx: Integer;
begin
  try
    for LIdx := 0 to High(FPtrs) do
      FPool.FreeMem(FPtrs[LIdx]);
  except
    on E: Exception do
      ErrorMessage := E.ClassName + ': ' + E.Message;
  end;
end;

{ TTestCase_TSlabPoolSharded }

procedure TTestCase_TSlabPoolSharded.SetUp;
begin
  inherited SetUp;
  FPool := TSlabPoolSharded.Create(16*1024, 4);
  FFallbackPtr := nil;
end;

procedure TTestCase_TSlabPoolSharded.TearDown;
begin
  FreeAndNil(FPool);
  inherited TearDown;
end;

procedure TTestCase_TSlabPoolSharded.DoFreeFallbackPtr;
begin
  FPool.FreeMem(FFallbackPtr);
end;

procedure TTestCase_TSlabPoolSharded.Test_Basic_Alloc_Free;
var
  LPtr: Pointer;
begin
  LPtr := FPool.GetMem(128);
  AssertNotNull(LPtr);
  FPool.FreeMem(LPtr);

  LPtr := FPool.AllocAligned(24, 64);
  AssertNotNull(LPtr);
  AssertTrue((PtrUInt(LPtr) and (64 - 1)) = 0);
  FPool.FreeMem(LPtr);

  LPtr := FPool.GetMem(256*1024);
  AssertNotNull(LPtr);
  FPool.FreeMem(LPtr);
end;

procedure TTestCase_TSlabPoolSharded.Test_Traits_ThreadSafe;
var
  T: TAllocatorTraits;
begin
  T := FPool.Traits;
  AssertTrue(T.ThreadSafe);
end;

procedure TTestCase_TSlabPoolSharded.Test_PerfCounters_Basic;
var
  LPtr: Pointer;
  LPerf: TSlabPerfCounters;
begin
  LPtr := FPool.GetMem(64);
  AssertNotNull(LPtr);
  FPool.FreeMem(LPtr);

  LPerf := FPool.GetPerfCounters;
  AssertTrue('AllocCalls should be > 0', LPerf.AllocCalls > 0);
  AssertTrue('FreeCalls should be > 0', LPerf.FreeCalls > 0);
end;

procedure TTestCase_TSlabPoolSharded.Test_Reset_invalidates_fallback_ptr;
begin
  FFallbackPtr := FPool.GetMem(256*1024);
  AssertNotNull(FFallbackPtr);
  FPool.Reset;
  AssertException(ESlabPoolCorruption, @DoFreeFallbackPtr);
end;

procedure TTestCase_TSlabPoolSharded.Test_CrossThread_Free_Mixed;
var
  LPtrs: array of Pointer;
  LIdx: Integer;
  LTh: TFreeThread;
  LBaselineSeg: Integer;
begin
  LPtrs := nil;
  SetLength(LPtrs, 0);

  // 强制同一线程分配，触发某个 shard 产生新 segment（验证路由表增量索引）
  LBaselineSeg := FPool.SegmentCount;
  for LIdx := 0 to 63 do
  begin
    SetLength(LPtrs, Length(LPtrs) + 1);
    LPtrs[High(LPtrs)] := FPool.GetMem(4096);
    AssertNotNull(LPtrs[High(LPtrs)]);
    if FPool.SegmentCount > LBaselineSeg then
      Break;
  end;

  // 追加一些小对象（slab）与 fallback（对齐/大对象）
  for LIdx := 0 to 127 do
  begin
    SetLength(LPtrs, Length(LPtrs) + 1);
    LPtrs[High(LPtrs)] := FPool.GetMem(64);
    AssertNotNull(LPtrs[High(LPtrs)]);
  end;

  for LIdx := 0 to 63 do
  begin
    SetLength(LPtrs, Length(LPtrs) + 1);
    LPtrs[High(LPtrs)] := FPool.AllocAligned(24, 64);
    AssertNotNull(LPtrs[High(LPtrs)]);
  end;

  for LIdx := 0 to 3 do
  begin
    SetLength(LPtrs, Length(LPtrs) + 1);
    LPtrs[High(LPtrs)] := FPool.GetMem(256*1024);
    AssertNotNull(LPtrs[High(LPtrs)]);
  end;

  LTh := TFreeThread.Create(FPool, LPtrs);
  try
    LTh.WaitFor;
    AssertEquals('', LTh.ErrorMessage);
  finally
    LTh.Free;
  end;
end;

initialization
  RegisterTest(TTestCase_Global);
  RegisterTest(TTestCase_TSlabPool);
  RegisterTest(TTestCase_TSlabPoolConcurrent);
  RegisterTest(TTestCase_TSlabPoolSharded);

{$POP}

end.
