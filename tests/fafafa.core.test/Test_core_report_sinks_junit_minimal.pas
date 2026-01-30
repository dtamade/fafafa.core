unit Test_core_report_sinks_junit_minimal;

{$mode objfpc}{$H+}
{$modeswitch anonymousfunctions}

interface

uses
  SysUtils, Classes, fpcunit, testregistry,
  fafafa.core.test.utils,
  fafafa.core.report.sink.intf,
  fafafa.core.report.sink.junit;

type
  TTestCase_CoreTest_Sinks_JUnit_Minimal = class(TTestCase)
  published
    procedure Test_JUnit_Sink_Escapes_And_Cleanup_CDATA;
  end;

procedure RegisterTests;

implementation

procedure TTestCase_CoreTest_Sinks_JUnit_Minimal.Test_JUnit_Sink_Escapes_And_Cleanup_CDATA;
var sink: IReportSink; outDir, outFile: string; sl: TStringList; s: string;
begin
  outDir := CreateTempDir('coretest_junit_sink_');
  outFile := IncludeTrailingPathDelimiter(outDir) + 'sink.xml';
  sink := TReportJUnitSink.Create(outFile);
  sink.SuiteStart(1);
  sink.CaseStart('suite/test');
  sink.CaseFailure('suite/test', 'boom & <bad>"quote"'+LineEnding+'[cleanup]'+LineEnding+'E1: c1'+LineEnding+'E2: c2', 2);
  sink.SuiteEnd(1, 1, 2);
  sl := TStringList.Create;
  try
    sl.LoadFromFile(outFile);
    s := sl.Text;
    // UTC Z timestamp present on testsuite
    AssertTrue('timestamp should be present', Pos('timestamp="', s) > 0);
    AssertTrue('timestamp should be UTC Z', Pos('Z"', s) > 0);
    // message XML escaping in attribute
    AssertTrue('message should escape &', Pos('message="boom &amp; ', s) > 0);
    AssertTrue('message should escape < > and quotes', (Pos('&lt;bad&gt;&quot;quote&quot;', s) > 0));
    // cleanup details inside CDATA
    AssertTrue('should contain system-err CDATA start', Pos('<system-err><![CDATA[', s) > 0);
    AssertTrue('should contain cleanup header', Pos('cleanup (2):', s) > 0);
    AssertTrue('should contain numbered cleanup item 1', Pos('  1) E1: c1', s) > 0);
    AssertTrue('should contain numbered cleanup item 2', Pos('  2) E2: c2', s) > 0);
  finally
    sl.Free;
    DeleteFile(outFile);
    RemoveDir(outDir);
  end;
end;

procedure RegisterTests;
begin
  RegisterTest(TTestCase_CoreTest_Sinks_JUnit_Minimal);
end;

end.

