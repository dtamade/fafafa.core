{$CODEPAGE UTF8}
unit Test_fafafa_core_xml_reader_charrefs_named_mix_smallbuf;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, fpcunit, testregistry,
  fafafa.core.xml;

implementation

type
  TTestCase_Reader_CharRefs_NamedMix_SmallBuf = class(TTestCase)
  published
    procedure Test_Text_CharRef_NamedNumeric_Mix_CrossChunk_SmallBuf;
    procedure Test_Text_CharRef_NamedNumeric_All_CrossChunk_SmallBuf;
  end;

procedure TTestCase_Reader_CharRefs_NamedMix_SmallBuf.Test_Text_CharRef_NamedNumeric_Mix_CrossChunk_SmallBuf;
var
  S: AnsiString; MS: TMemoryStream; R: IXmlReader; Tok: TXmlToken;
  Combined: AnsiString = '';
  i, CntAmp, CntLt: SizeInt;
begin
  // 混合 &amp; &#38; &lt; &#60; 跨块，确保两种写法均解码为相同字符
  S := '<?xml version="1.0"?><root>'
     + StringOfChar('x', 1000)
     + '&amp;&#38;&lt;&#60;'
     + StringOfChar('y', 1000)
     + '</root>';
  MS := TMemoryStream.Create;
  try
    if Length(S) > 0 then MS.WriteBuffer(S[1], Length(S));
    MS.Position := 0;
    R := CreateXmlReader.ReadFromStream(MS, [xrfIgnoreWhitespace], 64);
    while R.Read do if R.Token = xtText then Combined += AnsiString(R.Value);

    AssertTrue('Combined text should be non-empty', Length(Combined) > 0);

    // 统计 '&' 与 '<' 出现次数，应至少各 2 次（&amp;、&#38; -> '&'；&lt;、&#60; -> '<'）
    CntAmp := 0; CntLt := 0;
    for i := 1 to Length(Combined) do
    begin
      if Combined[i] = '&' then Inc(CntAmp)
      else if Combined[i] = '<' then Inc(CntLt);
    end;
    AssertTrue('At least two ampersands expected (from &amp; and &#38;)', CntAmp >= 2);
    AssertTrue('At least two less-than signs expected (from &lt; and &#60;)', CntLt >= 2);

    // 序列完整性：应包含 "&&<<" 连续片段
    AssertTrue('Sequence &&<< should appear', Pos('&&<<', Combined) > 0);
  finally
    MS.Free;
  end;
end;

procedure TTestCase_Reader_CharRefs_NamedMix_SmallBuf.Test_Text_CharRef_NamedNumeric_All_CrossChunk_SmallBuf;
var
  S: AnsiString; MS: TMemoryStream; R: IXmlReader; Tok: TXmlToken;
  Combined: AnsiString = '';
  i, CntGt, CntQuot, CntApos: SizeInt;
begin
  // 覆盖 > ", ' 的命名与数字实体混合：&gt;&#62;&quot;&#34;&apos;&#39; 跨块
  S := '<?xml version="1.0"?><root>'
     + StringOfChar('x', 1000)
     + '&gt;&#62;&quot;&#34;&apos;&#39;'
     + StringOfChar('y', 1000)
     + '</root>';
  MS := TMemoryStream.Create;
  try
    if Length(S) > 0 then MS.WriteBuffer(S[1], Length(S));
    MS.Position := 0;
    R := CreateXmlReader.ReadFromStream(MS, [xrfIgnoreWhitespace], 64);
    while R.Read do if R.Token = xtText then Combined += AnsiString(R.Value);

    AssertTrue('Combined text should be non-empty', Length(Combined) > 0);

    CntGt := 0; CntQuot := 0; CntApos := 0;
    for i := 1 to Length(Combined) do
    begin
      if Combined[i] = '>' then Inc(CntGt)
      else if Combined[i] = '"' then Inc(CntQuot)
      else if Combined[i] = '''' then Inc(CntApos);
    end;
    AssertTrue('At least two greater-than signs expected (from &gt; and &#62;)', CntGt >= 2);
    AssertTrue('At least two double quotes expected (from &quot; and &#34;)', CntQuot >= 2);
    AssertTrue('At least two single quotes expected (from &apos; and &#39;)', CntApos >= 2);

    AssertTrue('Sequence ">""'' should appear (>, ", ")', Pos('>""''', Combined) > 0);
  finally
    MS.Free;
  end;
end;

initialization
  RegisterTest(TTestCase_Reader_CharRefs_NamedMix_SmallBuf);

end.

