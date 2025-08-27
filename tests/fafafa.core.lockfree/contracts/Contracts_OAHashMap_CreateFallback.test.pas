unit Contracts_OAHashMap_CreateFallback_test;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.lockfree.hashmap.openAddressing;

type
  TTestCase_Contracts_OAHashMap_CreateFallback = class(TTestCase)
  published
    procedure Test_Create_NilHashComparer_Uses_Default_Fallback;
  end;

implementation

procedure TTestCase_Contracts_OAHashMap_CreateFallback.Test_Create_NilHashComparer_Uses_Default_Fallback;
var
  M: specialize TOAHashMap<Integer, Integer>;
  ok: Boolean;
  v: Integer;
begin
  // Create without providing hash/comparer -> should fallback to SimpleHash/CompareMem
  M := specialize TOAHashMap<Integer, Integer>.Create(64, nil, nil);
  try
    ok := M.Put(42, 100);
    AssertTrue('Put should succeed with default fallback', ok);
    AssertTrue('ContainsKey(42) should be true', M.ContainsKey(42));
    AssertTrue('Get(42) should succeed', M.Get(42, v));
    AssertEquals('Value should match', 100, v);
  finally
    M.Free;
  end;
end;

initialization
  RegisterTest(TTestCase_Contracts_OAHashMap_CreateFallback);

end.

