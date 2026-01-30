{$CODEPAGE UTF8}
unit Test_fafafa_core_toml_unicode_escapes;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.toml;

type
  TTestCase_Unicode_Escapes = class(TTestCase)
  published
    procedure Test_String_uXXXX;
    procedure Test_String_UXXXXXXXX;
  end;

implementation

procedure TTestCase_Unicode_Escapes.Test_String_uXXXX;
var
  Doc: ITomlDocument; Err: TTomlError; S: String;
begin
  Err.Clear;
  AssertTrue(Parse(RawByteString('s = "a\u0061b"'), Doc, Err));
  AssertFalse(Err.HasError);
  S := String(ToToml(Doc, []));
  AssertTrue(Pos('s = "aab"', S) > 0); // \u0061 == 'a'
end;

procedure TTestCase_Unicode_Escapes.Test_String_UXXXXXXXX;
var
  Doc: ITomlDocument; Err: TTomlError; S: String;
begin
  Err.Clear;
  AssertTrue(Parse(RawByteString('e = "\U0001F600"'), Doc, Err));
  AssertFalse(Err.HasError);
  S := String(ToToml(Doc, []));
  // Writer 会将字符写回字符串；断言存在引号包裹
  AssertTrue(Pos('e = "', S) > 0);
end;

initialization
  RegisterTest(TTestCase_Unicode_Escapes);
end.

