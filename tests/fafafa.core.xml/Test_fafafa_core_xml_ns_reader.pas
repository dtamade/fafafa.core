{$CODEPAGE UTF8}
unit Test_fafafa_core_xml_ns_reader;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, fpcunit, testregistry,
  fafafa.core.xml;

type
  TTestCase_Xml_NS_Reader = class(TTestCase)
  published
    procedure Test_DefaultNS_Elements;
    procedure Test_Prefix_Element_Attribute;
    procedure Test_Unbound_Prefix_Error;
    procedure Test_Prefix_Element_NonSelfClosing_OK;

  end;

implementation

procedure TTestCase_Xml_NS_Reader.Test_DefaultNS_Elements;
var R: IXmlReader; Ns: String; Cnt: SizeUInt;
begin
  R := CreateXmlReader.ReadFromString('<r xmlns="urn:x"><a/><b/></r>');
  Cnt := 0;
  while R.Read do begin
    if R.Token = xtStartElement then begin
      Ns := R.GetNamespaceURI;
      AssertEquals('urn:x', Ns);
      Inc(Cnt);
    end;
  end;
  AssertEquals(3, Cnt); // r, a, b
end;

procedure TTestCase_Xml_NS_Reader.Test_Prefix_Element_Attribute;
var R: IXmlReader; NsE, NsA: String;
begin
  R := CreateXmlReader.ReadFromString('<r xmlns:p="urn:y"><p:a p:k="v"/></r>');
  while R.Read do begin
    if R.Token = xtStartElement then begin
      NsE := R.GetNamespaceURI;
      if R.GetLocalName = 'a' then begin
        AssertEquals('urn:y', NsE);
        AssertEquals(1, R.AttributeCount);
        AssertEquals('k', R.GetAttributeLocalName(0));
        NsA := R.GetAttributeNamespaceURI(0);
        AssertEquals('urn:y', NsA);
      end;
    end;
  end;
end;

procedure TTestCase_Xml_NS_Reader.Test_Prefix_Element_NonSelfClosing_OK;
var R: IXmlReader; Ns: String; SeenStart: Boolean;
begin
  R := CreateXmlReader.ReadFromString('<r xmlns:p="urn:y"><p:a>text</p:a></r>');
  SeenStart := False;
  while R.Read do begin
    if (R.Token = xtStartElement) and (R.GetLocalName = 'a') then begin
      Ns := R.GetNamespaceURI;
      AssertEquals('urn:y', Ns);
      SeenStart := True;
    end;
  end;
  AssertTrue('should see non-self-closing start element with bound prefix', SeenStart);
end;

procedure TTestCase_Xml_NS_Reader.Test_Unbound_Prefix_Error;
var R: IXmlReader; Raised: Boolean;
begin
  R := CreateXmlReader.ReadFromString('<r><p:a/></r>');
  Raised := False;
  try while R.Read do ; except on E: EXmlParseError do Raised := True; end;
  AssertTrue('unbound prefix should raise', Raised);
end;

initialization
  if GetEnvironmentVariable('FAFAFA_TEST_SILENT_REG') <> '1' then
    Writeln('Registering TTestCase_Xml_NS_Reader');
  RegisterTest(TTestCase_Xml_NS_Reader);

end.

