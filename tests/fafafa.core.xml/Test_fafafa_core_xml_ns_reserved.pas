{$CODEPAGE UTF8}
unit Test_fafafa_core_xml_ns_reserved;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, fpcunit, testregistry,
  fafafa.core.xml;

type
  TTestCase_Xml_NS_Reserved = class(TTestCase)
  published
    procedure Test_Reader_CannotBind_xml_Prefix_DifferentURI;
    procedure Test_Reader_CannotBind_xmlns_Prefix;
    procedure Test_Reader_CannotBind_xmlns_URI;
    procedure Test_Writer_CannotBind_xml_Prefix_DifferentURI;
    procedure Test_Writer_CannotBind_xmlns_Prefix;
    procedure Test_Writer_CannotBind_xmlns_URI;
  end;

implementation

procedure TTestCase_Xml_NS_Reserved.Test_Reader_CannotBind_xml_Prefix_DifferentURI;
var R: IXmlReader; Raised: Boolean;
begin
  R := CreateXmlReader.ReadFromString('<r xmlns:xml="urn:oops"/>');
  Raised := False;
  try while R.Read do ; except on E: EXmlParseError do Raised := True; end;
  AssertTrue('rebind xml prefix should raise', Raised);
end;

procedure TTestCase_Xml_NS_Reserved.Test_Reader_CannotBind_xmlns_Prefix;
var R: IXmlReader; Raised: Boolean;
begin
  R := CreateXmlReader.ReadFromString('<r xmlns:xmlns="urn:x"/>');
  Raised := False;
  try while R.Read do ; except on E: EXmlParseError do Raised := True; end;
  AssertTrue('bind xmlns prefix should raise', Raised);
end;

procedure TTestCase_Xml_NS_Reserved.Test_Reader_CannotBind_xmlns_URI;
var R: IXmlReader; Raised: Boolean;
begin
  R := CreateXmlReader.ReadFromString('<r xmlns:p="http://www.w3.org/2000/xmlns/"/>');
  Raised := False;
  try while R.Read do ; except on E: EXmlParseError do Raised := True; end;
  AssertTrue('bind xmlns URI should raise', Raised);
end;

procedure TTestCase_Xml_NS_Reserved.Test_Writer_CannotBind_xml_Prefix_DifferentURI;
var W: IXmlWriter; Raised: Boolean;
begin
  W := CreateXmlWriter;
  Raised := False;
  try
    W.StartElementNS('xml','a','urn:oops');
  except on E: Exception do Raised := True; end;
  AssertTrue('writer cannot rebind xml prefix', Raised);
end;

procedure TTestCase_Xml_NS_Reserved.Test_Writer_CannotBind_xmlns_Prefix;
var W: IXmlWriter; Raised: Boolean;
begin
  W := CreateXmlWriter;
  Raised := False;
  try
    W.StartElementNS('xmlns','a','urn:x');
  except on E: Exception do Raised := True; end;
  AssertTrue('writer cannot bind xmlns prefix', Raised);
end;

procedure TTestCase_Xml_NS_Reserved.Test_Writer_CannotBind_xmlns_URI;
var W: IXmlWriter; Raised: Boolean;
begin
  W := CreateXmlWriter;
  Raised := False;
  try
    W.StartElementNS('p','a','http://www.w3.org/2000/xmlns/');
  except on E: Exception do Raised := True; end;
  AssertTrue('writer cannot bind prefix to xmlns URI', Raised);
end;

initialization
  RegisterTest(TTestCase_Xml_NS_Reserved);

end.

