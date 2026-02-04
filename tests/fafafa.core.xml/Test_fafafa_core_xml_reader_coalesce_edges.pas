unit Test_fafafa_core_xml_reader_coalesce_edges;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, fpcunit, testregistry,
  fafafa.core.xml;

type
  TTestCase_Reader_Coalesce_Edges = class(TTestCase)
  published
    procedure Test_Stream_Alternate_Text_CDATA_Text_AllMerged;
    procedure Test_Stream_Alternate_CrossChunk_AllMerged;
    procedure Test_Stream_BreakBy_Comment_PI_NotMerged;
  end;

implementation

procedure TTestCase_Reader_Coalesce_Edges.Test_Stream_Alternate_Text_CDATA_Text_AllMerged;
var R: IXmlReader; MS: TMemoryStream; Vals: array of String; i: Integer;
    Data: AnsiString;
begin
  MS := TMemoryStream.Create;
  try
    // 交替：Text CDATA Text CDATA Text
    // 期待合并为单个 xtText
    Data := '<r>t1<![CDATA[c2]]>t3<![CDATA[c4]]>t5</r>';
    MS.WriteBuffer(PAnsiChar(Data)^, Length(Data));
    MS.Position := 0;
    R := CreateXmlReader.ReadFromStream(MS, [xrfCoalesceText]);
    SetLength(Vals, 0);
    while R.Read do
      if R.Token = xtText then
      begin
        i := Length(Vals); SetLength(Vals, i+1); Vals[i] := R.Value;
      end;
    AssertEquals('one text after full coalesce', 1, Length(Vals));
    AssertEquals('t1c2t3c4t5', Vals[0]);
  finally
    MS.Free;
  end;
end;

procedure TTestCase_Reader_Coalesce_Edges.Test_Stream_Alternate_CrossChunk_AllMerged;
var R: IXmlReader; MS: TMemoryStream; Vals: array of String; i: Integer; S: String;
begin
  // 构造跨块交替：小缓冲触发 Text/CDATA 切换出现在块边界
  S := '<r>' + StringOfChar('A', 100) + '<![CDATA[' + StringOfChar('B', 100) + ']]>' + StringOfChar('C', 100) + '</r>';
  MS := TMemoryStream.Create;
  try
    if Length(S)>0 then MS.WriteBuffer(S[1], Length(S));
    MS.Position := 0;
    R := CreateXmlReader.ReadFromStream(MS, [xrfCoalesceText], 64);
    SetLength(Vals, 0);
    while R.Read do
      if R.Token = xtText then begin i := Length(Vals); SetLength(Vals, i+1); Vals[i] := R.Value; end;
    AssertEquals('one text after full coalesce cross-chunk', 1, Length(Vals));
    AssertEquals(StringOfChar('A',100)+StringOfChar('B',100)+StringOfChar('C',100), Vals[0]);
  finally
    MS.Free;
  end;
end;

procedure TTestCase_Reader_Coalesce_Edges.Test_Stream_BreakBy_Comment_PI_NotMerged;
var R: IXmlReader; MS: TMemoryStream; Vals: array of String; i: Integer;
    Data: AnsiString;
begin
  // 有 Comment 与 PI 介入：应打断合并，得到两个文本 token
  MS := TMemoryStream.Create;
  try
    Data := '<r>a<!--c--><?pi x?>b</r>';
    MS.WriteBuffer(PAnsiChar(Data)^, Length(Data));
    MS.Position := 0;
    R := CreateXmlReader.ReadFromStream(MS, [xrfCoalesceText]);
    SetLength(Vals, 0);
    while R.Read do
      if R.Token = xtText then begin i := Length(Vals); SetLength(Vals, i+1); Vals[i] := R.Value; end;
    AssertEquals('two text tokens due to break by Comment/PI', 2, Length(Vals));
    AssertEquals('a', Vals[0]);
    AssertEquals('b', Vals[1]);
  finally
    MS.Free;
  end;
end;

initialization
  if GetEnvironmentVariable('FAFAFA_TEST_SILENT_REG') <> '1' then
    RegisterTest('fafafa.core.xml', TTestCase_Reader_Coalesce_Edges);

end.
