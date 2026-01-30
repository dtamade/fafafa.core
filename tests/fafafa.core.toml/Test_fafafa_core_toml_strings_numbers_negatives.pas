{$CODEPAGE UTF8}
unit Test_fafafa_core_toml_strings_numbers_negatives;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.toml;

type
  TTestCase_Strings_Numbers_Negatives = class(TTestCase)
  published
    procedure Test_String_Escapes_BF_Should_Pass;
    procedure Test_Number_NaN_Inf_Should_Fail;
  end;

implementation

procedure TTestCase_Strings_Numbers_Negatives.Test_String_Escapes_BF_Should_Pass;
var
  Doc: ITomlDocument; Err: TTomlError; S: String;
begin
  Err.Clear;
  AssertTrue(Parse(RawByteString('s = "a\nb\rc\td\be\ff"'), Doc, Err));
  AssertFalse(Err.HasError);
  S := String(ToToml(Doc, []));
  AssertTrue(Pos('s = "a\nb\rc\td\be\ff"', S) > 0);
end;

procedure TTestCase_Strings_Numbers_Negatives.Test_Number_NaN_Inf_Should_Fail;
var
  Doc: ITomlDocument; Err: TTomlError;
begin
  Err.Clear;
  AssertFalse(Parse(RawByteString('x = nan'), Doc, Err));
  AssertTrue(Err.HasError);
  Err.Clear;
  AssertFalse(Parse(RawByteString('x = inf'), Doc, Err));
  AssertTrue(Err.HasError);
  Err.Clear;
  AssertFalse(Parse(RawByteString('x = -inf'), Doc, Err));
  AssertTrue(Err.HasError);
end;

initialization
  RegisterTest(TTestCase_Strings_Numbers_Negatives);
end.

