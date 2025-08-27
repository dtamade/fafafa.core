{$CODEPAGE UTF8}
unit Test_fafafa_core_xml_ns_freeze_elemns;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, fpcunit, testregistry,
  fafafa.core.xml;

type
  TTestCase_Xml_NS_Freeze = class(TTestCase)
  published
    procedure Test_Element_NamespaceURI_Freeze_DefaultNS;
    procedure Test_Element_NamespaceURI_Freeze_Prefix;
  end;

implementation

procedure TTestCase_Xml_NS_Freeze.Test_Element_NamespaceURI_Freeze_DefaultNS;
var R: IXmlReader; D: IXmlDocument; N: IXmlNode;
begin
  R := CreateXmlReader.ReadFromString('<r xmlns="urn:d"><a/><b/></r>');
  // 便捷函数：构建文档
  D := XmlReadAllToDocument(R);
  AssertNotNull('document should not be nil', TObject(D));
  N := D.Root;
  AssertEquals('root ns', 'urn:d', N.NamespaceURI);
  AssertEquals('child a ns', 'urn:d', N.GetChild(0).NamespaceURI);
  AssertEquals('child b ns', 'urn:d', N.GetChild(1).NamespaceURI);
end;

procedure TTestCase_Xml_NS_Freeze.Test_Element_NamespaceURI_Freeze_Prefix;
var R: IXmlReader; D: IXmlDocument; N: IXmlNode;
begin
  R := CreateXmlReader.ReadFromString('<r xmlns:p="urn:y"><p:a p:k="v"/><p:b/></r>');
  D := XmlReadAllToDocument(R);
  AssertNotNull('document should not be nil', TObject(D));
  N := D.Root;
  AssertEquals('a ns', 'urn:y', N.GetChild(0).NamespaceURI);
  AssertEquals('b ns default (empty)', '', N.GetChild(1).NamespaceURI);
end;

initialization
  if GetEnvironmentVariable('FAFAFA_TEST_SILENT_REG') <> '1' then
    Writeln('Registering TTestCase_Xml_NS_Freeze');
  RegisterTest(TTestCase_Xml_NS_Freeze);

end.

