{$CODEPAGE UTF8}
unit Test_fafafa_core_xml_decl_encoding_variants;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, fpcunit, testregistry,
  fafafa.core.xml;

type
  TTestCase_Reader_Decl_Encoding_Variants = class(TTestCase)
  published
    procedure Test_Decl_UTF8_Lowercase_Spaced_OK;
    procedure Test_Decl_UTF8_SingleQuoted_OK;
    procedure Test_Decl_Encoding_Attr_Order_Variant_OK;
  end;

implementation

procedure TTestCase_Reader_Decl_Encoding_Variants.Test_Decl_UTF8_Lowercase_Spaced_OK;
var R: IXmlReader; S: AnsiString; Count: Integer;
begin
  S := '<?xml version = "1.0"   encoding = "utf-8"?>\n<r/>';
  R := CreateXmlReader.ReadFromString(S, []);
  Count := 0; while R.Read do Inc(Count);
  AssertTrue('decl utf-8 lowercase with spaces ok', Count >= 1);
end;

procedure TTestCase_Reader_Decl_Encoding_Variants.Test_Decl_UTF8_SingleQuoted_OK;
var R: IXmlReader; S: AnsiString; Count: Integer;
begin
  S := '<?xml version="1.0" encoding=''UTF-8''?><r/>';
  R := CreateXmlReader.ReadFromString(S, []);
  Count := 0; while R.Read do Inc(Count);
  AssertTrue('decl utf-8 single quote ok', Count >= 1);
end;

procedure TTestCase_Reader_Decl_Encoding_Variants.Test_Decl_Encoding_Attr_Order_Variant_OK;
var R: IXmlReader; S: AnsiString; Count: Integer;
begin
  // encoding 在 version 之前，且大小写混合，允许
  S := '<?xml encoding="Utf-8" version="1.0"?><r/>';
  R := CreateXmlReader.ReadFromString(S, []);
  Count := 0; while R.Read do Inc(Count);
  AssertTrue('decl encoding before version ok', Count >= 1);
end;

initialization
  if GetEnvironmentVariable('FAFAFA_TEST_SILENT_REG') <> '1' then
    RegisterTest('fafafa.core.xml', TTestCase_Reader_Decl_Encoding_Variants);

end.

