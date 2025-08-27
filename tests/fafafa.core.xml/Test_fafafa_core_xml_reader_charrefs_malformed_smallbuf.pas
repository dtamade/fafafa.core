{$CODEPAGE UTF8}
unit Test_fafafa_core_xml_reader_charrefs_malformed_smallbuf;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, fpcunit, testregistry,
  fafafa.core.xml;

implementation

type
  TTestCase_Reader_CharRefs_Malformed_SmallBuf = class(TTestCase)
  published
    procedure Test_Text_CharRef_NoSemicolon_CrossChunk_SmallBuf;
    procedure Test_Text_CharRef_TooLarge_CrossChunk_SmallBuf;
  end;

// 情况1：缺少分号，应当退化为原样字符（不越界、不死循环）
procedure TTestCase_Reader_CharRefs_Malformed_SmallBuf.Test_Text_CharRef_NoSemicolon_CrossChunk_SmallBuf;
var
  S: AnsiString; MS: TMemoryStream; R: IXmlReader; Tok: TXmlToken;
  Combined: AnsiString = '';
begin
  S := '<?xml version="1.0"?><root>' + StringOfChar('x', 1000) + '&#65' + StringOfChar('y', 1000) + '</root>';
  MS := TMemoryStream.Create;
  try
    if Length(S) > 0 then MS.WriteBuffer(S[1], Length(S));
    MS.Position := 0;
    R := CreateXmlReader.ReadFromStream(MS, [xrfIgnoreWhitespace], 64);
    while R.Read do if R.Token = xtText then Combined += AnsiString(R.Value);
    // 这里不硬性验证具体字符，只要不崩溃且能完整读完即可
    AssertTrue('Reader should not crash on malformed entity without semicolon', Length(Combined) > 0);
  finally
    MS.Free;
  end;
end;

// 情况2：超范围码点（> $10FFFF），应退化为 '?' 或原样推进，不崩溃、不死循环
procedure TTestCase_Reader_CharRefs_Malformed_SmallBuf.Test_Text_CharRef_TooLarge_CrossChunk_SmallBuf;
var
  S: AnsiString; MS: TMemoryStream; R: IXmlReader; Tok: TXmlToken;
  Combined: AnsiString = '';
begin
  S := '<?xml version="1.0"?><root>' + StringOfChar('x', 1000) + '&#x110000;' + StringOfChar('y', 1000) + '</root>';
  MS := TMemoryStream.Create;
  try
    if Length(S) > 0 then MS.WriteBuffer(S[1], Length(S));
    MS.Position := 0;
    R := CreateXmlReader.ReadFromStream(MS, [xrfIgnoreWhitespace], 64);
    while R.Read do if R.Token = xtText then Combined += AnsiString(R.Value);
    AssertTrue('Reader should not crash on too-large codepoint entity', Length(Combined) > 0);
  finally
    MS.Free;
  end;
end;

initialization
  RegisterTest(TTestCase_Reader_CharRefs_Malformed_SmallBuf);

end.

