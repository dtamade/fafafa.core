{$CODEPAGE UTF8}
unit Test_fafafa_core_xml_decl_encoding_more;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, fpcunit, testregistry,
  fafafa.core.xml;

type
  TTestCase_Reader_Decl_Encoding_More = class(TTestCase)
  published
    procedure Test_Decl_UTF16_NoBOM_Default_ShouldFail;
    procedure Test_Decl_UTF16_NoBOM_AutoDecode_ShouldFail;
    procedure Test_BOM_UTF16_Decl_UTF32_Conflict_ShouldFail;
  end;

implementation

procedure TTestCase_Reader_Decl_Encoding_More.Test_Decl_UTF16_NoBOM_Default_ShouldFail;
var R: IXmlReader; S: AnsiString; Raised: Boolean;
begin
  // 无 BOM，但声明 UTF-16；默认 Assume UTF-8，应报不支持
  S := '<?xml version="1.0" encoding="UTF-16"?><r/>';
  R := CreateXmlReader.ReadFromString(S, []);
  Raised := False;
  try
    while R.Read do ;
  except
    on E: EXmlParseError do Raised := (E.Code = xecInvalidEncoding);
    else Raised := True;
  end;
  AssertTrue('decl UTF-16 without BOM should fail (default AssumeUTF8)', Raised);
end;

procedure TTestCase_Reader_Decl_Encoding_More.Test_Decl_UTF16_NoBOM_AutoDecode_ShouldFail;
var R: IXmlReader; S: AnsiString; Raised: Boolean;
begin
  // 无 BOM，但声明 UTF-16；即便开启 AutoDecode，仍不应基于声明转码，应报错
  S := '<?xml version="1.0" encoding="UTF-16"?><r/>';
  R := CreateXmlReader.ReadFromString(S, [xrfAutoDecodeEncoding]);
  Raised := False;
  try
    while R.Read do ;
  except
    on E: EXmlParseError do Raised := (E.Code = xecInvalidEncoding);
    else Raised := True;
  end;
  AssertTrue('decl UTF-16 without BOM should fail (even with AutoDecode)', Raised);
end;

procedure TTestCase_Reader_Decl_Encoding_More.Test_BOM_UTF16_Decl_UTF32_Conflict_ShouldFail;
var R: IXmlReader; MS: TMemoryStream; Raised: Boolean;
begin
  // BOM 指示 UTF-16LE，但声明 encoding="UTF-32"，视为冲突，抛错
  MS := TMemoryStream.Create;
  try
    // UTF-16 LE BOM FF FE + ASCII 内容 "<?xml version=... encoding=\"UTF-32\"?><r/>"
    MS.WriteBuffer(PAnsiChar(#$FF#$FE)^, 2);
    // 将 ASCII 串写为 UTF-16LE 字节序（每字节后 0x00）
    var Decl: RawByteString := '<?xml version="1.0" encoding="UTF-32"?><r/>';
    var i: SizeInt;
    for i := 1 to Length(Decl) do begin MS.WriteByte(Byte(Decl[i])); MS.WriteByte(0); end;
    MS.Position := 0;
    R := CreateXmlReader.ReadFromStream(MS, [xrfAutoDecodeEncoding]);
    Raised := False;
    try
      while R.Read do ;
    except
      on E: EXmlParseError do Raised := (E.Code = xecInvalidEncoding);
      else Raised := True;
    end;
    AssertTrue('BOM UTF-16 but decl UTF-32 => conflict should fail', Raised);
  finally
    MS.Free;
  end;
end;

initialization
  if GetEnvironmentVariable('FAFAFA_TEST_SILENT_REG') <> '1' then
    RegisterTest('fafafa.core.xml', TTestCase_Reader_Decl_Encoding_More);

end.

