unit test_junit_edge_cases;

{$MODE OBJFPC}{$H+}

interface

uses
  SysUtils, Classes, fpcunit, testregistry,
  fafafa.core.benchmark;

procedure DummyBenchProc(aState: IBenchmarkState);

type
  TTestJUnitEdgeCases = class(TTestCase)
  published
    procedure Test_JUnitReporter_NameEdgeCases_Parseable;
    procedure Test_JUnitReporter_ResultsParseable_WithUnicode;
  end;

implementation

uses
  fafafa.core.base;

procedure DummyBenchProc(aState: IBenchmarkState);
begin
  while aState.KeepRunning do ;
end;

procedure TTestJUnitEdgeCases.Test_JUnitReporter_NameEdgeCases_Parseable;
var
  Rep: IBenchmarkReporter;
  R: IBenchmarkResult;
  LTmp, XML: string;
  SL: TStringList;
  NameStr: string;
begin
  LTmp := IncludeTrailingPathDelimiter(GetTempDir) + 'reporter_junit_edge_names.xml';
  if FileExists(LTmp) then SysUtils.DeleteFile(LTmp);

  NameStr := 'edge<>&"'''+#9+#10+#13+'😀中μ';
  R := Bench(NameStr, @DummyBenchProc);

  Rep := CreateJUnitReporter(LTmp);
  Rep.ReportResult(R);

  AssertTrue('JUnit file not generated', FileExists(LTmp));

  // naive parse: ensure tags present and name attribute escaped
  SL := TStringList.Create;
  try
    SL.LoadFromFile(LTmp);
    XML := SL.Text;
    AssertTrue(Pos('<testsuite', XML) > 0);
    AssertTrue(Pos('<testcase ', XML) > 0);
    // name must be escaped; raw '<' should not appear inside attribute
    AssertTrue(Pos('name="', XML) > 0);
    AssertTrue(Pos('&lt;', XML) > 0);
    AssertTrue(Pos('&gt;', XML) > 0);
    AssertTrue(Pos('&amp;', XML) > 0);
  finally
    SL.Free;
  end;
end;

procedure TTestJUnitEdgeCases.Test_JUnitReporter_ResultsParseable_WithUnicode;
var
  Rep: IBenchmarkReporter;
  R1, R2: IBenchmarkResult;
  LTmp, XML: string;
  SL: TStringList;
begin
  LTmp := IncludeTrailingPathDelimiter(GetTempDir) + 'reporter_junit_edge_results.xml';
  if FileExists(LTmp) then SysUtils.DeleteFile(LTmp);

  R1 := Bench('αβγ', @DummyBenchProc);
  R2 := Bench('测试😀', @DummyBenchProc);

  Rep := CreateJUnitReporter(LTmp);
  Rep.ReportResults([R1, R2]);

  AssertTrue('JUnit file not generated', FileExists(LTmp));

  SL := TStringList.Create;
  try
    SL.LoadFromFile(LTmp);
    XML := SL.Text;
    AssertTrue(Pos('<testsuite', XML) > 0);
    AssertTrue(Pos('<testcase ', XML) > 0);
    AssertTrue(Pos('name="αβγ"', XML) > 0);
    AssertTrue(Pos('name="测试😀"', XML) > 0);
  finally
    SL.Free;
  end;
end;

initialization
  RegisterTest(TTestJUnitEdgeCases);
end.

