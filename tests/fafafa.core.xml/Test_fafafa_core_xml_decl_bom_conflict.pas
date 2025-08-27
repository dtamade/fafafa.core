{$CODEPAGE UTF8}
unit Test_fafafa_core_xml_decl_bom_conflict;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, fpcunit, testregistry,
  fafafa.core.xml;

type
  TTestCase_Reader_Decl_BOM_Conflict = class(TTestCase)
  published
    procedure Test_UTF16_BOM_Decl_UTF16_Conflict_Raises;
    procedure Test_UTF32_BOM_Decl_UTF16_Conflict_Raises;
  end;

implementation

procedure WriteUTF16LE_WithBOM_Bytes(const S: RawByteString; MS: TStream);
var i: Integer; b0,b1: Byte;
begin
  // UTF-16 LE BOM
  MS.WriteBuffer(PAnsiChar(#$FF#$FE)^, 2);
  for i := 1 to Length(S) do begin b0 := Byte(S[i]); b1 := 0; MS.WriteBuffer(b0,1); MS.WriteBuffer(b1,1); end;
end;

procedure WriteUTF32LE_WithBOM_Bytes(const S: RawByteString; MS: TStream);
var i: Integer; b: array[0..3] of Byte;
begin
  // UTF-32 LE BOM
  b[0]:=$FF; b[1]:=$FE; b[2]:=$00; b[3]:=$00; MS.WriteBuffer(b,4);
  for i := 1 to Length(S) do begin b[0]:=Byte(S[i]); b[1]:=0; b[2]:=0; b[3]:=0; MS.WriteBuffer(b,4); end;
end;

procedure TTestCase_Reader_Decl_BOM_Conflict.Test_UTF16_BOM_Decl_UTF16_Conflict_Raises;
var R: IXmlReader; MS: TMemoryStream; Raised: Boolean; S: RawByteString;
begin
  // 声明 encoding="utf-16" 与 BOM 冲突策略：当前实现抛错（仅支持 UTF-8 声明或基于 BOM 自动识别）
  S := '<?xml version="1.0" encoding="utf-16"?><r/>';
  MS := TMemoryStream.Create;
  try
    WriteUTF16LE_WithBOM_Bytes(S, MS);
    MS.Position := 0;
    R := CreateXmlReader.ReadFromStream(MS, [xrfAutoDecodeEncoding], 32);
    Raised := False;
    try while R.Read do ; except on E: EXmlParseError do Raised := (E.Code = xecInvalidEncoding); else Raised := True; end;
    AssertTrue('decl utf-16 with UTF-16 BOM should raise conflict in current policy', Raised);
  finally
    MS.Free;
  end;
end;

procedure TTestCase_Reader_Decl_BOM_Conflict.Test_UTF32_BOM_Decl_UTF16_Conflict_Raises;
var R: IXmlReader; MS: TMemoryStream; Raised: Boolean; S: RawByteString;
begin
  // UTF-32 BOM + 声明 utf-16：同样按冲突/不支持处理
  S := '<?xml version="1.0" encoding="utf-16"?><r/>';
  MS := TMemoryStream.Create;
  try
    WriteUTF32LE_WithBOM_Bytes(S, MS);
    MS.Position := 0;
    R := CreateXmlReader.ReadFromStream(MS, [xrfAutoDecodeEncoding], 32);
    Raised := False;
    try while R.Read do ; except on E: EXmlParseError do Raised := (E.Code = xecInvalidEncoding); else Raised := True; end;
    AssertTrue('decl utf-16 with UTF-32 BOM should raise conflict in current policy', Raised);
  finally
    MS.Free;
  end;
end;

initialization
  if GetEnvironmentVariable('FAFAFA_TEST_SILENT_REG') <> '1' then
    RegisterTest('fafafa.core.xml', TTestCase_Reader_Decl_BOM_Conflict);

end.

