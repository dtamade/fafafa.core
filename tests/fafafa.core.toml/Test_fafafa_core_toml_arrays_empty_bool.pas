{$CODEPAGE UTF8}
unit Test_fafafa_core_toml_arrays_empty_bool;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.toml;

type
  TTestCase_Toml_Arrays_Empty_Bool = class(TTestCase)
  published
    procedure Test_Parse_Empty_Array_Smoke;
    procedure Test_Write_Empty_Array_Smoke;
    procedure Test_Parse_Bool_Array_Smoke;
    procedure Test_Write_Bool_Array_Smoke;
  end;

implementation

procedure TTestCase_Toml_Arrays_Empty_Bool.Test_Parse_Empty_Array_Smoke;
var D: ITomlDocument; E: TTomlError; S: String;
begin
  E.Clear;
  AssertTrue(Parse(RawByteString('tags = []'), D, E));
  AssertFalse(E.HasError);
  S := String(ToToml(D, [twfSpacesAroundEquals]));
  AssertTrue(Pos('tags = []', S) > 0);
end;

procedure TTestCase_Toml_Arrays_Empty_Bool.Test_Write_Empty_Array_Smoke;
var D: ITomlDocument; E: TTomlError; S: String;
begin
  E.Clear;
  AssertTrue(Parse(RawByteString('nums = []'), D, E));
  AssertFalse(E.HasError);
  S := String(ToToml(D, [twfSpacesAroundEquals]));
  AssertTrue(Pos('nums = []', S) > 0);
end;

procedure TTestCase_Toml_Arrays_Empty_Bool.Test_Parse_Bool_Array_Smoke;
var D: ITomlDocument; E: TTomlError; V: ITomlValue; A: ITomlArray;
begin
  E.Clear;
  AssertTrue(Parse(RawByteString('flags = [true, false, true]'), D, E));
  AssertFalse(E.HasError);
  V := D.Root.GetValue('flags');
  AssertTrue(V <> nil);
  A := V as ITomlArray;
  AssertEquals(3, A.Count);
end;

procedure TTestCase_Toml_Arrays_Empty_Bool.Test_Write_Bool_Array_Smoke;
var D: ITomlDocument; E: TTomlError; S: String;
begin
  E.Clear;
  AssertTrue(Parse(RawByteString('flags = [true, false, true]'), D, E));
  AssertFalse(E.HasError);
  S := String(ToToml(D, [twfSpacesAroundEquals]));
  AssertTrue(Pos('flags = [true, false, true]', S) > 0);
end;

initialization
  RegisterTest(TTestCase_Toml_Arrays_Empty_Bool);
end.

