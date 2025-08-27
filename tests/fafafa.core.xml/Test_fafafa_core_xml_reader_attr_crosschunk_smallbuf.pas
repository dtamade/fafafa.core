{$CODEPAGE UTF8}
unit Test_fafafa_core_xml_reader_attr_crosschunk_smallbuf;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, fpcunit, testregistry,
  fafafa.core.xml;

implementation

type
  TTestCase_Reader_Attr_CrossChunk_SmallBuf = class(TTestCase)
  published
    procedure Test_Attr_Name_And_Value_CrossChunk_SelfClosing;
  end;

// 目标：在极小缓冲下让属性名跨块、属性值跨块，并以 '/>' 结束，验证 parser 稳定性
procedure TTestCase_Reader_Attr_CrossChunk_SmallBuf.Test_Attr_Name_And_Value_CrossChunk_SelfClosing;
var
  S: AnsiString; MS: TMemoryStream; R: IXmlReader;
  V: String; Seen: Boolean = False;
begin
  // 通过构造长的前缀文本，控制边界，使属性名与值都跨块；注意使用空格更容易穿过 ParseAttributes 的空白跳过逻辑
  // - name: 'attr' 由两侧填充让其落在块边界
  // - value: 由大段字符 + 实体 + 大段字符组成，跨越多个块
  S := '<?xml version="1.0"?><root>' +
       '<e ' +
       StringOfChar(' ', 60) + // 使用空格推动到边界（缓冲=64，这里留出 " attr=" 起始位置）
       'attr="' + StringOfChar('A', 1000) + '&amp;' + StringOfChar('B', 1000) + '"/>' +
       '</root>';
  MS := TMemoryStream.Create;
  try
    if Length(S) > 0 then MS.WriteBuffer(S[1], Length(S));
    MS.Position := 0;
    R := CreateXmlReader.ReadFromStream(MS, [xrfIgnoreWhitespace], 64);
    while R.Read do
      if (R.Token = xtStartElement) and (R.LocalName='e') then
      begin
        if R.TryGetAttribute('attr', V) then
        begin
          Seen := True;
          AssertTrue('Attr should contain decoded &', Pos('&', V) > 0);
          // 校验两侧大段文本是否保留
          AssertTrue('Value should contain many As', Pos(StringOfChar('A', 100), V) > 0);
          AssertTrue('Value should contain many Bs', Pos(StringOfChar('B', 100), V) > 0);
        end;
      end;
    AssertTrue('Should see element with attribute', Seen);
  finally
    MS.Free;
  end;
end;

initialization
  RegisterTest(TTestCase_Reader_Attr_CrossChunk_SmallBuf);

end.

