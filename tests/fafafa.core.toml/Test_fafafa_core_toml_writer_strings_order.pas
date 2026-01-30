{$CODEPAGE UTF8}
unit Test_fafafa_core_toml_writer_strings_order;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.toml;

type
  TTestCase_Writer_Strings_Order = class(TTestCase)
  published
    procedure Test_Writer_StringEscapes;
    procedure Test_Writer_Multiple_Subtables_Order;
    procedure Test_Writer_NoLeadingBlankLine_And_NoDoubleBlankLines;
  end;

implementation

procedure TTestCase_Writer_Strings_Order.Test_Writer_StringEscapes;
var
  LDoc: ITomlDocument;
  LErr: TTomlError;
  S: RawByteString;
begin
  LErr.Clear;
  // 输入包含需要转义的字符
  AssertTrue(Parse(RawByteString('s = "a\"b\\c\n\r\t"'), LDoc, LErr));
  AssertFalse(LErr.HasError);
  S := ToToml(LDoc, []);
  // 输出应包含转义序列，而非实际控制字符（注意 Pascal 字面量不需要 C 风格反斜杠转义）
  AssertTrue(Pos('s = "a\"b\\c\n\r\t"', String(S)) > 0);
end;

procedure TTestCase_Writer_Strings_Order.Test_Writer_Multiple_Subtables_Order;
var
  LDoc: ITomlDocument;
  LErr: TTomlError;
  S: RawByteString;
  Pa, Pab, Pad: SizeInt;
begin
  LErr.Clear;
  AssertTrue(Parse(RawByteString('a.b.c = 1' + LineEnding + 'a.d.e = 2'), LDoc, LErr));
  AssertFalse(LErr.HasError);
  S := ToToml(LDoc, []);
  Pa := Pos('[a]', String(S));
  Pab := Pos('[a.b]', String(S));
  Pad := Pos('[a.d]', String(S));
  AssertTrue((Pa > 0) and (Pab > 0) and (Pad > 0));
  AssertTrue(Pa < Pab);
  AssertTrue(Pab < Pad); // 解析顺序 b 再 d
end;

procedure TTestCase_Writer_Strings_Order.Test_Writer_NoLeadingBlankLine_And_NoDoubleBlankLines;
var
  LDoc: ITomlDocument;
  LErr: TTomlError;
  S: String;
begin
  LErr.Clear;
  AssertTrue(Parse(RawByteString('a.b.c = 1'), LDoc, LErr));
  AssertFalse(LErr.HasError);
  S := String(ToToml(LDoc, []));
  // 首字符应为 '['，而非空行
  AssertTrue((Length(S) > 0) and (S[1] = '['));
  // 不出现双重空行
  AssertTrue(Pos(LineEnding + LineEnding, S) = 0);
end;

initialization
  RegisterTest(TTestCase_Writer_Strings_Order);
end.

