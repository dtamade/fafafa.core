{$CODEPAGE UTF8}
unit Test_fafafa_core_xml_reader;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, fpcunit, testregistry,
  fafafa.core.xml;

const
  SampleXML = '<?xml version="1.0"?><root><!--c--><![CDATA[data]]><?pi x?>text<e/></root>'; // self-contained, balanced tree

type
  TTestCase_Reader = class(TTestCase)
  published
    procedure Test_Whitespace_Ignore;
    procedure Test_Comment_CData_PI;
  end;

implementation

procedure TTestCase_Reader.Test_Whitespace_Ignore;
var R: IXmlReader; C: Integer;
begin
  R := CreateXmlReader.ReadFromString('  <a/>', [xrfIgnoreWhitespace]);
  C := 0;
  while R.Read do
    if R.Token = xtWhitespace then Inc(C);
  AssertEquals('IgnoreWhitespace should drop whitespace tokens', 0, C);
end;

procedure TTestCase_Reader.Test_Comment_CData_PI;
var R: IXmlReader; Toks: array of TXmlToken; I: Integer;
begin
  R := CreateXmlReader.ReadFromString(SampleXML, []);
  SetLength(Toks, 0);
  while R.Read do
  begin
    if (R.Token = xtWhitespace) then Continue;
    I := Length(Toks); SetLength(Toks, I+1); Toks[I] := R.Token;
  end;
  // 期待包含 StartDocument/StartElement/Comment/CData/PI/Text/StartElement/EndElement/EndElement/EndDocument
  AssertTrue('Contains Comment', pos(IntToStr(Ord(xtComment)), IntToStr(Ord(Toks[2])))>=0);
  AssertTrue('Contains CData', pos(IntToStr(Ord(xtCData)), IntToStr(Ord(Toks[3])))>=0);
  AssertTrue('Contains PI', pos(IntToStr(Ord(xtPI)), IntToStr(Ord(Toks[4])))>=0);
end;

initialization
  if GetEnvironmentVariable('FAFAFA_TEST_SILENT_REG') <> '1' then
    Writeln('Registering TTestCase_Reader');
  RegisterTest(TTestCase_Reader);

end.

