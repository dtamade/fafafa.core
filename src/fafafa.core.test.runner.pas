unit fafafa.core.test.runner;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

// Minimal runner facade that reuses FPCUnit's consoletestrunner
// Later we can auto-detect TestInsight and switch accordingly.

procedure TestMain;

implementation

uses
  SysUtils, Classes, fpjson,
  fafafa.core.test.core,
  fafafa.core.test.listener.console,
  fafafa.core.test.listener.junit,
  fafafa.core.test.listener.json,
  fafafa.core.test.json.rtl,
  fafafa.core.test.cli,
  // optional sink-based console/json/junit output
  fafafa.core.report.sink.console,
  fafafa.core.report.sink.json,
  fafafa.core.report.sink.junit,
  fafafa.core.test.listener.sinkadapter;

  type
    TRunnerMetrics = class(TInterfacedObject, ITestListener)
    private
      type TRec = record Name: string; Elapsed: QWord; end;
    private
      FSkipped: Integer;
      FRecs: array of TRec;
      procedure AddRec(const AName: string; const AElapsed: QWord);
    public
      // ITestListener
      procedure OnStart(ATotal: Integer);
      procedure OnTestStart(const AName: string);
      procedure OnTestSuccess(const AName: string; AElapsedMs: QWord);
      procedure OnTestFailure(const AName, AMessage: string; AElapsedMs: QWord);
      procedure OnTestSkipped(const AName: string; AElapsedMs: QWord);
      procedure OnEnd(ATotal, AFailed: Integer; AElapsedMs: QWord);
      // Accessors
      function GetSkipped: Integer;
      procedure GetTopSlowest(N: Integer; var Names: array of string; var Times: array of QWord);
    end;

  procedure TRunnerMetrics.AddRec(const AName: string; const AElapsed: QWord);
  var L: Integer;
  begin
    L := Length(FRecs);
    SetLength(FRecs, L+1);
    FRecs[L].Name := AName;
    FRecs[L].Elapsed := AElapsed;
  end;

  procedure TRunnerMetrics.OnStart(ATotal: Integer);
  begin
    FSkipped := 0;
    SetLength(FRecs, 0);
  end;

  procedure TRunnerMetrics.OnTestStart(const AName: string);
  begin
  end;

  procedure TRunnerMetrics.OnTestSuccess(const AName: string; AElapsedMs: QWord);
  begin
    AddRec(AName, AElapsedMs);
  end;

  procedure TRunnerMetrics.OnTestFailure(const AName, AMessage: string; AElapsedMs: QWord);
  begin
    AddRec(AName, AElapsedMs);
  end;

  procedure TRunnerMetrics.OnTestSkipped(const AName: string; AElapsedMs: QWord);
  begin
    Inc(FSkipped);
  end;

  procedure TRunnerMetrics.OnEnd(ATotal, AFailed: Integer; AElapsedMs: QWord);
  begin
  end;

  function TRunnerMetrics.GetSkipped: Integer;
  begin
    Result := FSkipped;
  end;

  procedure TRunnerMetrics.GetTopSlowest(N: Integer; var Names: array of string; var Times: array of QWord);
  var
    i, j, k, Count, Take: Integer;
    used: array of Boolean;
  begin
    Count := Length(FRecs);
    if N <= 0 then Exit;
    SetLength(used, Count);
    if Length(Names) < N then Exit;
    if Length(Times) < N then Exit;
    // simple N-pass selection of max
    Take := 0;
    for i := 0 to N-1 do
    begin
      k := -1;
      for j := 0 to Count-1 do
        if (not used[j]) and ((k = -1) or (FRecs[j].Elapsed > FRecs[k].Elapsed)) then
          k := j;
      if k = -1 then Break;
      used[k] := True;
      Names[i] := FRecs[k].Name;
      Times[i] := FRecs[k].Elapsed;
      Inc(Take);
    end;
    // zero out remaining slots if fewer tests than N
    for i := Take to N-1 do
    begin
      Names[i] := '';
      Times[i] := 0;
    end;
  end;


