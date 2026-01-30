{$CODEPAGE UTF8}
unit Test_fafafa_core_xml_errors_attrs_more;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, fpcunit, testregistry,
  fafafa.core.xml;

implementation

type
  TTestCase_XmlErrors_Attrs_More = class(TTestCase)
  published
    procedure Test_Attr_Name_Unterminated;          // <a attr
    procedure Test_Attr_Value_Missing_Quotes;       // <a k=v>
    procedure Test_Attr_Unbound_Prefix;             // <a p:k="v">
  end;

procedure TTestCase_XmlErrors_Attrs_More.Test_Attr_Name_Unterminated;
var
  R: IXmlReader; Raised: Boolean; Guard: SizeInt;
begin
  R := CreateXmlReader.ReadFromString('<a attr');
  Raised := False; Guard := 0;
  try
    while R.Read do
    begin
      Inc(Guard);
      if Guard > 100000 then Fail('Guard triggered (Attr_Name_Unterminated)');
    end;
  except
    on E: EXmlParseError do Raised := True;
  end;
  AssertTrue('Should raise for unterminated attribute name/value', Raised);
end;

procedure TTestCase_XmlErrors_Attrs_More.Test_Attr_Value_Missing_Quotes;
var
  R: IXmlReader; Raised: Boolean; Guard: SizeInt;
begin
  R := CreateXmlReader.ReadFromString('<a k=v>');
  Raised := False; Guard := 0;
  try
    while R.Read do
    begin
      Inc(Guard);
      if Guard > 100000 then Fail('Guard triggered (Attr_Value_Missing_Quotes)');
    end;
  except
    on E: EXmlParseError do Raised := True;
  end;
  AssertTrue('Should raise for attribute value not quoted', Raised);
end;

procedure TTestCase_XmlErrors_Attrs_More.Test_Attr_Unbound_Prefix;
var
  R: IXmlReader; Raised: Boolean; Guard: SizeInt;
begin
  R := CreateXmlReader.ReadFromString('<a p:k="v">');
  Raised := False; Guard := 0;
  try
    while R.Read do
    begin
      Inc(Guard);
      if Guard > 100000 then Fail('Guard triggered (Attr_Unbound_Prefix)');
    end;
  except
    on E: EXmlParseError do Raised := True;
  end;
  AssertTrue('Should raise for unbound attribute prefix', Raised);
end;

initialization
  RegisterTest(TTestCase_XmlErrors_Attrs_More);

end.

