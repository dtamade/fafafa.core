{$CODEPAGE UTF8}
unit Test_fafafa_core_xml_reader_charrefs_nonascii_smallbuf;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, fpcunit, testregistry,
  fafafa.core.xml;

implementation

type
  TTestCase_Reader_CharRefs_NonAscii_SmallBuf = class(TTestCase)
  published
    procedure Test_Text_CharRef_Unicode_CrossChunk_SmallBuf;
  end;

procedure TTestCase_Reader_CharRefs_NonAscii_SmallBuf.Test_Text_CharRef_Unicode_CrossChunk_SmallBuf;
var
  S: AnsiString; MS: TMemoryStream; R: IXmlReader;
  Tok: TXmlToken; Combined: AnsiString = '';
  i, CntNi: SizeInt; // '你' (U+4F60) in UTF-8: E4 BD A0
begin
  // 包含非 ASCII 的字符引用，且强制跨块：先 1000 个 'x'，再 &#x4F60;，再 1000 个 'y'
  S := '<?xml version="1.0"?><root>' + StringOfChar('x', 1000) + '&#x4F60;' + StringOfChar('y', 1000) + '</root>';
  MS := TMemoryStream.Create;
  try
    if Length(S) > 0 then MS.WriteBuffer(S[1], Length(S));
    MS.Position := 0;
    R := CreateXmlReader.ReadFromStream(MS, [xrfIgnoreWhitespace], 64);
    while R.Read do
    begin
      Tok := R.Token;
      if Tok = xtText then Combined += AnsiString(R.Value);
    end;
    AssertTrue('Combined text should be non-empty', Length(Combined) > 0);
    // 统计 UTF-8 三字节序列 E4 BD A0 的出现次数，应至少出现 1 次
    CntNi := 0;
    i := 1;
    while i <= Length(Combined) - 2 do
    begin
      if (Byte(Combined[i]) = $E4) and (Byte(Combined[i+1]) = $BD) and (Byte(Combined[i+2]) = $A0) then
      begin
        Inc(CntNi);
        Inc(i, 3);
      end
      else
        Inc(i);
    end;
    AssertTrue('Unicode CharRef should be decoded to UTF-8 for 你 (>=1)', CntNi >= 1);
  finally
    MS.Free;
  end;
end;

initialization
  RegisterTest(TTestCase_Reader_CharRefs_NonAscii_SmallBuf);

end.

