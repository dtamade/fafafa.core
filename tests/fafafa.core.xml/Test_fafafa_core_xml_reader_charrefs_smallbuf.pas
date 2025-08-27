{$CODEPAGE UTF8}
unit Test_fafafa_core_xml_reader_charrefs_smallbuf;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, fpcunit, testregistry,
  fafafa.core.xml;

implementation

type
  TTestCase_Reader_CharRefs_SmallBuf = class(TTestCase)
  published
    procedure Test_Text_CharRef_CrossChunk_SmallBuf;
  end;

procedure TTestCase_Reader_CharRefs_SmallBuf.Test_Text_CharRef_CrossChunk_SmallBuf;
var
  S: AnsiString; MS: TMemoryStream; R: IXmlReader;
  Tok: TXmlToken; Combined: String = '';
  i, CntA: SizeInt;
begin
  // 文本中包含十六进制与十进制字符引用，并强制跨块
  S := '<?xml version="1.0"?><root>' + StringOfChar('A', 1000) + '&#x41;' + StringOfChar('B', 1000) + '&#65;' + '</root>';
  MS := TMemoryStream.Create;
  try
    if Length(S) > 0 then MS.WriteBuffer(S[1], Length(S));
    MS.Position := 0;
    R := CreateXmlReader.ReadFromStream(MS, [xrfIgnoreWhitespace], 64);
    while R.Read do
    begin
      Tok := R.Token;
      if Tok = xtText then Combined += R.Value;
    end;
    AssertTrue('Combined text should be non-empty', Length(Combined) > 0);
    // 统计 'A' 的出现次数：应至少包含 1000(连串) + 1(&#x41;) + 1(&#65;) = 1002
    CntA := 0;
    for i := 1 to Length(Combined) do if Combined[i] = 'A' then Inc(CntA);
    AssertTrue('CharRef should be decoded to A (>=1002)', CntA >= 1002);
  finally
    MS.Free;
  end;
end;

initialization
  RegisterTest(TTestCase_Reader_CharRefs_SmallBuf);

end.

