{$CODEPAGE UTF8}
unit Test_fafafa_core_xml_perf_baseline;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, DateUtils, fpcunit, testregistry,
  fafafa.core.xml;

type
  TTestCase_Xml_Perf_Baseline = class(TTestCase)
  private
    function MakeNSMixXML(Count: Integer): String;
    function MakeEntityMixXML(Count: Integer): String;
    function MakeLongCDataXML(Blocks, BlockLen: Integer): String;
  published
    procedure Test_Read_Small_10k_Elements;
    procedure Test_Read_Mid_StringBuffer_Repeat;
    procedure Test_Read_Stream_SmallBuf_Repeat;
    procedure Test_Writer_Attrs_Perf_Baseline_NoFlags;
    procedure Test_Writer_Attrs_Perf_SortDedup;
  end;

implementation

function MakeSmallXML(Count: Integer): String;
var i: Integer;
begin
  Result := '<root>';
  for i := 1 to Count do
    Result += '<item id="' + IntToStr(i) + '" name="n'+IntToStr(i)+'"/>';
  Result += '</root>';
end;

function TTestCase_Xml_Perf_Baseline.MakeNSMixXML(Count: Integer): String;
var i: Integer; pref: String;
begin
  Result := '<r xmlns="urn:d" xmlns:p="urn:p" xmlns:q="urn:q">';
  for i := 1 to Count do
  begin
    if (i and 1)=0 then pref:='' else pref:='p:';
    Result += '<'+pref+'e a="v'+IntToStr(i)+'" '+pref+'b="n'+IntToStr(i)+'"/>';
  end;
  Result += '</r>';
end;

function TTestCase_Xml_Perf_Baseline.MakeEntityMixXML(Count: Integer): String;
var i: Integer;
begin
  Result := '<r>';
  for i := 1 to Count do
    Result += '<t>&amp;&lt;&gt;&quot; &apos; '+IntToStr(i)+' &#x41;&#x42;&#65;</t>';
  Result += '</r>';
end;

function TTestCase_Xml_Perf_Baseline.MakeLongCDataXML(Blocks, BlockLen: Integer): String;
var i,j: Integer; s: String;
begin
  SetLength(s, BlockLen);
  for j := 1 to BlockLen do s[j] := Char(Ord('a') + (j mod 26));
  Result := '<r>';
  for i := 1 to Blocks do
    Result += '<c><![CDATA['+s+']]></c>';
  Result += '</r>';
end;

procedure TTestCase_Xml_Perf_Baseline.Test_Read_Small_10k_Elements;
var R: IXmlReader; xml: String; startTick, el, nodes: Int64; tok: TXmlToken;
begin
  xml := MakeSmallXML(10000);
  R := CreateXmlReader.ReadFromString(xml);
  nodes := 0; startTick := GetTickCount64;
  while R.Read do begin tok := R.Token; Inc(nodes); end;
  el := GetTickCount64 - startTick;
  // 断言节点数量大于元素数（含 start/end/root 等），给出粗略阈值
  AssertTrue(nodes > 20000);
  // 输出耗时（不作严格阈值，避免环境差异导致波动）
  WriteLn('[PERF] Small10k Read ms=', el, ' nodes=', nodes);
end;

procedure TTestCase_Xml_Perf_Baseline.Test_Read_Mid_StringBuffer_Repeat;
var R: IXmlReader; xml: String; i: Integer; nodes: Int64;
begin
  xml := MakeSmallXML(2000);
  nodes := 0;
  for i := 1 to 10 do
  begin
    R := CreateXmlReader.ReadFromString(xml);
    while R.Read do Inc(nodes);
  end;
  // 简单打印节点数，确认无异常
  WriteLn('[PERF] MidRepeat nodes=', nodes);
  AssertTrue(nodes > 0);
end;

procedure TTestCase_Xml_Perf_Baseline.Test_Read_Stream_SmallBuf_Repeat;
var i: Integer; xml: String; msStart, ms: QWord; nodes: QWord; R: IXmlReader; SS: TStringStream;
begin
  xml := MakeSmallXML(3000);
  nodes := 0; msStart := GetTickCount64;
  for i := 1 to 5 do
  begin
    SS := TStringStream.Create(xml);
    try
      R := CreateXmlReader.ReadFromStream(SS);
      while R.Read do Inc(nodes);
    finally
      SS.Free;
    end;
  end;
  ms := GetTickCount64 - msStart;
  WriteLn('[PERF] StreamSmallBuf repeat ms=', ms, ' nodes=', nodes);
  AssertTrue(nodes > 0);
end;


procedure TTestCase_Xml_Perf_Baseline.Test_Writer_Attrs_Perf_Baseline_NoFlags;

procedure Test_Read_Stream_SmallBuf_NSMix;
var R: IXmlReader; xml: String; ms: QWord; nodes: QWord; SS: TStringStream;
begin
  xml := MakeNSMixXML(2000);
  SS := TStringStream.Create(xml);
  try
    ms := GetTickCount64;
    R := CreateXmlReader.ReadFromStream(SS);
    while R.Read do Inc(nodes);
    ms := GetTickCount64 - ms;
  finally
    SS.Free;
  end;
  WriteLn('[PERF] Stream NSMix ms=', ms, ' nodes=', nodes);