procedure TestMain;
var
  i, Failed, Total: Integer;
  Name, JUnitFile, JsonFile, Filter: string;
  Proc: TTestProc;
  Ctx: ITestContext; // from core
  Start, SuiteStart: QWord;
  ElapsedMs, SuiteElapsed: QWord;
  ConsoleL: ITestListener;
  JUnitL: ITestListener;
  JsonL: ITestListener;
  NoConsole, NoJUnit, NoJson: Boolean;
  ListOnly, FailFast, FilterCI: Boolean;
  Quiet, SummaryFlag: Boolean;
  CI, FailOnSkip: Boolean;
  TopSlowestN: Integer;
  Metrics: TRunnerMetrics;
  SlowNames: array of string;
  SlowTimes: array of QWord;
  idx: Integer;
  ListJsonPath: string;
  ListJson: Boolean;
  ListJsonPretty: Boolean;
  ListSortMode: string; // 'alpha' (default) | 'none'
  ListSortCaseSensitive: Boolean; // default False (case-insensitive)
  EnvVal: string;
  CleanupErrs: string;

  function ArgValue(const Prefix: string): string;
  var key, v: string;
  begin
    key := Prefix;
    // strip leading '--'
    if (Length(key) >= 2) and (key[1] = '-') and (key[2] = '-') then
      key := Copy(key, 3, MaxInt);
    // strip trailing '=' if present
    if (Length(key) > 0) and (key[Length(key)] = '=') then
      Delete(key, Length(key), 1);
    if CliTryGetValue(key, v) then Exit(v);
    Result := '';
  end;

  function HasFlag(const Flag: string): Boolean;
  begin
    Result := CliHasFlag(Flag);
  end;

  function MatchesFilter(const S, F: string; const CaseInsensitive: Boolean): boolean;
  var SS, FF: string;
  begin
    if F = '' then Exit(True);
    if CaseInsensitive then
    begin
      SS := LowerCase(S);
      FF := LowerCase(F);
      Exit(Pos(FF, SS) > 0);
    end;
    Result := Pos(F, S) > 0;
  end;

  function WriteListJson(const PathOrEmpty, Filter: string; const FilterCI, Pretty, SortAlpha, SortCaseSensitive: Boolean): Boolean;
  var
    Names: TStringList;
    Arr: TJSONArray;
    i: Integer; Name: string; Proc: TTestProc;
    JsonText: string;
    SL: TStringList;
  begin
    Result := False;
    Names := TStringList.Create;
    try
      Names.Sorted := SortAlpha;           // 稳定排序（字母序）或保持注册顺序
      Names.CaseSensitive := SortCaseSensitive;
      if SortAlpha then Names.Duplicates := dupIgnore;
      for i := 0 to RegisteredTestCount-1 do
      begin
        GetRegisteredTest(i, Name, Proc);
        if MatchesFilter(Name, Filter, FilterCI) then
          Names.Add(Name);
      end;

      Arr := TJSONArray.Create;
      try
        for i := 0 to Names.Count-1 do
          Arr.Add(Names[i]);
        if Pretty then JsonText := Arr.FormatJSON() else JsonText := Arr.FormatJSON([]);
      finally
        Arr.Free;
      end;

      if PathOrEmpty = '' then
      begin
        Write(JsonText);
        Result := True;
      end
      else
      begin
        SL := TStringList.Create;
        try
          SL.Text := JsonText;
          try
            SL.SaveToFile(PathOrEmpty);
            Result := True;
          except
            on E: Exception do
            begin
              WriteLn(StdErr, 'ERROR: failed to write ', PathOrEmpty, ': ', E.Message);
              Result := False;
            end;
          end;
        finally
          SL.Free;
        end;
      end;
    finally
      Names.Free;
    end;
  end;

