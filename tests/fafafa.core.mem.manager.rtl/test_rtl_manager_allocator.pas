{$CODEPAGE UTF8}
unit test_rtl_manager_allocator;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.mem.allocator.base,
  fafafa.core.mem.allocator.rtlAllocator;

type
  TTestCase_Global = class(TTestCase)
  published
    procedure Test_GetRtlAllocator_Smoke;
  end;

  TTestCase_TRtlAllocator = class(TTestCase)
  published
    procedure Test_Alloc_Free_64;
    procedure Test_Realloc_64_256;
    procedure Test_Traits_ZeroInitialized;
    procedure Test_Traits_ThreadSafe;
    procedure Test_Traits_SupportsAligned_False;
    procedure Test_Traits_HasMemSize_False;
  end;

implementation

procedure TTestCase_Global.Test_GetRtlAllocator_Smoke;
var
  Alloc: IAllocator;
begin
  Alloc := GetRtlAllocator;
  AssertTrue('GetRtlAllocator should return non-nil', Alloc <> nil);
end;

procedure TTestCase_TRtlAllocator.Test_Alloc_Free_64;
var
  Alloc: IAllocator;
  P: Pointer;
begin
  Alloc := GetRtlAllocator;
  P := Alloc.AllocMem(64);
  AssertNotNull('AllocMem(64) should return non-nil', P);
  Alloc.FreeMem(P);
end;

procedure TTestCase_TRtlAllocator.Test_Realloc_64_256;
var
  Alloc: IAllocator;
  P: Pointer;
begin
  Alloc := GetRtlAllocator;
  P := Alloc.AllocMem(64);
  AssertNotNull('AllocMem(64) should return non-nil', P);
  P := Alloc.ReallocMem(P, 256);
  AssertNotNull('ReallocMem(256) should return non-nil', P);
  Alloc.FreeMem(P);
end;

procedure TTestCase_TRtlAllocator.Test_Traits_ZeroInitialized;
var
  Alloc: IAllocator;
  T: TAllocatorTraits;
begin
  Alloc := GetRtlAllocator;
  T := Alloc.Traits;
  AssertTrue('ZeroInitialized should be True for AllocMem', T.ZeroInitialized);
end;

procedure TTestCase_TRtlAllocator.Test_Traits_ThreadSafe;
var
  Alloc: IAllocator;
  T: TAllocatorTraits;
begin
  Alloc := GetRtlAllocator;
  T := Alloc.Traits;
  AssertTrue('ThreadSafe should be True by default', T.ThreadSafe);
end;

procedure TTestCase_TRtlAllocator.Test_Traits_SupportsAligned_False;
var
  Alloc: IAllocator;
  T: TAllocatorTraits;
begin
  Alloc := GetRtlAllocator;
  T := Alloc.Traits;
  AssertFalse('SupportsAligned should be False (use aligned bridge)', T.SupportsAligned);
end;

procedure TTestCase_TRtlAllocator.Test_Traits_HasMemSize_False;
var
  Alloc: IAllocator;
  T: TAllocatorTraits;
begin
  Alloc := GetRtlAllocator;
  T := Alloc.Traits;
  AssertFalse('HasMemSize should be False by default', T.HasMemSize);
end;


initialization
  RegisterTest(TTestCase_Global);
  RegisterTest(TTestCase_TRtlAllocator);

end.

