{$CODEPAGE UTF8}
unit Test_fafafa_core_xml_errors;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, fpcunit, testregistry,
  fafafa.core.xml;

type
  TTestCase_XmlErrors = class(TTestCase)
  published
    procedure Test_Unterminated_Comment;
  end;

implementation

procedure TTestCase_XmlErrors.Test_Unterminated_Comment;
var R: IXmlReader; Raised: Boolean;
begin
  R := CreateXmlReader.ReadFromString('<a><!-- oops</a>');
  Raised := False;
  try
    while R.Read do ;
  except
    on E: EXmlParseError do
    begin
      Raised := True;
      AssertEquals(Ord(xecMalformedXml), Ord(E.Code));
      AssertTrue(E.Line > 0);
      AssertTrue(E.Column > 0);
    end;
  end;
  AssertTrue('Should raise EXmlParseError for unterminated comment', Raised);
end;

initialization
  if GetEnvironmentVariable('FAFAFA_TEST_SILENT_REG') <> '1' then
    Writeln('Registering TTestCase_XmlErrors');
  RegisterTest(TTestCase_XmlErrors);

end.

