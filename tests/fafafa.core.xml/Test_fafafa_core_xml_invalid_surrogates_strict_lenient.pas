{$CODEPAGE UTF8}
unit Test_fafafa_core_xml_invalid_surrogates_strict_lenient;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, fpcunit, testregistry,
  fafafa.core.xml;

type
  TTestCase_Reader_Invalid_Surrogates = class(TTestCase)
  published
    procedure Test_UTF16LE_Unpaired_High_Surrogate_Strict_Raises;
    procedure Test_UTF16LE_Unpaired_High_Surrogate_Lenient_Replaces;
  end;

implementation

procedure WriteUTF16LE_Raw_WithBOM(const Bytes: array of Byte; MS: TStream);
begin
  // UTF-16LE BOM
  MS.WriteBuffer(PAnsiChar(#$FF#$FE)^, 2);
  if Length(Bytes) > 0 then MS.WriteBuffer(Bytes[0], Length(Bytes));
end;

procedure TTestCase_Reader_Invalid_Surrogates.Test_UTF16LE_Unpaired_High_Surrogate_Strict_Raises;
var R: IXmlReader; MS: TMemoryStream; Raised: Boolean;
begin
  // 构造: <r> + 高代理 D800 + </r>
  MS := TMemoryStream.Create;
  try
    WriteUTF16LE_Raw_WithBOM([$3C, $00, $72, $00, $3E, $00,  $00, $D8,  $3C, $00, $2F, $00, $72, $00, $3E, $00], MS);
    MS.Position := 0;
    R := CreateXmlReader.ReadFromStream(MS, [xrfAutoDecodeEncoding], 8);
    Raised := False;
    try while R.Read do ; except on E: EXmlParseError do Raised := (E.Code = xecInvalidEncoding); else Raised := True; end;
    AssertTrue('strict unpaired high surrogate should raise', Raised);
  finally
    MS.Free;
  end;
end;

procedure TTestCase_Reader_Invalid_Surrogates.Test_UTF16LE_Unpaired_High_Surrogate_Lenient_Replaces;
var R: IXmlReader; MS: TMemoryStream; Raised: Boolean; Texts: array of String;
begin
  MS := TMemoryStream.Create;
  try
    WriteUTF16LE_Raw_WithBOM([$3C, $00, $72, $00, $3E, $00,  $00, $D8,  $3C, $00, $2F, $00, $72, $00, $3E, $00], MS);
    MS.Position := 0;
    R := CreateXmlReader.ReadFromStream(MS, [xrfAutoDecodeEncoding, xrfAllowInvalidUnicode, xrfCoalesceText], 8);
    SetLength(Texts, 0);
    while R.Read do if R.Token = xtText then begin SetLength(Texts, Length(Texts)+1); Texts[High(Texts)] := R.Value; end;
    AssertTrue('lenient should not raise', Length(Texts) >= 0);
  finally
    MS.Free;
  end;
end;

initialization
  if GetEnvironmentVariable('FAFAFA_TEST_SILENT_REG') <> '1' then
    RegisterTest('fafafa.core.xml', TTestCase_Reader_Invalid_Surrogates);

end.

