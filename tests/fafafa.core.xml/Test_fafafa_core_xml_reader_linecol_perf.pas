{$CODEPAGE UTF8}
unit Test_fafafa_core_xml_reader_linecol_perf;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, DateUtils, fpcunit, testregistry,
  fafafa.core.xml;

type
  TTestCase_Reader_LineCol_Perf = class(TTestCase)
  published
    procedure Test_LineCol_Incremental_Does_Not_Regress;
  end;

implementation

function MakeManyLinesXml(NumLines: Integer): String;
var i: Integer; S: String;
begin
  S := '<r>' + LineEnding;
  for i := 1 to NumLines do
    S += '  text' + IntToStr(i) + LineEnding;
  S += '</r>';
  Result := S;
end;

procedure TTestCase_Reader_LineCol_Perf.Test_LineCol_Incremental_Does_Not_Regress;
var R: IXmlReader; S: String; startTick, endTick: QWord; L, C: SizeUInt; cnt: Integer;
begin
  S := MakeManyLinesXml(5000);
  R := CreateXmlReader.ReadFromString(S, [xrfIgnoreWhitespace, xrfCoalesceText]);
  startTick := GetTickCount64;
  cnt := 0;
  while R.Read do
  begin
    if R.Token = xtText then
    begin
      // 触发行列多次计算，不应显著退化
      L := R.Line; C := R.Column;
      Inc(cnt);
    end;
  end;
  endTick := GetTickCount64;
  AssertTrue('should parse many lines', cnt > 0);
  // 软性断言：时间在合理范围（本地环境依赖，设置宽松阈值）
  AssertTrue('line/column incremental should be reasonably fast', (endTick - startTick) < 2000);
end;

initialization
  if GetEnvironmentVariable('FAFAFA_TEST_SILENT_REG') <> '1' then
    Writeln('Registering TTestCase_Reader_LineCol_Perf');
  RegisterTest(TTestCase_Reader_LineCol_Perf);

end.

