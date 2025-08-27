{$CODEPAGE UTF8}
unit test_mimalloc_manager_optional_smoke;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testregistry
  {$IFDEF FAFAFA_CORE_MIMALLOC_ALLOCATOR}
  ,dynlibs,
  fafafa.core.mem.allocator.mimalloc,
  fafafa.core.mem.allocator.base
  {$ENDIF}
  ;

type
  TTestCase_Mimalloc_Manager_Optional = class(TTestCase)
  published
    procedure Test_Install_Uninstall_Smoke;
  end;

implementation

procedure TTestCase_Mimalloc_Manager_Optional.Test_Install_Uninstall_Smoke;
{$IFDEF FAFAFA_CORE_MIMALLOC_ALLOCATOR}
Type
  Tmi_malloc = function(size: SizeUInt): Pointer; cdecl;
  Tmi_free   = procedure(p: Pointer); cdecl;
var
  LLib: TLibHandle;
  FMalloc: Tmi_malloc;
  FFree:   Tmi_free;
  P: Pointer;
  LAlloc: fafafa.core.mem.allocator.base.IAllocator;
{$ENDIF}
begin
  {$IFDEF FAFAFA_CORE_MIMALLOC_ALLOCATOR}
  // Step B.3: Delayed bind to mimalloc symbols and call malloc/free without importing Pascal unit
  LLib := LoadLibrary('mimalloc.dll');
  if LLib = 0 then
    LLib := LoadLibrary('tests/fafafa.core.mem/bin/mimalloc.dll');
  if LLib = 0 then Exit; // skip when dll not available
  try
    Pointer(FMalloc) := GetProcedureAddress(LLib, 'mi_malloc');
    Pointer(FFree)   := GetProcedureAddress(LLib, 'mi_free');
    if (not Assigned(FMalloc)) or (not Assigned(FFree)) then Exit; // skip if symbols not found
    P := FMalloc(128);
    AssertNotNull('mi_malloc(128) should return non-nil', P);
    FFree(P);

    // Step B.4: Now try Pascal unit path (GetMimallocAllocator) and do Alloc/Free
    LAlloc := GetMimallocAllocator;
    AssertTrue('GetMimallocAllocator should return non-nil', LAlloc <> nil);
    P := LAlloc.AllocMem(64);
    AssertNotNull('AllocMem(64) from allocator should succeed', P);
    LAlloc.FreeMem(P);
  finally
    FreeLibrary(LLib);
  end;
  {$ELSE}
  AssertTrue('Macro disabled: no-op', True);
  {$ENDIF}
end;

initialization
  RegisterTest(TTestCase_Mimalloc_Manager_Optional);

end.

