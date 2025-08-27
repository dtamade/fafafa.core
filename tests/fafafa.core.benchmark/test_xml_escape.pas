unit test_xml_escape;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.base;

type
  TTestXmlEscape = class(TTestCase)
  published
    procedure Test_BasicEntities;
    procedure Test_QuotesAndApostrophe;
    procedure Test_ControlChars;
    procedure Test_UTF8Multibyte;
    procedure Test_LongString_PerformanceSmoke;
  end;

implementation

procedure TTestXmlEscape.Test_BasicEntities;
begin
  AssertEquals('&amp;lt;&amp;gt;&amp;amp;', XmlEscape('<>&'));
end;

procedure TTestXmlEscape.Test_QuotesAndApostrophe;
begin
  AssertEquals('&quot;hello&apos;', XmlEscape('"hello'''));
end;

procedure TTestXmlEscape.Test_ControlChars;
var
  S: string;
begin
  S := #0#1#2#9#10#13; // 控制字符与空白字符混合
  // XmlEscape 目前仅做实体替换，不删除控制字符；确保函数不抛异常且可返回
  // 这里不严格断言具体输出，仅验证可调用
  AssertTrue(Length(XmlEscape(S)) = Length(S));
end;

procedure TTestXmlEscape.Test_UTF8Multibyte;
begin
  AssertEquals('中文&lt;μ&gt;', XmlEscape('中文<μ>'));
end;

procedure TTestXmlEscape.Test_LongString_PerformanceSmoke;
var
  I: Integer;
  S, R: string;
begin
  SetLength(S, 20000);
  for I := 1 to Length(S) do
    if (I mod 100) = 0 then S[I] := '&' else S[I] := 'a';
  R := XmlEscape(S);
  AssertEquals(Length(S) + (Length(S) div 100) * (Length('&amp;') - 1), Length(R));
end;

initialization
  RegisterTest(TTestXmlEscape);
end.

