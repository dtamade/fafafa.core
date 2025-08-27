unit Test_fafafa_core_xml_attr_ns_freeze_more;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, fpcunit, testregistry,
  fafafa.core.xml;

type
  TTestCase_Attr_NS_Freeze_More = class(TTestCase)
  published
    procedure Test_NS_Accessors_Complex;
  end;

implementation

procedure TTestCase_Attr_NS_Freeze_More.Test_NS_Accessors_Complex;
var R: IXmlReader; D: IXmlDocument; N, C: IXmlNode;
    S: String; i: SizeUInt;
begin
  // 默认 ns + 前缀属性 + 元素级前缀
  S := '<root xmlns="urn:d">'+
       '<a:node xmlns:a="urn:a" x="1" a:y="2">t</a:node>'+
       '<node b:z="3" xmlns:b="urn:b" />'+
       '</root>';
  R := CreateXmlReader.ReadFromString(S, [xrfIgnoreWhitespace]);
  D := R.ReadAllToDocument; // 构建最小 DOM
  N := D.Root; // root
  AssertEquals('root ns', 'urn:d', N.NamespaceURI);
  // child1 with prefix a
  C := N.GetChild(0);
  AssertEquals('a:node local', 'node', C.LocalName);
  AssertEquals('a:node prefix', 'a', C.Prefix);
  AssertEquals('a:node ns', 'urn:a', C.NamespaceURI);
  // attributes on child1
  AssertEquals('attr count', 2, C.GetAttributeCount);
  // unnamed x has no URI
  AssertEquals('x ns empty', '', C.GetAttributeNamespaceURI(0));
  // a:y has ns urn:a
  AssertEquals('a:y ns', 'urn:a', C.GetAttributeNamespaceURI(1));
  // child2 default inherits urn:d, attr b:z has urn:b
  C := N.GetChild(1);
  AssertEquals('node ns default', 'urn:d', C.NamespaceURI);
  AssertEquals('attr count2', 1, C.GetAttributeCount);
  AssertEquals('b:z ns', 'urn:b', C.GetAttributeNamespaceURI(0));
end;

initialization
  if GetEnvironmentVariable('FAFAFA_TEST_SILENT_REG') <> '1' then
    RegisterTest('fafafa.core.xml', TTestCase_Attr_NS_Freeze_More);

end.

