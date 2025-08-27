{$CODEPAGE UTF8}
unit Test_fafafa_core_toml_arrays_strings;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.toml;

type
  TTestCase_Toml_Arrays_Strings = class(TTestCase)
  published
    procedure Test_Parse_String_Array_Smoke;
    procedure Test_Write_String_Array_Smoke;
  end;

implementation

procedure TTestCase_Toml_Arrays_Strings.Test_Parse_String_Array_Smoke;
var
  D: ITomlDocument;
  E: TTomlError;
  V: ITomlValue;
  A: ITomlArray;
begin
  E.Clear;
  AssertTrue(Parse(RawByteString('tags = ["a", "b", "c"]'), D, E));
  AssertFalse(E.HasError);
  V := D.Root.GetValue('tags');
  AssertTrue(V <> nil);
  A := V as ITomlArray;
  AssertEquals(3, A.Count);
end;

procedure TTestCase_Toml_Arrays_Strings.Test_Write_String_Array_Smoke;
var
  D: ITomlDocument;
  E: TTomlError;
  S: String;
begin
  E.Clear;
  AssertTrue(Parse(RawByteString('tags = ["a", "b", "c"]'), D, E));
  AssertFalse(E.HasError);
  S := String(ToToml(D, [twfSpacesAroundEquals]));
  AssertTrue(Pos('tags = ["a", "b", "c"]', S) > 0);
end;

initialization
  RegisterTest(TTestCase_Toml_Arrays_Strings);
end.

