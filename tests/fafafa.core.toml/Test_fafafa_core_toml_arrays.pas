{$CODEPAGE UTF8}
unit Test_fafafa_core_toml_arrays;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.toml;

type
  TTestCase_Toml_Arrays = class(TTestCase)
  published
    procedure Test_Parse_Int_Array_Smoke;
  end;

implementation

procedure TTestCase_Toml_Arrays.Test_Parse_Int_Array_Smoke;
var
  D: ITomlDocument;
  E: TTomlError;
var
  V: ITomlValue; A: ITomlArray;
begin
  E.Clear;
  AssertTrue(Parse(RawByteString('nums = [1, 2, 3]'), D, E));
  AssertFalse(E.HasError);
  V := D.Root.GetValue('nums');
  AssertTrue(V <> nil);
  A := V as ITomlArray;
  AssertEquals(3, A.Count);
  AssertTrue((A.Item(0) <> nil) and (A.Item(0).GetType = tvtInteger));
end;

initialization
  RegisterTest(TTestCase_Toml_Arrays);
end.

