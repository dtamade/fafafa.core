unit test_toml_basic;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testutils, testregistry,
  fafafa.core.toml;

procedure RegisterTomlBasicTests;

implementation

type
  TTomlBasicCase = class(TTestCase)
  published
    procedure Test_Parse_Simple_KeyValue_String_Int_Bool;
    procedure Test_Dotted_Keys_And_Table_Header;
    procedure Test_ToToml_Smoke_Output;
  end;

procedure AssertParseOk(const S: RawByteString; out Doc: ITomlDocument);
var
  Err: TTomlError;
begin
  FillChar(Err, SizeOf(Err), 0);
  TAssert.AssertTrue(Parse(S, Doc, Err));
  TAssert.AssertTrue(Doc <> nil);
  TAssert.AssertEquals(Ord(tecSuccess), Ord(Err.Code));
end;

procedure TTomlBasicCase.Test_Parse_Simple_KeyValue_String_Int_Bool;
var
  Doc: ITomlDocument;
  S: RawByteString;
  vStr: String; vInt: Int64; vBool: Boolean;
begin
  S := 'name = "fafafa"' + LineEnding + 'num = 42' + LineEnding + 'flag = true';
  AssertParseOk(S, Doc);
  vStr := GetString(Doc, 'name', '');
  vInt := GetInt(Doc, 'num', -1);
  vBool := GetBool(Doc, 'flag', False);
  TAssert.AssertEquals('fafafa', vStr);
  TAssert.AssertEquals(Int64(42), vInt);
  TAssert.AssertTrue(vBool);
end;

procedure TTomlBasicCase.Test_Dotted_Keys_And_Table_Header;
var
  Doc: ITomlDocument;
  S: RawByteString;
  v1, v2: Int64;
begin
  // 混合 dotted keys 与 [table] 头
  S := 'a.b.c = 1' + LineEnding + '[x.y]' + LineEnding + 'z = 2';
  AssertParseOk(S, Doc);
  v1 := GetInt(Doc, 'a.b.c', -1);
  v2 := GetInt(Doc, 'x.y.z', -1);
  TAssert.AssertEquals(Int64(1), v1);
  TAssert.AssertEquals(Int64(2), v2);
end;

procedure TTomlBasicCase.Test_ToToml_Smoke_Output;
var
  B: ITomlBuilder;
  Doc: ITomlDocument;
  OutS: RawByteString;
begin
  B := NewDoc;
  B.BeginTable('app').PutStr('name', 'core').PutInt('ver', 1).EndTable;
  Doc := B.Build;
  OutS := ToToml(Doc, []);
  // 默认紧凑
  TAssert.AssertTrue(Pos('name="core"', String(OutS)) > 0);
  TAssert.AssertTrue(Pos('ver=1', String(OutS)) > 0);
  // 开启空格风格
  OutS := ToToml(Doc, [twfSpacesAroundEquals]);
  TAssert.AssertTrue(Pos('name = "core"', String(OutS)) > 0);
  TAssert.AssertTrue(Pos('ver = 1', String(OutS)) > 0);
end;

procedure RegisterTomlBasicTests;
begin
  RegisterTest('toml-basic', TTomlBasicCase);
end;

end.

