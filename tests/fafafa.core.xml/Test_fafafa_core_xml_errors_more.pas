{$CODEPAGE UTF8}
unit Test_fafafa_core_xml_errors_more;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, fpcunit, testregistry,
  fafafa.core.xml;

type
  TTestCase_XmlErrors_More = class(TTestCase)
  published
    procedure Test_Unterminated_CDATA;
    procedure Test_Unterminated_PI;
  end;

implementation

procedure TTestCase_XmlErrors_More.Test_Unterminated_CDATA;
var R: IXmlReader; Raised: Boolean;
begin
  R := CreateXmlReader.ReadFromString('<a><![CDATA[oops</a>');
  Raised := False;
  try
    while R.Read do ;
  except
    on E: EXmlParseError do
    begin
      Raised := True;
      AssertEquals(Ord(xecMalformedXml), Ord(E.Code));
    end;
  end;
  AssertTrue('Should raise EXmlParseError for unterminated CDATA', Raised);
end;

procedure TTestCase_XmlErrors_More.Test_Unterminated_PI;
var R: IXmlReader; Raised: Boolean;
begin
  R := CreateXmlReader.ReadFromString('<a><?pi</a>');
  Raised := False;
  try
    while R.Read do ;
  except
    on E: EXmlParseError do
    begin
      Raised := True;
      AssertEquals(Ord(xecMalformedXml), Ord(E.Code));
    end;
  end;
  AssertTrue('Should raise EXmlParseError for unterminated PI', Raised);
end;

initialization
  RegisterTest(TTestCase_XmlErrors_More);

end.

