unit Test_fafafa_core_xml_reader_bom;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, fpcunit, testregistry,
  fafafa.core.xml;

type
  TTestCase_Reader_BOM = class(TTestCase)
  private
    procedure WriteUTF32LE_WithBOM(const S: RawByteString; MS: TStream);
    procedure WriteUTF32BE_WithBOM(const S: RawByteString; MS: TStream);
    procedure DoTest_UTF32_Internal(IsLE: Boolean);
  published
    procedure Test_UTF8_BOM_OK;
    procedure Test_UTF16_BOM_Unsupported_AssumeUTF8_Default;
    procedure Test_UTF16_BOM_AutoDecode_OK;
    procedure Test_UTF32_BOM_Default_Unsupported_AutoDecode_OK_LE;
    procedure Test_UTF32_BOM_Default_Unsupported_AutoDecode_OK_BE;
  end;

implementation

procedure TTestCase_Reader_BOM.Test_UTF8_BOM_OK;
var R: IXmlReader; MS: TMemoryStream; Vals: array of TXmlToken; i: Integer;
    Data: AnsiString;
begin
  MS := TMemoryStream.Create;
  try
    // UTF-8 BOM EF BB BF + 简单 XML
    MS.WriteBuffer(PAnsiChar(#$EF#$BB#$BF)^, 3);
    Data := '<r>t</r>';
    MS.WriteBuffer(PAnsiChar(Data)^, Length(Data));
    MS.Position := 0;
    R := CreateXmlReader.ReadFromStream(MS, [xrfCoalesceText]);
    SetLength(Vals, 0);
    while R.Read do begin i := Length(Vals); SetLength(Vals, i+1); Vals[i] := R.Token; end;
    // 期望存在 StartElement / Text / EndElement
    AssertTrue('has tokens', Length(Vals) >= 3);
  finally
    MS.Free;
  end;
end;

procedure TTestCase_Reader_BOM.Test_UTF16_BOM_Unsupported_AssumeUTF8_Default;
var R: IXmlReader; MS: TMemoryStream; Raised: Boolean;
    Data: AnsiString;
begin
  MS := TMemoryStream.Create;
  try
    // UTF-16 LE BOM FF FE + 伪内容
    MS.WriteBuffer(PAnsiChar(#$FF#$FE)^, 2);
    Data := '<r/>';
    MS.WriteBuffer(PAnsiChar(Data)^, Length(Data));
    MS.Position := 0;
    R := CreateXmlReader.ReadFromStream(MS, []); // 默认 AssumeUTF8，遇 UTF-16 应报错
    Raised := False;
    try
      while R.Read do ;
    except
      on E: EXmlParseError do begin Raised := (E.Code = xecInvalidEncoding); end;
      else Raised := True;
    end;
    AssertTrue('unsupported UTF-16 should raise by default', Raised);
  finally
    MS.Free;
  end;
end;

procedure TTestCase_Reader_BOM.Test_UTF16_BOM_AutoDecode_OK;
const
  Utf16LE: array[0..17] of Byte = (
    $FF, $FE,  // BOM
    $3C, $00,  // '<'
    $72, $00,  // 'r'
    $3E, $00,  // '>'
    $74, $00,  // 't'
    $3C, $00,  // '<'
    $2F, $00,  // '/'
    $72, $00,  // 'r'
    $3E, $00   // '>'
  );
var R: IXmlReader; MS: TMemoryStream; Vals: array of TXmlToken; i: Integer;
begin
  MS := TMemoryStream.Create;
  try
    // UTF-16 LE BOM FF FE + "<r>t</r>" 的 UTF-16LE 字节序列
    // 字符序列: < r > t < / r >
    // UTF-16LE: 每个 ASCII 字节后跟 0x00
    MS.WriteBuffer(Utf16LE, SizeOf(Utf16LE));
    MS.Position := 0;
    R := CreateXmlReader.ReadFromStream(MS, [xrfCoalesceText, xrfAutoDecodeEncoding]);
    SetLength(Vals, 0);
    while R.Read do begin i := Length(Vals); SetLength(Vals, i+1); Vals[i] := R.Token; end;
    AssertTrue('auto-decode produces tokens', Length(Vals) >= 3);
  finally
    MS.Free;
  end;
end;

procedure TTestCase_Reader_BOM.WriteUTF32LE_WithBOM(const S: RawByteString; MS: TStream);
var i: Integer; b: array[0..3] of Byte;
begin
  // UTF-32 LE BOM
  b[0]:=$FF; b[1]:=$FE; b[2]:=$00; b[3]:=$00; MS.WriteBuffer(b,4);
  for i := 1 to Length(S) do begin b[0]:=Byte(S[i]); b[1]:=0; b[2]:=0; b[3]:=0; MS.WriteBuffer(b,4); end;
end;

procedure TTestCase_Reader_BOM.WriteUTF32BE_WithBOM(const S: RawByteString; MS: TStream);
var i: Integer; b: array[0..3] of Byte;
begin
  // UTF-32 BE BOM
  b[0]:=$00; b[1]:=$00; b[2]:=$FE; b[3]:=$FF; MS.WriteBuffer(b,4);
  for i := 1 to Length(S) do begin b[0]:=0; b[1]:=0; b[2]:=0; b[3]:=Byte(S[i]); MS.WriteBuffer(b,4); end;
end;

procedure TTestCase_Reader_BOM.DoTest_UTF32_Internal(IsLE: Boolean);
var R: IXmlReader; MS: TMemoryStream; Raised: Boolean; Vals: array of TXmlToken; i: Integer;
begin
  MS := TMemoryStream.Create;
  try
    if IsLE then
      WriteUTF32LE_WithBOM('<r>t</r>', MS)
    else
      WriteUTF32BE_WithBOM('<r>t</r>', MS);
    MS.Position := 0;
    // 默认：应报错
    R := CreateXmlReader.ReadFromStream(MS, []);
    Raised := False;
    try
      while R.Read do ;
    except
      on E: EXmlParseError do Raised := (E.Code = xecInvalidEncoding);
      else Raised := True;
    end;
    AssertTrue('utf-32 default unsupported', Raised);
    // AutoDecode：应成功
    MS.Position := 0;
    SetLength(Vals, 0);
    R := CreateXmlReader.ReadFromStream(MS, [xrfCoalesceText, xrfAutoDecodeEncoding]);
    while R.Read do begin i := Length(Vals); SetLength(Vals, i+1); Vals[i] := R.Token; end;
    AssertTrue('utf-32 autodecode tokens', Length(Vals) >= 3);
  finally
    MS.Free;
  end;
end;

procedure TTestCase_Reader_BOM.Test_UTF32_BOM_Default_Unsupported_AutoDecode_OK_LE;
begin
  DoTest_UTF32_Internal(True);
end;

procedure TTestCase_Reader_BOM.Test_UTF32_BOM_Default_Unsupported_AutoDecode_OK_BE;
begin
  DoTest_UTF32_Internal(False);
end;

initialization
  if GetEnvironmentVariable('FAFAFA_TEST_SILENT_REG') <> '1' then
    RegisterTest('fafafa.core.xml', TTestCase_Reader_BOM);

end.
