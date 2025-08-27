unit test_element_manager_overflow;

{$mode objfpc}{$H+}
{$I ../fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.mem.allocator,
  fafafa.core.collections.elementManager;

procedure RegisterElementManagerOverflowTests;

implementation

type
  TOverflowEM = class(TTestCase)
  published
    procedure Test_AllocElements_Overflow;
    procedure Test_ReallocElements_Overflow;
  end;

procedure TOverflowEM.Test_AllocElements_Overflow;
var
  em: specialize TElementManager<Integer>;
  huge: SizeUInt;
begin
  em := specialize TElementManager<Integer>.Create;
  try
    huge := High(SizeUInt) div em.ElementSize + 1;
    try
      em.AllocElements(huge);
      Fail('Expected overflow not raised');
    except
      on E: EOverflow do ;
    end;
  finally
    em.Free;
  end;
end;

procedure TOverflowEM.Test_ReallocElements_Overflow;
var
  em: specialize TElementManager<Integer>;
  p: Pointer;
  huge: SizeUInt;
begin
  em := specialize TElementManager<Integer>.Create;
  try
    p := nil;
    huge := High(SizeUInt) div em.ElementSize + 1;
    try
      p := em.ReallocElements(p, 0, huge);
      Fail('Expected overflow not raised');
    except
      on E: EOverflow do ;
    end;
    if p <> nil then em.FreeElements(p, 0);
  finally
    em.Free;
  end;
end;

procedure RegisterElementManagerOverflowTests;
begin
  RegisterTest('element-manager-overflow', TOverflowEM);
end;

end.

