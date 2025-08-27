unit Test_fafafa_core_xml_attr_ns_freeze;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testutils, testregistry,
  fafafa.core.xml;

Type
  TTestCase_Attr_NS_Freeze = class(TTestCase)
  published
    procedure Test_Attr_NS_Resolved_On_Freeze;
  end;

implementation

procedure TTestCase_Attr_NS_Freeze.Test_Attr_NS_Resolved_On_Freeze;
var
  R: IXmlReader;
  N: IXmlNode;
  Xml: string;
  nsHref: string;
  nsLang: string;
  nsNoPref: string;
  nsXmlns: string;
  nsXml: string;
  i: SizeUInt;
  name: string;
  uri: string;
begin
  Xml := '<root xmlns="urn:def" xmlns:ns="urn:ns" xml:lang="en" xmlns:xlink="http://www.w3.org/1999/xlink" ns:href="/a" href="/b"/>';
  R := CreateXmlReader.ReadFromString(Xml);
  AssertTrue('Read start element', R.Read);
  // 冻结当前节点
  N := R.FreezeCurrentNode;
  AssertTrue('Frozen node not nil', N<>nil);

  // 扫描属性，记录我们关心的几项
  nsHref := '';
  nsNoPref := '';
  nsLang := '';
  for i := 0 to N.GetAttributeCount-1 do
  begin
    name := N.GetAttributeName(i);
    uri := N.GetAttributeNamespaceURI(i);
    if name='ns:href' then nsHref := uri
    else if name='href' then nsNoPref := uri
    else if name='xml:lang' then nsLang := uri;
  end;

  // 断言：
  // - 有前缀的 ns:href => urn:ns
  // - 无前缀的 href => ''（默认命名空间不作用于属性）
  // - xml:lang => http://www.w3.org/XML/1998/namespace
  AssertEquals('ns:href ns', 'urn:ns', nsHref);
  AssertEquals('href no default ns', '', nsNoPref);
  AssertEquals('xml:lang ns', 'http://www.w3.org/XML/1998/namespace', nsLang);
end;

initialization
  RegisterTest(TTestCase_Attr_NS_Freeze);

end.

