{$CODEPAGE UTF8}
unit test_crt_manager_allocator;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.mem.allocator.base,
  {$IFDEF FAFAFA_CORE_CRT_ALLOCATOR}
  fafafa.core.mem.allocator.crtAllocator
  {$ENDIF}
  ;

type
  TTestCase_Global = class(TTestCase)
  published
    procedure Test_GetCrtAllocator_Smoke;
  end;

  TTestCase_TCrtAllocator = class(TTestCase)
  published
    procedure Test_Alloc_Free_64;
    procedure Test_Realloc_64_256;
    procedure Test_Traits_ZeroInitialized;
    procedure Test_Traits_ThreadSafe;
    procedure Test_Traits_SupportsAligned_False;
    procedure Test_Traits_HasMemSize_False;
  end;

implementation

procedure TTestCase_Global.Test_GetCrtAllocator_Smoke;
{$IFDEF FAFAFA_CORE_CRT_ALLOCATOR}
var
  Alloc: IAllocator;
{$ENDIF}
begin
  {$IFDEF FAFAFA_CORE_CRT_ALLOCATOR}
  Alloc := GetCrtAllocator;
  AssertTrue('GetCrtAllocator should return non-nil', Alloc <> nil);
  {$ELSE}
  AssertTrue('CRT allocator macro disabled: no-op', True);
  {$ENDIF}
end;

procedure TTestCase_TCrtAllocator.Test_Alloc_Free_64;
{$IFDEF FAFAFA_CORE_CRT_ALLOCATOR}
var
  Alloc: IAllocator;
  P: Pointer;
{$ENDIF}
begin
  {$IFDEF FAFAFA_CORE_CRT_ALLOCATOR}
  Alloc := GetCrtAllocator;
  P := Alloc.AllocMem(64);
  AssertNotNull('AllocMem(64) should return non-nil', P);
  Alloc.FreeMem(P);
  {$ELSE}
  AssertTrue('CRT allocator macro disabled: no-op', True);
  {$ENDIF}
end;

procedure TTestCase_TCrtAllocator.Test_Realloc_64_256;
{$IFDEF FAFAFA_CORE_CRT_ALLOCATOR}
var
  Alloc: IAllocator;
  P: Pointer;
{$ENDIF}
begin
  {$IFDEF FAFAFA_CORE_CRT_ALLOCATOR}
  Alloc := GetCrtAllocator;
  P := Alloc.AllocMem(64);
  AssertNotNull('AllocMem(64) should return non-nil', P);
  P := Alloc.ReallocMem(P, 256);
  AssertNotNull('ReallocMem(256) should return non-nil', P);
  Alloc.FreeMem(P);
  {$ELSE}
  AssertTrue('CRT allocator macro disabled: no-op', True);
  {$ENDIF}
end;

procedure TTestCase_TCrtAllocator.Test_Traits_ZeroInitialized;
{$IFDEF FAFAFA_CORE_CRT_ALLOCATOR}
var
  Alloc: IAllocator;
  T: TAllocatorTraits;
{$ENDIF}
begin
  {$IFDEF FAFAFA_CORE_CRT_ALLOCATOR}
  Alloc := GetCrtAllocator;
  T := Alloc.Traits;
  AssertTrue('ZeroInitialized should be True for AllocMem', T.ZeroInitialized);
  {$ELSE}
  AssertTrue('CRT allocator macro disabled: no-op', True);
  {$ENDIF}
end;

procedure TTestCase_TCrtAllocator.Test_Traits_ThreadSafe;
{$IFDEF FAFAFA_CORE_CRT_ALLOCATOR}
var
  Alloc: IAllocator;
  T: TAllocatorTraits;
{$ENDIF}
begin
  {$IFDEF FAFAFA_CORE_CRT_ALLOCATOR}
  Alloc := GetCrtAllocator;
  T := Alloc.Traits;
  AssertTrue('ThreadSafe should be True by default', T.ThreadSafe);
  {$ELSE}
  AssertTrue('CRT allocator macro disabled: no-op', True);
  {$ENDIF}
end;

procedure TTestCase_TCrtAllocator.Test_Traits_SupportsAligned_False;
{$IFDEF FAFAFA_CORE_CRT_ALLOCATOR}
var
  Alloc: IAllocator;
  T: TAllocatorTraits;
{$ENDIF}
begin
  {$IFDEF FAFAFA_CORE_CRT_ALLOCATOR}
  Alloc := GetCrtAllocator;
  T := Alloc.Traits;
  AssertFalse('SupportsAligned should be False (use aligned bridge)', T.SupportsAligned);
  {$ELSE}
  AssertTrue('CRT allocator macro disabled: no-op', True);
  {$ENDIF}
end;

procedure TTestCase_TCrtAllocator.Test_Traits_HasMemSize_False;
{$IFDEF FAFAFA_CORE_CRT_ALLOCATOR}
var
  Alloc: IAllocator;
  T: TAllocatorTraits;
{$ENDIF}
begin
  {$IFDEF FAFAFA_CORE_CRT_ALLOCATOR}
  Alloc := GetCrtAllocator;
  T := Alloc.Traits;
  AssertFalse('HasMemSize should be False by default', T.HasMemSize);
  {$ELSE}
  AssertTrue('CRT allocator macro disabled: no-op', True);
  {$ENDIF}
end;

initialization
  RegisterTest(TTestCase_Global);
  RegisterTest(TTestCase_TCrtAllocator);

end.

