{$CODEPAGE UTF8}
unit Test_fafafa_core_xml_writer_omit_decl_combos;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, fpcunit, testregistry,
  fafafa.core.xml;

type
  TTestCase_Xml_Writer_OmitDecl_Combos = class(TTestCase)
  published
    procedure Test_OmitDecl_With_Pretty;
    procedure Test_OmitDecl_With_Sort_Dedup;
  end;

implementation

procedure TTestCase_Xml_Writer_OmitDecl_Combos.Test_OmitDecl_With_Pretty;
var W: IXmlWriter; S: String;
begin
  W := CreateXmlWriter;
  W.StartDocument('1.0','UTF-8');
  W.StartElement('r');
  W.WriteString('t');
  W.EndElement;
  W.EndDocument;
  S := W.WriteToString([xwfOmitXmlDecl, xwfPretty]);
  AssertTrue('no xml declaration', Pos('<?xml', S) = 0);
  AssertTrue('pretty contains newline', Pos(LineEnding, S) > 0);
end;

procedure TTestCase_Xml_Writer_OmitDecl_Combos.Test_OmitDecl_With_Sort_Dedup;
var W: IXmlWriter; S: String; p, p2: SizeInt;
begin
  W := CreateXmlWriter;
  W.StartDocument('1.0','UTF-8');
  W.StartElement('r');
  W.WriteAttribute('b', '2');
  W.WriteAttribute('a', '1');
  W.WriteAttribute('a', '3'); // dedup keep last
  W.EndElement;
  W.EndDocument;
  S := W.WriteToString([xwfOmitXmlDecl, xwfSortAttrs, xwfDedupAttrs]);
  AssertTrue('no xml declaration', Pos('<?xml', S) = 0);
  // 属性应排序：a 在 b 前，且去重保留最后一个 a=3
  p := Pos(' a="3"', S);
  p2 := Pos(' b="2"', S);
  AssertTrue('a before b', (p>0) and (p2>0) and (p < p2));
end;

initialization
  if GetEnvironmentVariable('FAFAFA_TEST_SILENT_REG') <> '1' then
    Writeln('Registering TTestCase_Xml_Writer_OmitDecl_Combos');
  RegisterTest(TTestCase_Xml_Writer_OmitDecl_Combos);

end.

