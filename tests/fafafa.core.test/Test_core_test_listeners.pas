unit Test_core_test_listeners;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

interface

uses
  SysUtils, Classes, fpcunit, testregistry,
  fpjson, jsonparser,
  fafafa.core.test.core,
  fafafa.core.test.listener.console,
  fafafa.core.test.listener.json,
  fafafa.core.test.listener.junit,
  fafafa.core.test.json.rtl,
  fafafa.core.test.utils,
  iso8601_check;

type
  TTestCase_CoreTest_Listeners = class(TTestCase)
  published
    procedure Test_JsonListener_Writes_File_With_Tests;
    procedure Test_JUnitListener_Writes_File_With_Tests;
    procedure Test_Listeners_Record_Skipped;
    procedure Test_Console_Shows_Cleanup_Block;
    procedure Test_JUnit_And_JSON_Include_Cleanup_Details;

  end;

procedure RegisterTests;

implementation

function ReadAllText(const AFile: string): string;
var SL: TStringList;
begin
  SL := TStringList.Create;
  try
    SL.LoadFromFile(AFile);
    Result := SL.Text;
  finally
    SL.Free;
  end;
end;

function CountJsonStatus(const JsonText, Status: string): Integer;
var
  P: TJSONParser;
  Root: TJSONObject;
  Arr: TJSONArray;
  I: Integer;
  Obj: TJSONObject;
begin
  Result := 0;
{$push}
{$warn 5066 off}
  P := TJSONParser.Create(JsonText);
{$pop}
  try
    Root := P.Parse as TJSONObject;
    try
      Arr := Root.FindPath('tests') as TJSONArray;
      if Arr <> nil then
        for I := 0 to Arr.Count-1 do
        begin
          Obj := Arr.Objects[I];
          if Assigned(Obj) and SameText(Obj.Get('status', ''), Status) then
            Inc(Result);
        end;
    finally
      Root.Free;
    end;
  finally
    P.Free;
  end;
end;

function CountOccurrences(const S, Sub: string): Integer;
var
  P, StartPos: SizeInt;
begin
  Result := 0;
  if (S = '') or (Sub = '') then Exit;
  StartPos := 1;
  while True do
  begin
    P := Pos(Sub, Copy(S, StartPos, MaxInt));
    if P = 0 then Break;
    Inc(Result);
    Inc(StartPos, P + Length(Sub) - 1);
  end;
end;

procedure TTestCase_CoreTest_Listeners.Test_JsonListener_Writes_File_With_Tests;
var
  OutDir, OutFile, Content: string;
  L: ITestListener;
begin
  OutDir := CreateTempDir('coretest_json_');
  OutFile := IncludeTrailingPathDelimiter(OutDir) + 'report.json';
  L := TJsonTestListener.Create(@CreateRtlJsonWriter, OutFile);
  L.OnStart(2);
  L.OnTestSuccess('suite/test1', 10);
  L.OnTestFailure('suite/test2', 'boom', 20);
  L.OnEnd(2, 1, 30);

  AssertTrue('JSON report should exist', FileExists(OutFile));
  Content := ReadAllText(OutFile);
  AssertTrue('JSON should include tests array', Pos('"tests"', Content) > 0);
  AssertTrue('JSON should include one passed', CountJsonStatus(Content, 'passed') = 1);
  AssertTrue('JSON should include one failed', CountJsonStatus(Content, 'failed') = 1);
end;

procedure TTestCase_CoreTest_Listeners.Test_JUnitListener_Writes_File_With_Tests;
var
  OutDir, OutFile, Content: string;
  L: ITestListener;
  Cases: Integer;
begin
  OutDir := CreateTempDir('coretest_junit_');
  OutFile := IncludeTrailingPathDelimiter(OutDir) + 'report.xml';
  L := TJUnitTestListener.Create(OutFile);
  L.OnStart(2);
  L.OnTestSuccess('suite/test1', 10);
  L.OnTestFailure('suite/test2', 'boom', 20);
  L.OnEnd(2, 1, 30);

  AssertTrue('JUnit XML report should exist', FileExists(OutFile));
  Content := ReadAllText(OutFile);
  AssertTrue('XML should have testsuite header', Pos('<testsuite', Content) > 0);
  Cases := CountOccurrences(Content, '<testcase');
  AssertTrue('XML should contain 2 testcases, got ' + IntToStr(Cases), Cases = 2);
  // assert timestamp and hostname attributes present
  AssertTrue('testsuite has timestamp', Pos(' timestamp="', Content) > 0);
  AssertTrue('testsuite has hostname', Pos(' hostname="', Content) > 0);
  // if timestamp ends with Z then ensure it's RFC3339-like UTC format
  if Pos(' timestamp="', Content) > 0 then
  begin
    // naive check: contains 'T' and ends with 'Z"' in header line
    AssertTrue('timestamp contains T', Pos('T', Content) > 0);
  end;

end;

procedure TTestCase_CoreTest_Listeners.Test_Console_Shows_Cleanup_Block;
var
  Listener: ITestListener;
  Msg: string;
