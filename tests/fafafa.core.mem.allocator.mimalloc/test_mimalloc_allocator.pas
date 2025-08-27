{$CODEPAGE UTF8}
unit test_mimalloc_allocator;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testregistry
  {$IFDEF FAFAFA_CORE_MIMALLOC_ALLOCATOR}
  ,dynlibs, fafafa.core.mem.allocator.mimalloc, fafafa.core.mem.allocator.base
  {$ENDIF}
  ;

type
  // 全局函数/延迟绑定路径（B.3）
  TTestCase_Global = class(TTestCase)
  published
    procedure Test_DelayedBind_mi_malloc_free;
  end;

  // 对象/接口路径（B.4）
  TTestCase_MimallocAllocator = class(TTestCase)
  published
    procedure Test_GetMimallocAllocator_Smoke;
    procedure Test_Alloc_Free_128;
    procedure Test_Realloc_128_512;
  end;
  TTestCase_MimallocAllocator_Traits = class(TTestCase)
  published
    procedure Test_Traits_ZeroInitialized;
    procedure Test_Traits_ThreadSafe;
  end;
  TTestCase_MimallocAllocator_Traits2 = class(TTestCase)
  published
    procedure Test_Traits_SupportsAligned_False;
    procedure Test_Traits_HasMemSize_False;
  end;
  TTestCase_MimallocAllocator_Optional = class(TTestCase)
  published
    procedure Test_TryGetMimallocAllocator_NoThrow;
  end;

implementation

procedure TTestCase_Global.Test_DelayedBind_mi_malloc_free;
{$IFDEF FAFAFA_CORE_MIMALLOC_ALLOCATOR}
  type
    Tmi_malloc = function(size: SizeUInt): Pointer; cdecl;
    Tmi_free   = procedure(p: Pointer); cdecl;
  var
    Lib: TLibHandle;
    FMalloc: Tmi_malloc;
    FFree: Tmi_free;
    P: Pointer;
{$ENDIF}
begin
  {$IFDEF FAFAFA_CORE_MIMALLOC_ALLOCATOR}
  Lib := LoadLibrary('mimalloc.dll');
  if Lib = 0 then Lib := LoadLibrary('mimalloc-redirect.dll');
  if Lib = 0 then Exit; // 跳过：未提供DLL
  try
    Pointer(FMalloc) := GetProcedureAddress(Lib, 'mi_malloc');
    Pointer(FFree)   := GetProcedureAddress(Lib, 'mi_free');
    if (not Assigned(FMalloc)) or (not Assigned(FFree)) then Exit; // 符号缺失：跳过
    P := FMalloc(128);
    AssertNotNull('mi_malloc(128) should return non-nil', P);
    FFree(P);
  finally
    FreeLibrary(Lib);
  end;
  {$ELSE}
  AssertTrue('Macro disabled: no-op', True);
  {$ENDIF}
end;

procedure TTestCase_MimallocAllocator.Test_GetMimallocAllocator_Smoke;
{$IFDEF FAFAFA_CORE_MIMALLOC_ALLOCATOR}
var
  Alloc: fafafa.core.mem.allocator.base.IAllocator;
  Lib: TLibHandle;
{$ENDIF}
begin
  {$IFDEF FAFAFA_CORE_MIMALLOC_ALLOCATOR}
  Lib := LoadLibrary('mimalloc.dll');
  if Lib = 0 then Lib := LoadLibrary('mimalloc-redirect.dll');
  if Lib = 0 then Exit; // 跳过：未提供DLL
  FreeLibrary(Lib);
  Alloc := GetMimallocAllocator;
  AssertTrue('GetMimallocAllocator should return non-nil', Alloc <> nil);
  {$ELSE}
  AssertTrue('Macro disabled: no-op', True);
  {$ENDIF}
end;

procedure TTestCase_MimallocAllocator.Test_Alloc_Free_128;
{$IFDEF FAFAFA_CORE_MIMALLOC_ALLOCATOR}
var
  Alloc: fafafa.core.mem.allocator.base.IAllocator;
  Lib: TLibHandle;
  P: Pointer;
{$ENDIF}
begin
  {$IFDEF FAFAFA_CORE_MIMALLOC_ALLOCATOR}
  Lib := LoadLibrary('mimalloc.dll');
  if Lib = 0 then Lib := LoadLibrary('mimalloc-redirect.dll');
  if Lib = 0 then Exit;
  FreeLibrary(Lib);
  Alloc := GetMimallocAllocator;
  P := Alloc.AllocMem(128);
  AssertNotNull('AllocMem(128) should return non-nil', P);
  Alloc.FreeMem(P);
  {$ELSE}
  AssertTrue('Macro disabled: no-op', True);
  {$ENDIF}
end;

procedure TTestCase_MimallocAllocator.Test_Realloc_128_512;
{$IFDEF FAFAFA_CORE_MIMALLOC_ALLOCATOR}
var
  Alloc: fafafa.core.mem.allocator.base.IAllocator;
  Lib: TLibHandle;
  P: Pointer;
{$ENDIF}
begin
  {$IFDEF FAFAFA_CORE_MIMALLOC_ALLOCATOR}
  Lib := LoadLibrary('mimalloc.dll');
  if Lib = 0 then Lib := LoadLibrary('mimalloc-redirect.dll');
  if Lib = 0 then Exit;
  FreeLibrary(Lib);
  Alloc := GetMimallocAllocator;
  P := Alloc.AllocMem(128);
  AssertNotNull('AllocMem(128) should return non-nil', P);
  P := Alloc.ReallocMem(P, 512);
  AssertNotNull('ReallocMem(512) should return non-nil', P);
  Alloc.FreeMem(P);
  {$ELSE}
  AssertTrue('Macro disabled: no-op', True);
  {$ENDIF}
