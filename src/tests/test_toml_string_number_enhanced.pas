unit test_toml_string_number_enhanced;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.toml;

procedure RegisterTomlStringNumberEnhancedTests;

implementation

type
  TTomlStringNumberCase = class(TTestCase)
  published
    procedure Test_Literal_String_Single_Quote;
    procedure Test_Multiline_String_Triple_Quotes;
    procedure Test_Integer_Underscore;
    procedure Test_Float_Underscore;
  end;

procedure TTomlStringNumberCase.Test_Literal_String_Single_Quote;
var
  Doc: ITomlDocument; Err: TTomlError; S: String;
  Txt: RawByteString;
begin
  Txt := 'path = ''C:\Program Files\App''';
  FillChar(Err, SizeOf(Err), 0);
  AssertTrue(Parse(Txt, Doc, Err));
  S := GetString(Doc, 'path', '');
  AssertEquals('C:\Program Files\App', S);
end;

procedure TTomlStringNumberCase.Test_Multiline_String_Triple_Quotes;
var
  Doc: ITomlDocument; Err: TTomlError; S: String;
  Txt: RawByteString;
begin
  // 内容不以换行开头，避免处理首行修剪规则
  Txt := 'msg = """hello' + LineEnding + 'world"""';
  FillChar(Err, SizeOf(Err), 0);
  AssertTrue(Parse(Txt, Doc, Err));
  S := GetString(Doc, 'msg', '');
  AssertEquals('hello' + LineEnding + 'world', S);
end;

procedure TTomlStringNumberCase.Test_Integer_Underscore;
var
  Doc: ITomlDocument; Err: TTomlError; I: Int64;
  Txt: RawByteString;
begin
  Txt := 'n = 1_000_000';
  FillChar(Err, SizeOf(Err), 0);
  AssertTrue(Parse(Txt, Doc, Err));
  I := GetInt(Doc, 'n', -1);
  AssertEquals(Int64(1000000), I);
end;

procedure TTomlStringNumberCase.Test_Float_Underscore;
var
  Doc: ITomlDocument; Err: TTomlError; F: Double;
  Txt: RawByteString;
begin
  Txt := 'pi = 3.141_592';
  FillChar(Err, SizeOf(Err), 0);
  AssertTrue(Parse(Txt, Doc, Err));
  F := GetInt(Doc, 'pi', -1); // ensure not mistaken as int
  AssertEquals(Int64(-1), F);
  // 读取浮点（通过 ToToml roundtrip 或内部 TryGetFloat 简化：此处用 roundtrip 检查包含小数点）
  AssertTrue(Pos('3.141592', String(ToToml(Doc, []))) > 0);
end;

procedure RegisterTomlStringNumberEnhancedTests;
begin
  RegisterTest('toml-string-number', TTomlStringNumberCase);
end;

end.

