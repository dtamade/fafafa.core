{$CODEPAGE UTF8}
unit Test_fafafa_core_xml_ns_writer;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, fpcunit, testregistry,
  fafafa.core.xml;

type
  TTestCase_Xml_NS_Writer = class(TTestCase)
  published
    procedure Test_StartElementNS_DefaultNS;
    procedure Test_StartElementNS_Prefix;
    procedure Test_WriteAttributeNS;
  end;

implementation

procedure TTestCase_Xml_NS_Writer.Test_StartElementNS_DefaultNS;
var W: IXmlWriter; S: String;
begin
  W := CreateXmlWriter;
  W.StartDocument('1.0','UTF-8');
  W.StartElementNS('', 'root', 'urn:x');
  W.StartElementNS('', 'child', 'urn:x');
  W.EndElement; W.EndElement; W.EndDocument;
  S := W.WriteToString;
  AssertTrue(Pos('<root xmlns="urn:x"><child/></root>', S) > 0);
end;

procedure TTestCase_Xml_NS_Writer.Test_StartElementNS_Prefix;
var W: IXmlWriter; S: String;
begin
  W := CreateXmlWriter;
  W.StartElementNS('p', 'a', 'urn:y');
  W.EndElement;
  S := W.WriteToString;
  AssertTrue(Pos('<p:a xmlns:p="urn:y"/>', S) > 0);
end;

procedure TTestCase_Xml_NS_Writer.Test_WriteAttributeNS;
var W: IXmlWriter; S: String;
begin
  W := CreateXmlWriter;
  W.StartElementNS('p', 'a', 'urn:y');
  W.WriteAttributeNS('p', 'k', 'urn:y', 'v');
  W.EndElement;
  S := W.WriteToString;
  AssertTrue(Pos('<p:a xmlns:p="urn:y" p:k="v"/>', S) > 0);
end;

initialization
  RegisterTest(TTestCase_Xml_NS_Writer);

end.