begin
  // inform core that our custom runner is active so that Skip/Assume raise ETestSkip
  _SetRunnerActive(True);
  // parse args
  if CliIsHelpRequested then
  begin
    WriteLn('Usage: tests.exe [--filter=substr] [--filter-ci] [--list] [--list-json[=path]] [--list-json-pretty] [--list-sort=alpha|none] [--list-sort-case] [--help] [--version]');
    WriteLn('       tests.exe [--junit[=report.xml]] [--json[=report.json]] [--no-console] [--no-junit] [--no-json] [--fail-fast] [--quiet] [--summary] [--ci] [--fail-on-skip] [--top-slowest=N]');
    WriteLn('');
    WriteLn('  --filter=substr   Run tests whose hierarchical names contain substr');
    WriteLn('  --filter-ci       Case-insensitive filter match');
    WriteLn('  --list            List matching tests and exit');
    WriteLn('  --list-json[=p]  Output matching tests as JSON to stdout or file path p');
    WriteLn('  --list-json-pretty  Pretty-print JSON (default is compact)');
    WriteLn('  --list-sort=alpha|none  Sort output names (default alpha) or keep registration order');
    WriteLn('  --list-sort-case  Use case-sensitive alpha sort (default is case-insensitive)');
    WriteLn('  --junit[=path]    Write JUnit XML to file (adapter or sink). If no path, defaults to junit.xml');
    WriteLn('  --json[=path]     Write JSON report to file (adapter or sink). If no path, defaults to report.json');
    WriteLn('  --no-console      Disable console listener');
    WriteLn('  --no-junit        Disable JUnit listener');
    WriteLn('  --no-json         Disable JSON listener');
    WriteLn('');
    WriteLn('  Environment defaults:');
    WriteLn('    FAFAFA_TEST_JUNIT_FILE  Default path for --junit when not specified');
    WriteLn('    FAFAFA_TEST_JSON_FILE   Default path for --json when not specified');
    WriteLn('');
    WriteLn('  Flags:');
    WriteLn('  --quiet           Suppress console output (still writes junit/json if set)');
    WriteLn('  --summary         Print a concise end-of-suite summary');
    WriteLn('  --fail-fast       Stop on first failure (suite still finalizes)');
    WriteLn('  --ci              CI-friendly: implies --quiet --summary and default junit.xml');
    WriteLn('  --fail-on-skip    Return non-zero exit code if any test was skipped');
    WriteLn('  --top-slowest=N   Print top N slowest tests in summary');
    WriteLn('  --help, -h, /?    Show this help');
    WriteLn('  --version         Show version info');
    WriteLn('');
    WriteLn('  Notes:');
    WriteLn('    --list-json output is alpha-sorted by default (case-insensitive) for stable results');
    WriteLn('Examples:');
    WriteLn('  tests.exe --list');
    WriteLn('  tests.exe --filter=math/');
    WriteLn('  tests.exe --filter=string/equals --junit=results.xml');
    WriteLn('');
    WriteLn('Notes:');
    WriteLn('  - This runner focuses on framework-first usage and console output.');
    WriteLn('  - External report formats (JUnit/JSON) are considered adapters and are');
    WriteLn('    not enabled by default.');
    Halt(0);
  end;

  if HasFlag('--version') then
  begin
    WriteLn('fafafa.core.test runner version 0.1');
    Halt(0);
  end;

  JUnitFile := ArgValue('--junit=');
  JsonFile := ArgValue('--json=');
  Filter := ArgValue('--filter=');
  NoConsole := HasFlag('--no-console');
  NoJUnit := HasFlag('--no-junit');
  NoJson := HasFlag('--no-json');
  ListOnly := HasFlag('--list');
  ListJsonPath := ArgValue('--list-json=');
  ListJson := HasFlag('--list-json') or (ListJsonPath <> '');
  ListJsonPretty := HasFlag('--list-json-pretty');
  ListSortMode := ArgValue('--list-sort=');
  ListSortCaseSensitive := HasFlag('--list-sort-case');
  FailFast := HasFlag('--fail-fast');
  FilterCI := HasFlag('--filter-ci');
  Quiet := HasFlag('--quiet');
  SummaryFlag := HasFlag('--summary');
  CI := HasFlag('--ci');
  FailOnSkip := HasFlag('--fail-on-skip');
  TopSlowestN := StrToIntDef(ArgValue('--top-slowest='), 0);

  // environment variable defaults (used if CLI paths not provided)
  if (JUnitFile = '') and (not NoJUnit) then
  begin
    EnvVal := GetEnvironmentVariable('FAFAFA_TEST_JUNIT_FILE');
    if EnvVal <> '' then JUnitFile := EnvVal;
  end;
  if (JsonFile = '') and (not NoJson) then
  begin
    EnvVal := GetEnvironmentVariable('FAFAFA_TEST_JSON_FILE');
    if EnvVal <> '' then JsonFile := EnvVal;
  end;

  if CI then
  begin
    Quiet := True;
    SummaryFlag := True;
    if (JUnitFile = '') and (not NoJUnit) then JUnitFile := 'junit.xml';
  end;

  if Quiet then NoConsole := True;

  // allow bare --junit / --json to use default file names
  if (JUnitFile = '') and HasFlag('--junit') then JUnitFile := 'junit.xml';
  if (JsonFile = '') and HasFlag('--json') then JsonFile := 'report.json';

  if ListOnly then
  begin
    for i := 0 to RegisteredTestCount-1 do
    begin
      GetRegisteredTest(i, Name, Proc);
      if MatchesFilter(Name, Filter, FilterCI) then WriteLn(Name);
    end;
    Halt(0);
  end;

  if ListJson then
  begin
    // 默认 alpha 排序（不区分大小写），可用 --list-sort=none 关闭排序；--list-sort-case 切换为区分大小写
    if (ListSortMode = '') then ListSortMode := 'alpha';
    if WriteListJson(ListJsonPath, Filter, FilterCI,
                     ListJsonPretty,
                     (LowerCase(ListSortMode) <> 'none'),
                     ListSortCaseSensitive) then Halt(0)
    else Halt(2);
  end;

  // listeners
  ClearListeners; // avoid listener accumulation across multiple runs in same process
  if not NoConsole then begin
    if SameText(GetEnvironmentVariable('FAFAFA_TEST_USE_SINK_CONSOLE'), '1') then
    begin
      // Use sink-based console output via adapter (opt-in)
      ConsoleL := TTestListenerSinkAdapter.Create(TReportConsoleSink.Create);
    end
    else
    begin
      // Default legacy console listener
      ConsoleL := TConsoleTestListener.Create;
    end;
    AddListener(ConsoleL);
  end;
  if (JUnitFile <> '') and (not NoJUnit) then begin
    if SameText(GetEnvironmentVariable('FAFAFA_TEST_USE_SINK_JUNIT'), '1') then
      JUnitL := TTestListenerSinkAdapter.Create(TReportJUnitSink.Create(JUnitFile))
    else
      JUnitL := TJUnitTestListener.Create(JUnitFile);
    AddListener(JUnitL);
  end;
  if (JsonFile <> '') and (not NoJson) then begin
    if SameText(GetEnvironmentVariable('FAFAFA_TEST_USE_SINK_JSON'), '1') then
      JsonL := TTestListenerSinkAdapter.Create(TReportJsonSink.Create(@CreateRtlJsonWriter, JsonFile))
    else
      JsonL := TJsonTestListener.Create(@CreateRtlJsonWriter, JsonFile);
    AddListener(JsonL);
  end;

  // count total after filter
  Total := 0;
  for i := 0 to RegisteredTestCount-1 do
  begin
    GetRegisteredTest(i, Name, Proc);
    if MatchesFilter(Name, Filter, FilterCI) then Inc(Total);
  end;

  SuiteStart := GetTickCount64;
  // attach internal metrics listener for skipped count and timings
  Metrics := TRunnerMetrics.Create;
  AddListener(Metrics);
  NotifyStart(Total);

  Failed := 0;
  for i := 0 to RegisteredTestCount-1 do
  begin
    GetRegisteredTest(i, Name, Proc);
    if not MatchesFilter(Name, Filter, FilterCI) then Continue;

    // top-level: set context name for hierarchical subtests
    NotifyTestStart(Name);
    Ctx := NewTestContext;
    Ctx.SetName(Name);
    Start := GetTickCount64;
    try
      Proc(Ctx);
      ElapsedMs := GetTickCount64 - Start;
      // even on success, ensure we try cleanups and capture errors
      CleanupErrs := '';
      if Ctx.RunCleanupsCapture(CleanupErrs) then
      begin
        Inc(Failed);
        NotifyTestFailure(Name, 'cleanup errors:' + LineEnding + CleanupErrs, ElapsedMs);
        if FailFast then Break;
      end
      else
        NotifyTestSuccess(Name, ElapsedMs);
    except
      on E: ETestSkip do
      begin
        ElapsedMs := GetTickCount64 - Start;
        // run cleanups, ignore cleanup errors for skipped
        Ctx.RunCleanupsNow;
        NotifyTestSkipped(Name, ElapsedMs);
      end;
      on E: ETestFailure do
      begin
        ElapsedMs := GetTickCount64 - Start;
        Inc(Failed);
        CleanupErrs := '';
        Ctx.RunCleanupsCapture(CleanupErrs);
        if CleanupErrs <> '' then
          NotifyTestFailure(Name, E.Message + LineEnding + '[cleanup]' + LineEnding + CleanupErrs, ElapsedMs)
        else
          NotifyTestFailure(Name, E.Message, ElapsedMs);
        if FailFast then Break;
      end;
      on E: Exception do
      begin
        ElapsedMs := GetTickCount64 - Start;
        Inc(Failed);
        CleanupErrs := '';
        Ctx.RunCleanupsCapture(CleanupErrs);
        if CleanupErrs <> '' then
          NotifyTestFailure(Name, E.ClassName+': '+E.Message + LineEnding + '[cleanup]' + LineEnding + CleanupErrs, ElapsedMs)
        else
          NotifyTestFailure(Name, E.ClassName+': '+E.Message, ElapsedMs);
        if FailFast then Break;
      end;
    end;
  end;
  SuiteElapsed := GetTickCount64 - SuiteStart;
  NotifyEnd(Total, Failed, SuiteElapsed);

  if SummaryFlag or CI then
  begin
    if Failed > 0 then
      WriteLn(Format('== FAILED: %d of %d in %d ms ==', [Failed, Total, SuiteElapsed]))
    else
      WriteLn(Format('== OK: %d tests, %d ms ==', [Total, SuiteElapsed]));

    if TopSlowestN > 0 then
    begin
      SetLength(SlowNames, TopSlowestN);
      SetLength(SlowTimes, TopSlowestN);
      Metrics.GetTopSlowest(TopSlowestN, SlowNames, SlowTimes);
      WriteLn('Top slowest:');
      for idx := 0 to TopSlowestN-1 do
        if SlowNames[idx] <> '' then
          WriteLn(Format('  %d) %s - %d ms', [idx+1, SlowNames[idx], SlowTimes[idx]]));
    end;
  end;

  if (Failed > 0) or (FailOnSkip and (Metrics.GetSkipped > 0)) then Halt(1) else Halt(0);
end;

end.

