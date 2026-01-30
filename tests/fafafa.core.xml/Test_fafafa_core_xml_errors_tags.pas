{$CODEPAGE UTF8}
unit Test_fafafa_core_xml_errors_tags;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, fpcunit, testregistry,
  fafafa.core.xml;

type
  TTestCase_XmlErrors_Tags = class(TTestCase)
  published
    procedure Test_Unterminated_StartTag;
  end;

implementation

procedure TTestCase_XmlErrors_Tags.Test_Unterminated_StartTag;
var R: IXmlReader; Raised: Boolean; Guard: SizeInt;
begin
  R := CreateXmlReader.ReadFromString('<a');
  Raised := False; Guard := 0;
  try
    while R.Read do
    begin
      Inc(Guard);
      if Guard > 100000 then Fail('Traversal guard triggered (unterminated start tag)');
    end;
  except
    on E: EXmlParseError do Raised := True;
  end;
  AssertTrue('Should raise for unterminated start tag', Raised);
end;

initialization
  RegisterTest(TTestCase_XmlErrors_Tags);

end.

