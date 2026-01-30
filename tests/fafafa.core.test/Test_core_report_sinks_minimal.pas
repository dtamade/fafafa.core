unit Test_core_report_sinks_minimal;

{$mode objfpc}{$H+}
{$modeswitch anonymousfunctions}

interface

uses
  SysUtils, Classes, fpcunit, testregistry,
  fafafa.core.test.json.intf, fafafa.core.test.json.rtl,
  fafafa.core.test.utils,
  fafafa.core.report.common,
  fafafa.core.report.sink.intf,
  fafafa.core.report.sink.json;

type
  TTestCase_CoreTest_Sinks_Minimal = class(TTestCase)
  published
    procedure Test_JSON_Sink_Writes_UTC_Z_And_Cleanup;
  end;

procedure RegisterTests;

implementation

procedure TTestCase_CoreTest_Sinks_Minimal.Test_JSON_Sink_Writes_UTC_Z_And_Cleanup;
var sink: IReportSink; outDir, outFile: string; sl: TStringList; s: string;
begin
  outDir := CreateTempDir('coretest_sink_');
  outFile := IncludeTrailingPathDelimiter(outDir) + 'sink.json';
  sink := TReportJsonSink.Create(@CreateRtlJsonWriter, outFile);
  sink.SuiteStart(1);
  sink.CaseStart('t/a');
  sink.CaseFailure('t/a', 'boom'+LineEnding+'[cleanup]'+LineEnding+'E1: c1'+LineEnding+'E2: c2', 1);
  sink.SuiteEnd(1, 1, 1);
  sl := TStringList.Create;
  try
    sl.LoadFromFile(outFile);
    s := sl.Text;
    AssertTrue('should have timestamp', Pos('"timestamp"', s) > 0);
    AssertTrue('should be UTC Z', Pos('Z"', s) > 0); // UTC Zulu
    AssertTrue('should contain cleanup', Pos('cleanup', s) > 0);
    AssertTrue('cleanup should contain first entry', Pos('E1: c1', s) > 0);
    AssertTrue('cleanup should contain second entry', Pos('E2: c2', s) > 0);
  finally
    sl.Free;
    DeleteFile(outFile);
    RemoveDir(outDir);
  end;
end;

procedure RegisterTests;
begin
  RegisterTest(TTestCase_CoreTest_Sinks_Minimal);
end;

end.

