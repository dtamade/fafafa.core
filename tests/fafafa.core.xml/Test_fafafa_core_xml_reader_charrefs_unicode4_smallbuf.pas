{$CODEPAGE UTF8}
unit Test_fafafa_core_xml_reader_charrefs_unicode4_smallbuf;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, fpcunit, testregistry,
  fafafa.core.xml;

implementation

type
  TTestCase_Reader_CharRefs_Unicode4_SmallBuf = class(TTestCase)
  published
    procedure Test_Text_CharRef_Unicode4_CrossChunk_SmallBuf;
  end;

procedure TTestCase_Reader_CharRefs_Unicode4_SmallBuf.Test_Text_CharRef_Unicode4_CrossChunk_SmallBuf;
var
  S: AnsiString; MS: TMemoryStream; R: IXmlReader;
  Tok: TXmlToken; Combined: AnsiString = '';
  i, CntEmoji: SizeInt; // 🙂 U+1F60A => F0 9F 98 8A
begin
  S := '<?xml version="1.0"?><root>'
     + StringOfChar('x', 1000) + '&#x1F60A;'
     + StringOfChar('y', 1000) + '&#128522;'
     + '</root>';
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
    // 统计 UTF-8 四字节序列 F0 9F 98 8A 的出现次数，应至少 2 次
    CntEmoji := 0; i := 1;
    while i <= Length(Combined) - 3 do
    begin
      if (Byte(Combined[i]) = $F0) and (Byte(Combined[i+1]) = $9F) and (Byte(Combined[i+2]) = $98) and (Byte(Combined[i+3]) = $8A) then
      begin
        Inc(CntEmoji);
        Inc(i, 4);
      end
      else
        Inc(i);
    end;
    AssertTrue('Unicode4 CharRef (U+1F60A) should decode to UTF-8 (>=2)', CntEmoji >= 2);
  finally
    MS.Free;
  end;
end;

initialization
  RegisterTest(TTestCase_Reader_CharRefs_Unicode4_SmallBuf);

end.

