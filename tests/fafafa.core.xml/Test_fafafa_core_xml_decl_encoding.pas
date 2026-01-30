unit Test_fafafa_core_xml_decl_encoding;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, fpcunit, testregistry,
  fafafa.core.xml;

type
  TTestCase_Reader_Decl_Encoding = class(TTestCase)
  published
    procedure Test_Decl_UTF8_OK_AutoDecode_On;
    procedure Test_Decl_NonUTF8_Unsupported_AutoDecode_On;
  end;

implementation

procedure TTestCase_Reader_Decl_Encoding.Test_Decl_UTF8_OK_AutoDecode_On;
var R: IXmlReader; S: AnsiString; Vals: array of TXmlToken; i: Integer;
begin
  S := '<?xml version="1.0" encoding="UTF-8"?><r/>';
  R := CreateXmlReader.ReadFromString(S, [xrfAutoDecodeEncoding]);
  SetLength(Vals, 0);
  while R.Read do begin i := Length(Vals); SetLength(Vals, i+1); Vals[i] := R.Token; end;
  AssertTrue('decl utf-8 ok', Length(Vals) >= 1);
end;

procedure TTestCase_Reader_Decl_Encoding.Test_Decl_NonUTF8_Unsupported_AutoDecode_On;
var R: IXmlReader; S: AnsiString; Raised: Boolean;
begin
  S := '<?xml version="1.0" encoding="ISO-8859-1"?><r/>';
  R := CreateXmlReader.ReadFromString(S, [xrfAutoDecodeEncoding]);
  Raised := False;
  try
    while R.Read do ;
  except
    on E: EXmlParseError do Raised := (E.Code = xecInvalidEncoding);
    else Raised := True;
  end;
  AssertTrue('decl non-utf8 should be unsupported now', Raised);
end;

initialization
  if GetEnvironmentVariable('FAFAFA_TEST_SILENT_REG') <> '1' then
    RegisterTest('fafafa.core.xml', TTestCase_Reader_Decl_Encoding);

end.