end;

procedure Test_Read_Stream_SmallBuf_EntityMix;
var R: IXmlReader; xml: String; ms: QWord; nodes: QWord; SS: TStringStream;
begin
  xml := MakeEntityMixXML(2000);
  SS := TStringStream.Create(xml);
  try
    ms := GetTickCount64;
    R := CreateXmlReader.ReadFromStream(SS);
    while R.Read do Inc(nodes);
    ms := GetTickCount64 - ms;
  finally
    SS.Free;
  end;
  WriteLn('[PERF] Stream EntityMix ms=', ms, ' nodes=', nodes);
end;

procedure Test_Read_Stream_SmallBuf_LongCData;
var R: IXmlReader; xml: String; ms: QWord; nodes: QWord; SS: TStringStream;
begin
  xml := MakeLongCDataXML(500, 256);
  SS := TStringStream.Create(xml);
  try
    ms := GetTickCount64;
    R := CreateXmlReader.ReadFromStream(SS);
    while R.Read do Inc(nodes);
    ms := GetTickCount64 - ms;
  finally
    SS.Free;
  end;
  WriteLn('[PERF] Stream LongCData ms=', ms, ' nodes=', nodes);
end;

var W: IXmlWriter; i: Integer; xml: String; start, ms: QWord; cnt: Integer;
begin
  // 构造单元素含大量属性（含重复键），不启用排序/去重
  W := CreateXmlWriter;
  W.StartElement('root');
  cnt := 0;
  for i := 1 to 500 do begin W.WriteAttribute('k'+IntToStr(i), IntToStr(i)); Inc(cnt); end;
  for i := 1 to 200 do begin W.WriteAttribute('dup', 'v'+IntToStr(i)); Inc(cnt); end;
  start := GetTickCount64;
  xml := W.WriteToString([]);
  ms := GetTickCount64 - start;
  AssertTrue(Length(xml) > 0);
  WriteLn('[PERF][Writer] attrs baseline noflags ms=', ms, ' attrs=', cnt);
end;

procedure TTestCase_Xml_Perf_Baseline.Test_Writer_Attrs_Perf_SortDedup;
var W: IXmlWriter; i: Integer; xml: String; start, ms: QWord; cnt: Integer;
begin
  // 同样输入，启用排序+去重（dup 应保留最后一个），观察 flush 开销
  W := CreateXmlWriter;
  W.StartElement('root');
  cnt := 0;
  for i := 1 to 500 do begin W.WriteAttribute('k'+IntToStr(i), IntToStr(i)); Inc(cnt); end;
  for i := 1 to 200 do begin W.WriteAttribute('dup', 'v'+IntToStr(i)); Inc(cnt); end;
  start := GetTickCount64;
  xml := W.WriteToString([xwfSortAttrs, xwfDedupAttrs]);
  ms := GetTickCount64 - start;
  AssertTrue(Pos(' dup="v200"', xml) > 0);
  WriteLn('[PERF][Writer] attrs sort+dedup ms=', ms, ' attrs=', cnt);
end;

initialization
  RegisterTest(TTestCase_Xml_Perf_Baseline);

end.



procedure TTestCase_Xml_Perf_Baseline.Test_Writer_Attrs_Perf_Baseline_NoFlags;
var W: IXmlWriter; i: Integer; xml: String; start, ms: QWord; cnt: Integer;
begin
  // 构造单元素含大量属性（含重复键），不启用排序/去重
  W := CreateXmlWriter;
  W.StartElement('root');
  cnt := 0;
  for i := 1 to 500 do begin W.WriteAttribute('k'+IntToStr(i), IntToStr(i)); Inc(cnt); end;
  for i := 1 to 200 do begin W.WriteAttribute('dup', 'v'+IntToStr(i)); Inc(cnt); end;
  start := GetTickCount64;
  xml := W.WriteToString([]);
  ms := GetTickCount64 - start;
  AssertTrue(Length(xml) > 0);
  WriteLn('[PERF][Writer] attrs baseline noflags ms=', ms, ' attrs=', cnt);
end;

procedure TTestCase_Xml_Perf_Baseline.Test_Writer_Attrs_Perf_SortDedup;
var W: IXmlWriter; i: Integer; xml: String; start, ms: QWord; cnt: Integer;
begin
  // 同样输入，启用排序+去重（dup 应保留最后一个），观察 flush 开销
  W := CreateXmlWriter;
  W.StartElement('root');
  cnt := 0;
  for i := 1 to 500 do begin W.WriteAttribute('k'+IntToStr(i), IntToStr(i)); Inc(cnt); end;
  for i := 1 to 200 do begin W.WriteAttribute('dup', 'v'+IntToStr(i)); Inc(cnt); end;
  start := GetTickCount64;
  xml := W.WriteToString([xwfSortAttrs, xwfDedupAttrs]);
  ms := GetTickCount64 - start;
  AssertTrue(Pos(' dup="v200"', xml) > 0);
  WriteLn('[PERF][Writer] attrs sort+dedup ms=', ms, ' attrs=', cnt);
end;
