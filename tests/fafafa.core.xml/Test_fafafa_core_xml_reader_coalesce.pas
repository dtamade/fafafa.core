unit Test_fafafa_core_xml_reader_coalesce;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, fpcunit, testregistry,
  fafafa.core.xml;

// 测试 xrfCoalesceText 对字符串与流式两种模式的行为

type
  TTestCase_Reader_Coalesce = class(TTestCase)
  published
    procedure Test_String_Text_CDATA_Text_Merged;
    procedure Test_Stream_Text_CDATA_Text_Merged_All;
  end;

implementation

procedure TTestCase_Reader_Coalesce.Test_String_Text_CDATA_Text_Merged;
var R: IXmlReader; S: String; Toks: array of TXmlToken; Vals: array of String; i: Integer;
begin
  S := '<root>aa<![CDATA[bb]]>cc</root>';
  R := CreateXmlReader.ReadFromString(S, [xrfCoalesceText]);
  SetLength(Toks, 0); SetLength(Vals, 0);
  while R.Read do
  begin
    if R.Token = xtText then
    begin
      i := Length(Toks); SetLength(Toks, i+1); Toks[i] := R.Token;
      SetLength(Vals, i+1); Vals[i] := R.Value;
    end;
  end;
  // 期望只有一个合并后的 xtText，内容为 aabbcc
  AssertEquals('one merged text', 1, Length(Toks));
  AssertEquals('aabbcc', Vals[0]);
end;

procedure TTestCase_Reader_Coalesce.Test_Stream_Text_CDATA_Text_Merged_All;
var R: IXmlReader; Ms: TMemoryStream; i: Integer; Toks: array of TXmlToken; Vals: array of String;
begin
  Ms := TMemoryStream.Create;
  try
    Ms.WriteBuffer(Pointer('<root>aa<![CDATA[')^, Length('<root>aa<![CDATA['));
    Ms.WriteBuffer(Pointer('bb')^, Length('bb'));
    Ms.WriteBuffer(Pointer(']]>cc</root>')^, Length(']]>cc</root>'));
    Ms.Position := 0;
    R := CreateXmlReader.ReadFromStream(Ms, [xrfCoalesceText]);
    SetLength(Toks, 0); SetLength(Vals, 0);
    while R.Read do
    begin
      if R.Token = xtText then
      begin
        i := Length(Toks); SetLength(Toks, i+1); Toks[i] := R.Token;
        SetLength(Vals, i+1); Vals[i] := R.Value;
      end;
    end;
    // 完全连续合并：期望一个文本 token（aabbcc）
    AssertEquals('one merged text', 1, Length(Toks));
    AssertEquals('aabbcc', Vals[0]);
  finally
    Ms.Free;
  end;
end;

initialization
  if GetEnvironmentVariable('FAFAFA_TEST_SILENT_REG') <> '1' then
    RegisterTest('fafafa.core.xml', TTestCase_Reader_Coalesce);

end.

