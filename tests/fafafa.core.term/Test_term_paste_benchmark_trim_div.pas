{$CODEPAGE UTF8}
unit Test_term_paste_benchmark_trim_div;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, dateutils,
  fafafa.core.term;

type
  TTestCase_PasteBenchmarkTrimDiv = class(TTestCase)
  published
    procedure Benchmark_TrimFastPath_Effect;
  end;

implementation

procedure FillRandomData(Count: SizeInt);
var i: SizeInt; s: string; len: SizeInt;
begin
  term_paste_clear_all;
  Randomize;
  for i := 1 to Count do
  begin
    len := 1 + Random(8);
    SetLength(s, len);
    FillChar(Pointer(s)^, len, Ord('A') + (i mod 26));
    term_paste_store_text(s);
  end;
end;

procedure TTestCase_PasteBenchmarkTrimDiv.Benchmark_TrimFastPath_Effect;
var
  t0, t1: QWord;
  dur_no_fast, dur_fast: QWord;
  i: Integer;
begin
  // 准备数据：5000 条
  FillRandomData(5000);
  term_paste_set_trim_fastpath_div(High(SizeUInt)); // 基本关闭快速路径
  t0 := GetTickCount64;
  for i := 1 to 200 do
    term_paste_trim_keep_last(1000);
  t1 := GetTickCount64;
  dur_no_fast := t1 - t0;

  // 重新准备数据并启用快速路径（分母变小：越容易触发）
  FillRandomData(5000);
  term_paste_set_trim_fastpath_div(4);
  t0 := GetTickCount64;
  for i := 1 to 200 do
    term_paste_trim_keep_last(1000);
  t1 := GetTickCount64;
  dur_fast := t1 - t0;

  // 打印结果（不作严格断言，避免 CI 抖动干扰）
  writeln(Format('[benchmark] trim_keep_last: no_fast=%d ms, fast=%d ms',[dur_no_fast, dur_fast]));
end;

initialization
  RegisterTest(TTestCase_PasteBenchmarkTrimDiv);

end.

