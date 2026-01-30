{$CODEPAGE UTF8}
unit Test_fafafa_core_xml_errors_tags2;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, fpcunit, testregistry,
  fafafa.core.xml;

type
  TTestCase_XmlErrors_Tags2 = class(TTestCase)
  published
    procedure Test_Mismatched_EndTag;
  end;

implementation

procedure TTestCase_XmlErrors_Tags2.Test_Mismatched_EndTag;
var R: IXmlReader; Raised: Boolean;
begin
  // <a></b>
  R := CreateXmlReader.ReadFromString('<a></b>');
  Raised := False;
  try
    while R.Read do ;
  except
    on E: EXmlParseError do
      Raised := True;
  end;
  AssertTrue('Should raise for mismatched end tag', Raised);
end;

initialization
  RegisterTest(TTestCase_XmlErrors_Tags2);

end.

