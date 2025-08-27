{$CODEPAGE UTF8}
unit Test_fafafa_core_xml_reader_stream_chunks;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, fpcunit, testregistry,
  fafafa.core.xml;

// 为了让 Reader 走流式路径，我们走 ReadFromStream
procedure RunReadFromStream(const S: AnsiString; var Tokens: array of TXmlToken; out TextCount: Integer);

implementation

procedure RunReadFromStream(const S: AnsiString; var Tokens: array of TXmlToken; out TextCount: Integer);
var
  MS: TMemoryStream;
  R: IXmlReader;
  i: Integer;
begin
  MS := TMemoryStream.Create;
  try
    if Length(S) > 0 then MS.WriteBuffer(S[1], Length(S));
    MS.Position := 0;
    R := CreateXmlReader.ReadFromStream(MS, [xrfIgnoreWhitespace, xrfIgnoreComments]);
    i := 0; TextCount := 0;
    while R.Read do
    begin
      if (R.Token = xtText) then Inc(TextCount);
      if (i < Length(Tokens)) then begin Tokens[i] := R.Token; Inc(i); end;
      if i >= Length(Tokens) then Break;
    end;
  finally
    MS.Free;
  end;
end;

type
  TTestCase_Reader_StreamChunks = class(TTestCase)
  published
    procedure Test_Text_CrossChunk;
    procedure Test_CDATA_CrossChunk;
    procedure Test_PI_CrossChunk;
  end;

procedure TTestCase_Reader_StreamChunks.Test_Text_CrossChunk;
var
  S: AnsiString; Toks: array[0..31] of TXmlToken; TextCnt: Integer;
begin
  // 构造较大的文本，概率性跨块（不依赖具体块大小）
  S := '<?xml version="1.0"?><root>' + StringOfChar('x', 200000) + '<child/></root>';
  FillChar(Toks, SizeOf(Toks), 0);
  RunReadFromStream(S, Toks, TextCnt);
  AssertTrue('Should produce at least one text token', TextCnt >= 1);
end;

procedure TTestCase_Reader_StreamChunks.Test_CDATA_CrossChunk;
var
  S: AnsiString; Toks: array[0..31] of TXmlToken; TextCnt: Integer;
begin
  S := '<?xml version="1.0"?><root><![CDATA[' + StringOfChar('y', 200000) + ']]><e/></root>';
  FillChar(Toks, SizeOf(Toks), 0);
  RunReadFromStream(S, Toks, TextCnt);
  // 期望读到一个 CDATA token（在任意位置即可）
  AssertTrue('Should include a CDATA token',
    (Toks[0]=xtCData) or (Toks[1]=xtCData) or (Toks[2]=xtCData) or (Toks[3]=xtCData) or
    (Toks[4]=xtCData) or (Toks[5]=xtCData) or (Toks[6]=xtCData) or (Toks[7]=xtCData) or
    (Toks[8]=xtCData) or (Toks[9]=xtCData) or (Toks[10]=xtCData) or (Toks[11]=xtCData) or
    (Toks[12]=xtCData) or (Toks[13]=xtCData) or (Toks[14]=xtCData) or (Toks[15]=xtCData));
end;

procedure TTestCase_Reader_StreamChunks.Test_PI_CrossChunk;
var
  S: AnsiString; Toks: array[0..31] of TXmlToken; TextCnt: Integer;
begin
  S := '<?xml version="1.0"?><root><?pi ' + StringOfChar('z', 200000) + '?></root>';
  FillChar(Toks, SizeOf(Toks), 0);
  RunReadFromStream(S, Toks, TextCnt);
  AssertTrue('Should include a PI token',
    (Toks[0]=xtPI) or (Toks[1]=xtPI) or (Toks[2]=xtPI) or (Toks[3]=xtPI) or
    (Toks[4]=xtPI) or (Toks[5]=xtPI) or (Toks[6]=xtPI) or (Toks[7]=xtPI) or
    (Toks[8]=xtPI) or (Toks[9]=xtPI) or (Toks[10]=xtPI) or (Toks[11]=xtPI) or
    (Toks[12]=xtPI) or (Toks[13]=xtPI) or (Toks[14]=xtPI) or (Toks[15]=xtPI));
end;

initialization
  RegisterTest(TTestCase_Reader_StreamChunks);

end.