end;

procedure TTestCase_MimallocAllocator_Optional.Test_TryGetMimallocAllocator_NoThrow;
{$IFDEF FAFAFA_CORE_MIMALLOC_ALLOCATOR}
var
  Alloc: fafafa.core.mem.allocator.base.IAllocator;
  Ok: Boolean;
  Lib: TLibHandle;
{$ENDIF}
begin
  {$IFDEF FAFAFA_CORE_MIMALLOC_ALLOCATOR}
  // 缺库时不抛异常，应返回 False（redirect 也算存在）
  Lib := LoadLibrary('mimalloc.dll');
  if (Lib = 0) then Lib := LoadLibrary('mimalloc-redirect.dll');
  if Lib <> 0 then
  begin
    FreeLibrary(Lib); // 有库时也应返回 True
    Ok := TryGetMimallocAllocator(Alloc);
    AssertTrue('TryGet should return True when dll is available', Ok);
    AssertTrue('Alloc not nil when available', Alloc <> nil);
  end
  else
  begin
    Ok := TryGetMimallocAllocator(Alloc);
    AssertFalse('TryGet should return False when dll missing', Ok);
    AssertTrue('Alloc should be nil when missing', Alloc = nil);
  end;
  {$ELSE}
  AssertTrue('Macro disabled: no-op', True);
  {$ENDIF}
end;

procedure TTestCase_MimallocAllocator_Traits.Test_Traits_ZeroInitialized;
{$IFDEF FAFAFA_CORE_MIMALLOC_ALLOCATOR}
var
  Alloc: fafafa.core.mem.allocator.base.IAllocator;
  Lib: TLibHandle;
  T: TAllocatorTraits;
{$ENDIF}
begin
  {$IFDEF FAFAFA_CORE_MIMALLOC_ALLOCATOR}
  Lib := LoadLibrary('mimalloc.dll');
  if (Lib = 0) then Lib := LoadLibrary('mimalloc-redirect.dll');
  if Lib = 0 then Exit; // 缺库：跳过
  FreeLibrary(Lib);
  Alloc := GetMimallocAllocator;
  T := Alloc.Traits;
  AssertTrue('ZeroInitialized should be True (mi_calloc)', T.ZeroInitialized);
  {$ELSE}
  AssertTrue('Macro disabled: no-op', True);
  {$ENDIF}
end;

procedure TTestCase_MimallocAllocator_Traits.Test_Traits_ThreadSafe;
{$IFDEF FAFAFA_CORE_MIMALLOC_ALLOCATOR}
var
  Alloc: fafafa.core.mem.allocator.base.IAllocator;
  Lib: TLibHandle;
  T: TAllocatorTraits;
{$ENDIF}
begin
  {$IFDEF FAFAFA_CORE_MIMALLOC_ALLOCATOR}
  Lib := LoadLibrary('mimalloc.dll');
  if (Lib = 0) then Lib := LoadLibrary('mimalloc-redirect.dll');
  if Lib = 0 then Exit; // 缺库：跳过
  FreeLibrary(Lib);
  Alloc := GetMimallocAllocator;
  T := Alloc.Traits;
  AssertTrue('ThreadSafe should be True by default', T.ThreadSafe);
  {$ELSE}
  AssertTrue('Macro disabled: no-op', True);
  {$ENDIF}
end;

procedure TTestCase_MimallocAllocator_Traits2.Test_Traits_SupportsAligned_False;
{$IFDEF FAFAFA_CORE_MIMALLOC_ALLOCATOR}
var
  Alloc: fafafa.core.mem.allocator.base.IAllocator;
  Lib: TLibHandle;
  T: TAllocatorTraits;
{$ENDIF}
begin
  {$IFDEF FAFAFA_CORE_MIMALLOC_ALLOCATOR}
  Lib := LoadLibrary('mimalloc.dll');
  if (Lib = 0) then Lib := LoadLibrary('mimalloc-redirect.dll');
  if Lib = 0 then Exit; // 缺库：跳过
  FreeLibrary(Lib);
  Alloc := GetMimallocAllocator;
  T := Alloc.Traits;
  AssertFalse('SupportsAligned should be False (use aligned bridge)', T.SupportsAligned);
  {$ELSE}
  AssertTrue('Macro disabled: no-op', True);
  {$ENDIF}
end;

procedure TTestCase_MimallocAllocator_Traits2.Test_Traits_HasMemSize_False;
{$IFDEF FAFAFA_CORE_MIMALLOC_ALLOCATOR}
var
  Alloc: fafafa.core.mem.allocator.base.IAllocator;
  Lib: TLibHandle;
  T: TAllocatorTraits;
{$ENDIF}
begin
  {$IFDEF FAFAFA_CORE_MIMALLOC_ALLOCATOR}
  Lib := LoadLibrary('mimalloc.dll');
  if (Lib = 0) then Lib := LoadLibrary('mimalloc-redirect.dll');
  if Lib = 0 then Exit; // 缺库：跳过
  FreeLibrary(Lib);
  Alloc := GetMimallocAllocator;
  T := Alloc.Traits;
  AssertFalse('HasMemSize should be False by default', T.HasMemSize);
  {$ELSE}
  AssertTrue('Macro disabled: no-op', True);
  {$ENDIF}
end;

initialization
  RegisterTest(TTestCase_Global);
  RegisterTest(TTestCase_MimallocAllocator);
  RegisterTest(TTestCase_MimallocAllocator_Traits);
  RegisterTest(TTestCase_MimallocAllocator_Traits2);
  RegisterTest(TTestCase_MimallocAllocator_Optional);
end.

