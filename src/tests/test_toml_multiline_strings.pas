unit test_toml_multiline_strings;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.toml;

procedure RegisterTomlMultilineStringTests;

implementation
function NormEOL(const S: String): String;
begin
  Result := StringReplace(StringReplace(S, #13#10, #10, [rfReplaceAll]), #13, #10, [rfReplaceAll]);
end;


type
  TTomlMultilineStringCase = class(TTestCase)
  published
    procedure Test_Basic_Multiline_Trim_First_Newline;
    procedure Test_Basic_Multiline_With_Escapes;
    procedure Test_Literal_Multiline_No_Escape;
    procedure Test_Basic_Multiline_Line_Continuation;
  end;

procedure TTomlMultilineStringCase.Test_Basic_Multiline_Trim_First_Newline;
var
  Doc: ITomlDocument; Err: TTomlError; S: String;
  Txt: RawByteString;
begin
  // TOML 规则：开头紧随的换行会被忽略
  Txt := 'msg = """' + LineEnding + 'hello' + LineEnding + 'world"""';
  FillChar(Err, SizeOf(Err), 0);
  AssertTrue(Parse(Txt, Doc, Err));
  S := GetString(Doc, 'msg', '');
  AssertEquals(NormEOL('hello' + LineEnding + 'world'), NormEOL(S));
end;

procedure TTomlMultilineStringCase.Test_Basic_Multiline_With_Escapes;
var
  Doc: ITomlDocument; Err: TTomlError; S: String;
  Txt: RawByteString;
begin
  // 多行基本字符串允许转义序列（\n -> 换行，\t -> Tab）
  Txt := 'msg = """hello\nworld\t!"""';
  FillChar(Err, SizeOf(Err), 0);
  AssertTrue(Parse(Txt, Doc, Err));
  S := GetString(Doc, 'msg', '');
  AssertEquals(NormEOL('hello' + LineEnding + 'world' + #9 + '!'), NormEOL(S));
end;

procedure TTomlMultilineStringCase.Test_Literal_Multiline_No_Escape;
var
  Doc: ITomlDocument; Err: TTomlError; S: String;
  Txt: RawByteString;
begin
  // 多行字面量字符串不处理转义
  Txt := 'path = ''''' + LineEnding + 'C:\\a\\b\\n' + LineEnding + 'x''''';
  FillChar(Err, SizeOf(Err), 0);
  AssertTrue(Parse(Txt, Doc, Err));
  S := GetString(Doc, 'path', '');
  AssertEquals(NormEOL('C:\\a\\b\\n' + LineEnding + 'x'), NormEOL(S));
end;

procedure TTomlMultilineStringCase.Test_Basic_Multiline_Line_Continuation;
var
  Doc: ITomlDocument; Err: TTomlError; S: String;
  Txt: RawByteString;
begin
  // 行尾反斜杠 + 行终止：拼接相邻行并修剪下一行起始空白
  Txt := 'msg = """hello\  ' + LineEnding + '   world"""';
  FillChar(Err, SizeOf(Err), 0);
  AssertTrue(Parse(Txt, Doc, Err));
  S := GetString(Doc, 'msg', '');
  AssertEquals('helloworld', S);
end;

procedure RegisterTomlMultilineStringTests;
begin
  RegisterTest('toml-multiline-strings', TTomlMultilineStringCase);
end;

end.

