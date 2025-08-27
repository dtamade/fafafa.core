{$CODEPAGE UTF8}
unit Test_fafafa_core_xml_errors_attrs;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, fpcunit, testregistry,
  fafafa.core.xml;

type
  TTestCase_XmlErrors_Attrs = class(TTestCase)
  published
    procedure Test_Attr_Missing_Equals;
    procedure Test_Attr_Unterminated_Value;
    procedure Test_Duplicate_Attr_Name;
  end;

implementation

procedure TTestCase_XmlErrors_Attrs.Test_Attr_Missing_Equals;
var R: IXmlReader; Raised: Boolean;
begin
  R := CreateXmlReader.ReadFromString('<a k"v"/>');
  Raised := False;
  try while R.Read do ; except on E: EXmlParseError do Raised := True; end;
  AssertTrue('missing = should raise', Raised);
end;

procedure TTestCase_XmlErrors_Attrs.Test_Attr_Unterminated_Value;
var R: IXmlReader; Raised: Boolean;
begin
  R := CreateXmlReader.ReadFromString('<a k="v></a>');
  Raised := False;
  try while R.Read do ; except on E: EXmlParseError do Raised := True; end;
  AssertTrue('unterminated attr value should raise', Raised);
end;

procedure TTestCase_XmlErrors_Attrs.Test_Duplicate_Attr_Name;
var R: IXmlReader; Raised: Boolean;
begin
  R := CreateXmlReader.ReadFromString('<a k="1" k="2"/>');
  Raised := False;
  try while R.Read do ; except on E: EXmlParseError do Raised := True; end;
  AssertTrue('duplicate attribute name should raise', Raised);
end;

initialization
  RegisterTest(TTestCase_XmlErrors_Attrs);

end.

