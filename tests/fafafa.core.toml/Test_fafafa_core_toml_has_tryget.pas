{$CODEPAGE UTF8}
unit Test_fafafa_core_toml_has_tryget;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.toml;

type
  TTestCase_Has_TryGet = class(TTestCase)
  published
    procedure Test_Has_Positive_Scalar;
    procedure Test_Has_Negative_NotExists;
    procedure Test_TryGetValue_Positive_Table;
    procedure Test_TryGetValue_Negative_NotExists;
  end;

implementation

procedure TTestCase_Has_TryGet.Test_Has_Positive_Scalar;
var
  Doc: ITomlDocument; Err: TTomlError;
begin
  Err.Clear;
  AssertTrue(Parse(RawByteString('a.b.c = 1'), Doc, Err));
  AssertFalse(Err.HasError);
  AssertTrue(Has(Doc, 'a.b.c'));
  AssertTrue(Has(Doc, 'a.b'));
  AssertTrue(Has(Doc, 'a'));
end;

procedure TTestCase_Has_TryGet.Test_Has_Negative_NotExists;
var
  Doc: ITomlDocument; Err: TTomlError;
begin
  Err.Clear;
  AssertTrue(Parse(RawByteString('a = 1'), Doc, Err));
  AssertFalse(Err.HasError);
  AssertFalse(Has(Doc, 'b'));
  AssertFalse(Has(Doc, 'a.b'));
end;

procedure TTestCase_Has_TryGet.Test_TryGetValue_Positive_Table;
var
  Doc: ITomlDocument; Err: TTomlError; V: ITomlValue;
begin
  Err.Clear;
  AssertTrue(Parse(RawByteString('[a]\nb = 2'), Doc, Err));
  AssertFalse(Err.HasError);
  AssertTrue(TryGetValue(Doc, 'a', V));
  AssertNotNull(V);
  AssertEquals(Ord(tvtTable), Ord(V.GetType));
end;

procedure TTestCase_Has_TryGet.Test_TryGetValue_Negative_NotExists;
var
  Doc: ITomlDocument; Err: TTomlError; V: ITomlValue;
begin
  Err.Clear;
  AssertTrue(Parse(RawByteString('x = 1'), Doc, Err));
  AssertFalse(Err.HasError);
  AssertFalse(TryGetValue(Doc, 'y', V));
  AssertTrue(V = nil);
end;

initialization
  RegisterTest(TTestCase_Has_TryGet);
end.

