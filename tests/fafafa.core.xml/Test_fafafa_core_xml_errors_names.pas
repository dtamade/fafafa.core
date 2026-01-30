{$CODEPAGE UTF8}
unit Test_fafafa_core_xml_errors_names;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, fpcunit, testregistry,
  fafafa.core.xml;

implementation

type
  TTestCase_XmlErrors_Names = class(TTestCase)
  published
    procedure Test_Name_Only_LessThan;  // "<"
  end;

procedure TTestCase_XmlErrors_Names.Test_Name_Only_LessThan;
var
  R: IXmlReader; Raised: Boolean; Guard: SizeInt;
begin
  R := CreateXmlReader.ReadFromString('<');
  Raised := False; Guard := 0;
  try
    while R.Read do
    begin
      Inc(Guard);
      if Guard > 100000 then Fail('Guard triggered (Name_Only_LessThan)');
    end;
  except
    on E: EXmlParseError do Raised := True;
  end;
  AssertTrue('Should raise for lone <', Raised);
end;

initialization
  RegisterTest(TTestCase_XmlErrors_Names);

end.

