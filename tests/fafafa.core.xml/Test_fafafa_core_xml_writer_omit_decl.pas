unit Test_fafafa_core_xml_writer_omit_decl;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, fpcunit, testregistry,
  fafafa.core.xml;

type
  TTestCase_Writer_OmitDecl = class(TTestCase)
  published
    procedure Test_Omit_XmlDecl;
  end;

implementation

procedure TTestCase_Writer_OmitDecl.Test_Omit_XmlDecl;
var W: IXmlWriter; S: String;
begin
  W := CreateXmlWriter;
  W.StartDocument('1.0', 'UTF-8');
  W.StartElement('root');
  W.WriteString('x');
  W.EndElement;
  W.EndDocument;
  // 使用 xwfOmitXmlDecl，期待不包含 xml 声明
  S := W.WriteToString([xwfOmitXmlDecl]);
  AssertTrue('no xml decl', Pos('<?xml', S) = 0);
  // 不传 flag，期待包含 xml 声明
  S := W.WriteToString([]);
  AssertTrue('has xml decl', Pos('<?xml', S) > 0);
end;

initialization
  if GetEnvironmentVariable('FAFAFA_TEST_SILENT_REG') <> '1' then
    RegisterTest('fafafa.core.xml', TTestCase_Writer_OmitDecl);

end.