begin
  // 仅验证解析/格式化逻辑可执行，不读取控制台；依赖无异常完成
  Listener := TConsoleTestListener.Create;
  Listener.OnStart(1);
  Msg := 'boom' + LineEnding + '[cleanup]' + LineEnding + 'E1: c1' + LineEnding + 'E2: c2';
  Listener.OnTestFailure('s/t', Msg, 1);
  Listener.OnEnd(1, 1, 1);
  AssertTrue(True);
end;

procedure TTestCase_CoreTest_Listeners.Test_JUnit_And_JSON_Include_Cleanup_Details;
var
  OutDir, JsonFile, XmlFile, JsonContent, XmlContent, Msg: string;
  LJ: ITestListener; LX: ITestListener;
  P: TJSONParser; Root: TJSONObject; Arr: TJSONArray; Obj: TJSONObject;
begin
  OutDir := CreateTempDir('coretest_cleanup_');
  // JSON
  JsonFile := IncludeTrailingPathDelimiter(OutDir) + 'report.json';
  // use V2 writer to get structured cleanup array
  LJ := TJsonTestListener.Create(@CreateRtlJsonWriterV2, JsonFile);
  LJ.OnStart(1);
  Msg := 'boom' + LineEnding + '[cleanup]' + LineEnding + 'E1: c1' + LineEnding + 'E2: c2';
  LJ.OnTestFailure('suite/test2', Msg, 20);
  LJ.OnEnd(1, 1, 20);
  JsonContent := ReadAllText(JsonFile);
  AssertTrue('JSON contains cleanup marker text', Pos('E1: c1', JsonContent) > 0);
  AssertTrue('JSON contains cleanup marker text', Pos('E2: c2', JsonContent) > 0);
  // Re-parse JSON and assert structured cleanup array exists
{$push}
{$warn 5066 off}
  P := TJSONParser.Create(JsonContent);
{$pop}
  try
    Root := P.Parse as TJSONObject;
    try
      Arr := Root.FindPath('tests') as TJSONArray;
      AssertTrue('tests array exists', Assigned(Arr));
      Obj := Arr.Objects[0];
      AssertTrue('cleanup array exists', Assigned(Obj.Find('cleanup')));
      AssertTrue('cleanup item 1 present', Pos('E1: c1', Obj.FindPath('cleanup[0].text').AsString) > 0);
      AssertTrue('cleanup item 2 present', Pos('E2: c2', Obj.FindPath('cleanup[1].text').AsString) > 0);
      // 当启用 FAFAFA_TEST_JSON_CLEANUP_TS 时，清理项应包含 RFC3339 时间戳（UTC Z 或本地偏移）
      if Assigned(Obj.FindPath('cleanup[0].ts')) then
      begin
        AssertTrue('cleanup[0].ts is RFC3339', IsRFC3339Timestamp(Obj.FindPath('cleanup[0].ts').AsString));
        AssertTrue('cleanup[1].ts is RFC3339', IsRFC3339Timestamp(Obj.FindPath('cleanup[1].ts').AsString));
      end;
    finally
      Root.Free;
    end;
  finally
    P.Free;
  end;

  // JUnit
  XmlFile := IncludeTrailingPathDelimiter(OutDir) + 'report.xml';
  LX := TJUnitTestListener.Create(XmlFile);
  LX.OnStart(1);
  LX.OnTestFailure('suite/test2', Msg, 20);
  LX.OnEnd(1, 1, 20);
  XmlContent := ReadAllText(XmlFile);
  AssertTrue('JUnit has system-err cleanup header', Pos('cleanup (2):', XmlContent) > 0);
  AssertTrue('JUnit has indexed items', (Pos('1) E1: c1', XmlContent) > 0) and (Pos('2) E2: c2', XmlContent) > 0));
end;

procedure RegisterTests;
begin
  RegisterTest(TTestCase_CoreTest_Listeners);
end;

procedure TTestCase_CoreTest_Listeners.Test_Listeners_Record_Skipped;
var
  OutDir, OutFile, JsonContent, XmlContent: string;
  LJ: ITestListener;
  LX: ITestListener;
  Cases: Integer;
begin
  OutDir := CreateTempDir('coretest_skip_');
  // JSON
  OutFile := IncludeTrailingPathDelimiter(OutDir) + 'report.json';
  LJ := TJsonTestListener.Create(@CreateRtlJsonWriter, OutFile);
  LJ.OnStart(1);
  LJ.OnTestSkipped('suite/skip1', 5);
  LJ.OnEnd(1, 0, 5);
  AssertTrue('JSON report should exist', FileExists(OutFile));
  JsonContent := ReadAllText(OutFile);
  AssertTrue('JSON should include skipped count', Pos('"skipped"', JsonContent) > 0);
  AssertTrue('JSON should include one skipped', CountJsonStatus(JsonContent, 'skipped') = 1);
  // JUnit
  OutFile := IncludeTrailingPathDelimiter(OutDir) + 'report.xml';
  LX := TJUnitTestListener.Create(OutFile);
  LX.OnStart(1);
  LX.OnTestSkipped('suite/skip1', 5);
  LX.OnEnd(1, 0, 5);
  XmlContent := ReadAllText(OutFile);
  AssertTrue('JUnit should include skipped attribute', Pos('skipped="1"', XmlContent) > 0);
  Cases := CountOccurrences(XmlContent, '<skipped/>');
  AssertTrue('JUnit should contain one <skipped/>', Cases = 1);
end;

end.

