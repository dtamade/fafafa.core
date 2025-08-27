{$CODEPAGE UTF8}
unit Test_fafafa_core_xml_reader_stream_smallbuf;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, fpcunit, testregistry,
  fafafa.core.xml;

implementation

type
  TTestCase_Reader_StreamSmallBuf = class(TTestCase)
  published
    procedure Test_Text_Entity_CrossChunk_SmallBuf;
  end;

procedure TTestCase_Reader_StreamSmallBuf.Test_Text_Entity_CrossChunk_SmallBuf;
var
  S: AnsiString; MS: TMemoryStream; R: IXmlReader;
  Tok: TXmlToken; Texts: Integer; V: String;
begin
  // 构造包含实体且很长的文本，强制跨多个小块
  S := '<?xml version="1.0"?><root>' + StringOfChar('A', 1000) + '&amp;' + StringOfChar('B', 1000) + '</root>';
  MS := TMemoryStream.Create;
  try
    if Length(S) > 0 then MS.WriteBuffer(S[1], Length(S));
    MS.Position := 0;
    // 极小缓冲区触发频繁跨块
    R := CreateXmlReader.ReadFromStream(MS, [xrfIgnoreWhitespace], 64);
    Texts := 0;
    while R.Read do
    begin
      Tok := R.Token;
      if Tok = xtText then
      begin
        Inc(Texts);
        V := R.Value; // 应该正确解码实体
        // 验证中间有一个 & 符号（由 &amp; 解码）
        AssertTrue('Text should contain decoded &', Pos('&', V) > 0);
      end;
    end;
    AssertTrue('Should see text tokens', Texts > 0);
  finally
    MS.Free;
  end;
end;

initialization
  RegisterTest(TTestCase_Reader_StreamSmallBuf);

end.

