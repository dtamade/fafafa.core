{$CODEPAGE UTF8}
unit Test_fafafa_core_xml_stream_transcode_smallbuf;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, fpcunit, testregistry,
  fafafa.core.xml;

type
  TTestCase_Reader_Stream_Transcode = class(TTestCase)
  published
    procedure Test_UTF16LE_SmallBuf_Text_Entity_CrossChunk_OK;
    procedure Test_UTF32LE_SmallBuf_Text_CDATA_CrossChunk_OK;
  end;

implementation

procedure WriteUTF16LE_WithBOM_Text(const S: RawByteString; MS: TStream);
var i: Integer; b0,b1: Byte;
begin
  MS.WriteBuffer(PAnsiChar(#$FF#$FE)^, 2);
  for i := 1 to Length(S) do begin b0 := Byte(S[i]); b1 := 0; MS.WriteBuffer(b0,1); MS.WriteBuffer(b1,1); end;
end;

procedure WriteUTF32LE_WithBOM_Text(const S: RawByteString; MS: TStream);
var i: Integer; b: array[0..3] of Byte;
begin
  b[0]:=$FF; b[1]:=$FE; b[2]:=$00; b[3]:=$00; MS.WriteBuffer(b,4);
  for i := 1 to Length(S) do begin b[0]:=Byte(S[i]); b[1]:=0; b[2]:=0; b[3]:=0; MS.WriteBuffer(b,4); end;
end;

procedure TTestCase_Reader_Stream_Transcode.Test_UTF16LE_SmallBuf_Text_Entity_CrossChunk_OK;
var R: IXmlReader; MS: TMemoryStream; Tok: TXmlToken; Texts: array of String; S: RawByteString;
begin
  // 构造: <r>ab&amp;cd</r>，实体将跨块
  S := '<r>ab&amp;cd</r>';
  MS := TMemoryStream.Create;
  try
    WriteUTF16LE_WithBOM_Text(S, MS);
    MS.Position := 0;
    R := CreateXmlReader.ReadFromStream(MS, [xrfAutoDecodeEncoding, xrfCoalesceText], 8);
    SetLength(Texts, 0);
    while R.Read do
      if R.Token = xtText then begin SetLength(Texts, Length(Texts)+1); Texts[High(Texts)] := R.Value; end;
    AssertTrue('should see at least one text', Length(Texts) >= 1);
    AssertTrue('entity decoded', Pos('&', Texts[0]) = 0);
    AssertTrue('content contains abcd', Pos('abcd', Texts[0]) > 0);
  finally
    MS.Free;
  end;
end;

procedure TTestCase_Reader_Stream_Transcode.Test_UTF32LE_SmallBuf_Text_CDATA_CrossChunk_OK;
var R: IXmlReader; MS: TMemoryStream; Texts: array of String; S: RawByteString;
begin
  // 构造: <r><![CDATA[xy]]>z</r>，CDAT A/文本跨块
  S := '<r><![CDATA[xy]]>z</r>';
  MS := TMemoryStream.Create;
  try
    WriteUTF32LE_WithBOM_Text(S, MS);
    MS.Position := 0;
    R := CreateXmlReader.ReadFromStream(MS, [xrfAutoDecodeEncoding, xrfCoalesceText], 8);
    SetLength(Texts, 0);
    while R.Read do
      if R.Token = xtText then begin SetLength(Texts, Length(Texts)+1); Texts[High(Texts)] := R.Value; end;
    AssertTrue('should see at least one text', Length(Texts) >= 1);
    AssertTrue('contains xyz', Pos('xyz', Texts[0]) > 0);
  finally
    MS.Free;
  end;
end;

initialization
  if GetEnvironmentVariable('FAFAFA_TEST_SILENT_REG') <> '1' then
    RegisterTest('fafafa.core.xml', TTestCase_Reader_Stream_Transcode);

end.

