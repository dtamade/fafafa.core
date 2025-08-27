{$CODEPAGE UTF8}
unit Test_fafafa_core_xml_reader_charrefs_hex_illegal_smallbuf;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, fpcunit, testregistry,
  fafafa.core.xml;

implementation

type
  TTestCase_Reader_CharRefs_HexIllegal_SmallBuf = class(TTestCase)
  published
    procedure Test_Text_CharRef_HexIllegal_CrossChunk_SmallBuf;
  end;

procedure TTestCase_Reader_CharRefs_HexIllegal_SmallBuf.Test_Text_CharRef_HexIllegal_CrossChunk_SmallBuf;
var
  S: AnsiString; MS: TMemoryStream; R: IXmlReader; Tok: TXmlToken;
  Combined: AnsiString = '';
begin
  // 非法十六进制字符 'G' 出现在 &#x... 中，要求不崩溃且能推进
  S := '<?xml version="1.0"?><root>' + StringOfChar('x', 1000) + '&#x4G;' + StringOfChar('y', 1000) + '</root>';
  MS := TMemoryStream.Create;
  try
    if Length(S) > 0 then MS.WriteBuffer(S[1], Length(S));
    MS.Position := 0;
    R := CreateXmlReader.ReadFromStream(MS, [xrfIgnoreWhitespace], 64);
    while R.Read do if R.Token = xtText then Combined += AnsiString(R.Value);
    AssertTrue('Reader should not crash on illegal hex char in numeric entity', Length(Combined) > 0);
  finally
    MS.Free;
  end;
end;

initialization
  RegisterTest(TTestCase_Reader_CharRefs_HexIllegal_SmallBuf);

end.

