unit test_strict_factories;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.lockfree, fafafa.core.lockfree.hashmap.openAddressing;

type
  { TTestStrictFactories }
  TTestStrictFactories = class(TTestCase)
  published
    procedure NewStrict_Raises_When_Missing_Comparer;
    procedure Facade_CreateStrict_Compiles_And_Works;
  end;

implementation

type
  TStringOA = specialize TLockFreeHashMap<string, Integer>;

procedure TTestStrictFactories.NewStrict_Raises_When_Missing_Comparer;
var
  M: TStringOA;
begin
  try
    M := TStringOA.NewStrict(16, nil, nil);
    Fail('NewStrict should raise when comparer/hash are missing');
  except
    on E: Exception do ; // expected
  end;
end;

function HashCI(const S: string): Cardinal; inline;
begin
  Result := fafafa.core.lockfree.SimpleHash(UpperCase(S)[1], Length(S));
end;

function EqCI(const L, R: string): Boolean; inline;
begin
  Result := SameText(L, R);
end;

procedure TTestStrictFactories.Facade_CreateStrict_Compiles_And_Works;
var
  Map: TStrIntOAHashMap;
  V: Integer;
begin
  Map := CreateStrIntOAHashMapStrict(64, @HashCI, @EqCI);
  try
    AssertTrue(Map.Put('Abc', 7));
    AssertTrue(Map.Get('abc', V));
    AssertEquals(7, V);
  finally
    Map.Free;
  end;
end;

initialization
  RegisterTest(TTestStrictFactories);
end.

