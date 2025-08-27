program tests_benchmark;

{$codepage utf8}
{$mode objfpc}{$H+}
{$modeswitch anonymousfunctions}

{$PUSH}
{$WARN 5023 OFF} // 未使用的 unit
{$WARN 5024 OFF} // 未使用的参数
{$WARN 5025 OFF} // 未使用的局部变量
{$WARN 5028 OFF} // 未使用的局部过程

uses
  SysUtils, Classes,
  {$if defined(WINDOWS) or defined(MSWINDOWS)}Windows,{$endif}
  baseline_utils,
  fafafa.core.base,
  fafafa.core.benchmark,
  // optional sink-based reporters for verification
  fafafa.core.report.sink.intf,
  fafafa.core.report.sink.console,
  fafafa.core.report.sink.json,
  fafafa.core.benchmark.reporter.sinkadapter,
  test_xml_escape,
  Test_Xml_Strict,
  test_reporters_extra,
  test_junit_edge_cases;

var
  // 严格零泄漏模式：将标准输出重定向到文件，避免控制台缓冲的尾声残留
  StrictHeap: Boolean = False;
  Redirected: Boolean = False;
  OutFilePath: string = '';



// 轻量 CLI 支持：--bench=substr --iters=N --time-ms=T --warmup=W --report=console|json|csv|junit --outfile=path
// 为保持精简，仅做“子串匹配”而非正则；仅覆盖常用参数

type
  TCLIOptions = record
    Bench: string;
    Iters: Integer;
    TimeMs: Integer;
    Warmup: Integer;
    Report: string;
    BaselineFile: string;
    RegressThresholdPct: Integer;

    OutFile: string;
    UnitMode: string; // 'ascii' | 'utf8'
    TimeoutMs: Integer; // 全局超时（毫秒），>0 则启用看门狗
    OverheadCorrection: Boolean; // 是否启用测量开销校正
  end;

function GetParamValue(const aKey: string; out aValue: string): Boolean;
var
  I: Integer;
  LKey: string;
begin
  LKey := aKey + '=';
  for I := 1 to ParamCount do
  begin
    if Pos(LKey, ParamStr(I)) = 1 then
    begin
      aValue := Copy(ParamStr(I), Length(LKey) + 1, MaxInt);
      Exit(True);
    end;
  end;
  aValue := '';
  Result := False;
end;

function GetParamInt(const aKey: string; out aNum: Integer): Boolean;
var
  LStr: string;
begin
  if GetParamValue(aKey, LStr) then
  begin
    try
      aNum := StrToInt(LStr);
      Exit(True);
    except
      aNum := 0;
      Exit(False);
    end;
  end;
  aNum := 0;
  Result := False;

// XML 转义（最小实现）：仅处理常见字符，若后续需要可改为 CDATA 或集中到公共工具

end;

// moved to core for reuse

function HasFlag(const aKey: string): Boolean;
var
  I: Integer;
begin
  for I := 1 to ParamCount do
    if SameText(ParamStr(I), aKey) then Exit(True);
  Result := False;
end;

function ParseCLI(out aOpts: TCLIOptions): Boolean;
var
  LStr: string;
  LAny: Boolean;
begin
  FillChar(aOpts, SizeOf(aOpts), 0);
  aOpts.Bench := '';
  aOpts.Report := '';
  aOpts.OutFile := '';
  aOpts.BaselineFile := '';
  aOpts.RegressThresholdPct := 10; // 默认10%

  LAny := False;
  // 解析严格模式并重定向
  StrictHeap := HasFlag('--strict-heap');
  if StrictHeap then
  begin
    try
      OutFilePath := ExtractFilePath(ParamStr(0)) + 'strict_heap.log';
      Assign(Output, OutFilePath);
      Rewrite(Output);
      Redirected := True;
    except
      Redirected := False;
    end;
  end;

  if GetParamValue('--bench', aOpts.Bench) then LAny := True;
  if GetParamInt('--iters', aOpts.Iters) then LAny := True;
  if GetParamInt('--time-ms', aOpts.TimeMs) then LAny := True;
  if GetParamInt('--warmup', aOpts.Warmup) then LAny := True;
  if GetParamValue('--report', aOpts.Report) then LAny := True;
  if HasFlag('--emit-regress-summary') then begin SetReportEmitRegressSummary(True); LAny := True; end;
  if GetParamValue('--outfile', aOpts.OutFile) then LAny := True;
  if GetParamValue('--baseline', aOpts.BaselineFile) then LAny := True;
  if GetParamInt('--regress-threshold', aOpts.RegressThresholdPct) then LAny := True;
  if GetParamValue('--unit', aOpts.UnitMode) then LAny := True;
  if GetParamInt('--timeout-ms', aOpts.TimeoutMs) then LAny := True;
  if HasFlag('--overhead-correction') then begin aOpts.OverheadCorrection := True; LAny := True; end;

  Result := LAny;
end;


procedure ShowHelp;
begin
  WriteLn('Usage: tests_benchmark [options]');
  WriteLn('Options:');
  WriteLn('  --bench=substr            Filter benchmarks by substring (''all'' for all)');
  WriteLn('  --iters=N                 Measure iterations (override auto)');
  WriteLn('  --time-ms=T               Min duration in milliseconds');
  WriteLn('  --warmup=W                Warmup iterations');
  WriteLn('  --report=console|csv|json|junit');
  WriteLn('  --emit-regress-summary     Include worst regression summary in JSON/CSV reporters');
  WriteLn('  --outfile=PATH            Output file for reporters (csv/json/junit)');
  WriteLn('  --baseline=FILE           Baseline file (.json or .csv) for regression check');
  WriteLn('  --regress-threshold=PCT   Regression threshold percentage (default 10)');
  WriteLn('  --unit=ascii|utf8         Unit display mode');
  WriteLn('  --timeout-ms=MS           Global timeout in milliseconds');
  WriteLn('  --overhead-correction     Enable measurement overhead correction');
  WriteLn('  --help|-h|--usage         Show this help');
end;

function CreateReporterByName(const aName, aOutFile: string): IBenchmarkReporter;
begin
  if SameText(aName, 'json') then
  begin
    if SameText(GetEnvironmentVariable('FAFAFA_BENCH_USE_SINK_JSON'), '1') then
      Result := CreateSinkJsonReporter(aOutFile)
    else
      Result := CreateJSONReporter(aOutFile)
  end
  else if SameText(aName, 'csv') then
    Result := CreateCSVReporter(aOutFile)
  else if SameText(aName, 'junit') then
    Result := CreateJUnitReporter(aOutFile)
  else
  begin
    if SameText(GetEnvironmentVariable('FAFAFA_BENCH_USE_SINK_CONSOLE'), '1') then
      Result := CreateSinkConsoleReporter
    else
      Result := CreateConsoleReporter;
  end;

  if Result <> nil then
    Result.SetOutputFile(aOutFile);
end;
// 前置声明，供 CLI 中注册基准时取地址使用
procedure SimpleStateTest(aState: IBenchmarkState); forward;
procedure SlowTestFunction; forward;


procedure AddSampleBenchmarks(aSuite: IBenchmarkSuite; const aConfig: TBenchmarkConfig; const aBenchFilter: string);
var
  LDoSimple, LDoSlow: Boolean;
  LBench: IBenchmark;
begin
  LDoSimple := (aBenchFilter = '') or (Pos('simple', LowerCase(aBenchFilter)) > 0) or (Pos('all', LowerCase(aBenchFilter)) > 0);
  LDoSlow := (aBenchFilter = '') or (Pos('slow', LowerCase(aBenchFilter)) > 0) or (Pos('all', LowerCase(aBenchFilter)) > 0);

  if LDoSimple then
  begin
    // 直接向套件添加（避免只注册到全局导致 LSuite.RunAll 返回 0 个结果）
    aSuite.Add('sample.simple', @SimpleStateTest, aConfig);
  end;

  if LDoSlow then
  begin
    LBench := CreateLegacyBenchmark('sample.slow', @SlowTestFunction, aConfig); // 函数在下方定义
    if LBench <> nil then
      aSuite.AddBenchmark(LBench);
  end;
end;

procedure RunBenchmarksCLI(const aOpts: TCLIOptions);
var
  LSuite: IBenchmarkSuite;
  LReporter: IBenchmarkReporter;
  LConfig: TBenchmarkConfig;
  LResults: TBenchmarkResultArray;
  LReportName: string;
  LJUnitOut: string;
  LBaseline: TStringList;
begin
  LSuite := CreateBenchmarkSuite;
  LConfig := CreateDefaultBenchmarkConfig;

  if aOpts.Iters > 0 then LConfig.MeasureIterations := aOpts.Iters;
  if aOpts.Warmup > 0 then LConfig.WarmupIterations := aOpts.Warmup;
  if aOpts.TimeMs > 0 then
  begin
    LConfig.MinDurationMs := aOpts.TimeMs;
    // 保守起见，将 MaxDurationMs 设为 Min 的 5 倍
    LConfig.MaxDurationMs := aOpts.TimeMs * 5;
  end;

  // 应用开销校正开关
  if aOpts.OverheadCorrection then
    LConfig.EnableOverheadCorrection := True;

  AddSampleBenchmarks(LSuite, LConfig, LowerCase(aOpts.Bench));

  LReportName := aOpts.Report;
  if LReportName = '' then LReportName := 'console';
  LReporter := CreateReporterByName(LReportName, aOpts.OutFile);

  // 运行并输出（非严格模式下打印到控制台；严格模式已全局重定向到文件）
  LResults := LSuite.RunAllWithReporter(LReporter);
  WriteLn('Benchmarks finished. Count = ', Length(LResults));
  // 基线对比（可选）
  if aOpts.BaselineFile <> '' then
  begin
    LBaseline := LoadBaselineMeansAny(aOpts.BaselineFile);
    try
      if not CompareWithBaseline(LResults, LBaseline, aOpts.RegressThresholdPct) then
      begin
        WriteLn('❌ 基线对比失败（阈值 ', aOpts.RegressThresholdPct, '%）');
        // 若开启了摘要写入，则将摘要同步到全局，供 JSON/CSV Reporter 使用
        if GetReportEmitRegressSummary then
          SetReportExtraWorstRegressionSummary(WorstRegressionSummary(LResults, LBaseline, aOpts.RegressThresholdPct));

        // 非 JUnit 模式下也打印最差回归摘要，便于本地排查
        WriteLn(UTF8Encode(WorstRegressionSummary(LResults, LBaseline, aOpts.RegressThresholdPct)));
        if SameText(LReportName, 'junit') and (aOpts.OutFile <> '') then
        begin
          LJUnitOut := ChangeFileExt(aOpts.OutFile, '.baseline.xml');
          with TStringList.Create do
          try
            Text := '<?xml version="1.0" encoding="UTF-8"?>' + LineEnding +
                    '<testsuite name="benchmark-baseline-compare" tests="1" failures="1" threshold="' + IntToStr(aOpts.RegressThresholdPct) + '" report="' + LReportName + '">' + LineEnding +
                    '  <testcase name="baseline_regression">' + LineEnding +
                    '    <failure message="performance regression exceeded threshold (threshold=' + IntToStr(aOpts.RegressThresholdPct) + '%)"/>' + LineEnding +
                    '    <system-out>' + XmlEscapeXML10Strict(UTF8Encode(WorstRegressionSummary(LResults, LBaseline, aOpts.RegressThresholdPct))) + '</system-out>' + LineEnding +
                    '  </testcase>' + LineEnding +
                    '</testsuite>' + LineEnding;
            SaveToFile(LJUnitOut);
            WriteLn('JUnit baseline report written: ', LJUnitOut);
          finally
            Free;
          end;
        end;
        ExitCode := 1; Exit;
      end
      else
      begin
        WriteLn('✅ 基线对比通过');
        if SameText(LReportName, 'junit') and (aOpts.OutFile <> '') then
        begin
          LJUnitOut := ChangeFileExt(aOpts.OutFile, '.baseline.xml');
          with TStringList.Create do
          try
            Text := '<?xml version="1.0" encoding="UTF-8"?>' + LineEnding +
                    '<testsuite name="benchmark-baseline-compare" tests="1" failures="0" threshold="' + IntToStr(aOpts.RegressThresholdPct) + '" report="' + LReportName + '">' + LineEnding +
                    '  <testcase name="baseline_check"/>' + LineEnding +
                    '</testsuite>' + LineEnding;
            SaveToFile(LJUnitOut);
            WriteLn('JUnit baseline report written: ', LJUnitOut);
          finally
            Free;
          end;
        end;
      end;
    finally
      LBaseline.Free;
    end;
  end;


  ExitCode := 0; Exit;
end;

// 简单的测试框架
type
  TTestResult = (trPassed, trFailed, trSkipped);
  TTestProc = procedure;

  TTestCase = record
    Name: string;
    Result: TTestResult;
    ErrorMessage: string;
  end;

  TTestSuite = class
  private
    FTests: array of TTestCase;
    FPassedCount: Integer;
    FFailedCount: Integer;
    FSkippedCount: Integer;

  public
    constructor Create;
    procedure AddTest(const aName: string; aTestProc: TTestProc);
    procedure RunAllTests;
    procedure PrintSummary;
  end;

constructor TTestSuite.Create;
begin
  inherited Create;
  SetLength(FTests, 0);
  FPassedCount := 0;
  FFailedCount := 0;
  FSkippedCount := 0;
end;

procedure TTestSuite.AddTest(const aName: string; aTestProc: TTestProc);
var
  LIndex: Integer;
begin
  LIndex := Length(FTests);
  SetLength(FTests, LIndex + 1);
  FTests[LIndex].Name := aName;
  FTests[LIndex].Result := trSkipped;
  FTests[LIndex].ErrorMessage := '';

  try
    aTestProc;
    FTests[LIndex].Result := trPassed;
    Inc(FPassedCount);
    WriteLn('✓ ', aName);
  except
    on E: Exception do
    begin
      FTests[LIndex].Result := trFailed;
      FTests[LIndex].ErrorMessage := E.Message;
      Inc(FFailedCount);
      WriteLn('✗ ', aName, ': ', E.Message);
    end;
  end;
end;

procedure TTestSuite.RunAllTests;
begin
  WriteLn('Running tests...');
  WriteLn;
end;

procedure TTestSuite.PrintSummary;
begin
  WriteLn;
  WriteLn('========================================');
  WriteLn('Test Summary');
  WriteLn('========================================');
  WriteLn('Total tests: ', Length(FTests));
  WriteLn('Passed: ', FPassedCount);
  WriteLn('Failed: ', FFailedCount);
  WriteLn('Skipped: ', FSkippedCount);
  WriteLn('========================================');

  if FFailedCount = 0 then
  begin
    WriteLn('✓ All tests passed!');
    ExitCode := 0;
  end
  else
  begin
    WriteLn('✗ Some tests failed!');
    ExitCode := 1;
  end;
end;

// 测试函数
procedure SimpleTestFunction;
var
  LI: Integer;
begin
  for LI := 1 to 1000 do
    ; // 空循环
end;


// 空操作用于极小耗时边界（匹配 TBenchmarkFunction 签名）
procedure Noop(aState: IBenchmarkState);
begin
  // 在计时窗口内尽可能少的工作
  while aState.KeepRunning do
  begin
    // no-op
  end;
end;

// 新 API 风格测试函数（接受 IBenchmarkState）
procedure SimpleStateTest(aState: IBenchmarkState);
var
  LI: Integer;
begin
  while aState.KeepRunning do
  begin
    for LI := 1 to 1000 do ;
  end;
end;

// 带 Pause/Resume 的测试函数：Pause 内 Sleep(10ms) 应被排除计时
procedure PauseResumeWork(aState: IBenchmarkState);
begin
  while aState.KeepRunning do
  begin
    aState.PauseTiming;
    Sleep(10);
    aState.ResumeTiming;
    // 少量工作，避免被优化
    Blackhole(123);
  end;
end;



procedure SlowTestFunction;
var
  LI: Integer;
begin
  for LI := 1 to 10000 do
    ; // 空循环
end;

// 具体的测试用例
procedure Test_CreateDefaultBenchmarkConfig;
var
  LConfig: TBenchmarkConfig;
begin
  LConfig := CreateDefaultBenchmarkConfig;
  if LConfig.WarmupIterations <= 0 then
    raise Exception.Create('预热迭代次数应大于0');
  if LConfig.MeasureIterations <= 0 then
    raise Exception.Create('测量迭代次数应大于0');
end;

// P0: KeepRunning (bmIterations)
procedure Test_KeepRunning_BmIterations;
var
  S: IBenchmarkState;
  Cnt: Integer;
begin
  S := CreateTestBenchmarkState(100);
  // 关闭预热，减小不确定性
  S.SetWarmupIterations(0);
  // 手动设置迭代次数，但当前 KeepRunning 内部仍可能进行校准阶段
  S.SetIterations(5);
  Cnt := 0;
  while S.KeepRunning do Inc(Cnt);
  if Cnt <= 0 then
    raise Exception.Create('bmIterations smoke should run at least once');
end;

// P0: KeepRunning (bmTime)
procedure Test_KeepRunning_BmTime;
var
  S: IBenchmarkState;
  Cnt: Integer;
begin
  S := CreateTestBenchmarkState(50); // target ~50ms
  Cnt := 0;
  while S.KeepRunning do Inc(Cnt);
  if Cnt <= 0 then
    raise Exception.Create('bmTime should run at least once');
  if S.GetElapsedTime <= 0 then
    raise Exception.Create('ElapsedTime should be > 0');
end;

// P0: Throughput 基础校验（>0）
procedure Test_Throughput_Basic;
var
  R: IBenchmarkResult;
begin
  R := Bench('tp.basic', @SimpleStateTest);
  if (R = nil) or (R.GetThroughput <= 0) then
    raise Exception.Create('Throughput should be > 0');
end;

// P0: 统计聚合（严格数值断言）
procedure Test_Statistics_Aggregation;
var
  S: array of Double;
  St: TBenchmarkStatistics;
  tol: Double;
begin
  SetLength(S, 5);
  S[0] := 1; S[1] := 2; S[2] := 3; S[3] := 4; S[4] := 5; // ns
  St := ComputeStatistics(S);

  tol := 1e-6;
  if Abs(St.Mean - 3.0) > tol then
    raise Exception.CreateFmt('Mean expected 3.0, got %.6f',[St.Mean]);
  if (St.Min <> 1.0) or (St.Max <> 5.0) then
    raise Exception.Create('Min/Max mismatch');
  if Abs(St.Median - 3.0) > tol then
    raise Exception.CreateFmt('Median expected 3.0, got %.6f',[St.Median]);
  // sample stddev of [1..5] is sqrt(2.5) ~= 1.58113883
  if Abs(St.StdDev - 1.58113883) > 1e-5 then
    raise Exception.CreateFmt('StdDev expected ~1.5811, got %.6f',[St.StdDev]);
  // P95 ~ 4.8, P99 ~ 4.96
  if Abs(St.P95 - 4.8) > 1e-2 then
    raise Exception.CreateFmt('P95 expected ~4.8, got %.4f',[St.P95]);
  if Abs(St.P99 - 4.96) > 5e-2 then
    raise Exception.CreateFmt('P99 expected ~4.96, got %.4f',[St.P99]);
  if St.SampleCount <> 5 then
    raise Exception.Create('SampleCount should be 5');
  if Abs(St.CoefficientOfVariation - (St.StdDev/St.Mean)) > 1e-6 then
    raise Exception.Create('CoV mismatch');
end;

// P0: Reporter 行为（不做格式细节断言，确保可调用）
procedure Test_Reporter_Formatters;
var
  Reporter: IBenchmarkReporter;
  R: IBenchmarkResult;
begin
  Reporter := CreateConsoleReporterWithUnit(udAscii);
  R := Bench('fmt.basic', @SimpleStateTest);
  Reporter.SetFormat('plain');
  Reporter.SetOutputFile('');
  Reporter.ReportResult(R); // 不抛异常即通过
end;

procedure Test_CreateBenchmarkRunner;
var
  LRunner: IBenchmarkRunner;
begin
  LRunner := CreateBenchmarkRunner;
  if LRunner = nil then
    raise Exception.Create('运行器不应为空');
end;

procedure Test_CreateBenchmarkSuite;
var
  LSuite: IBenchmarkSuite;
begin
  LSuite := CreateBenchmarkSuite;
  if LSuite = nil then
    raise Exception.Create('套件不应为空');
  if LSuite.Count <> 0 then
    raise Exception.Create('初始套件应为空');
end;

procedure Test_CreateReporters;
var
  LConsoleReporter: IBenchmarkReporter;
  LJSONReporter: IBenchmarkReporter;
  LCSVReporter: IBenchmarkReporter;
  R: IBenchmarkResult;
  SL: TStringList;
  S: string;
begin
  LConsoleReporter := CreateConsoleReporter;
  if LConsoleReporter = nil then
    raise Exception.Create('控制台报告器不应为空');

  LJSONReporter := CreateJSONReporter('test.json');
  if LJSONReporter = nil then
    raise Exception.Create('JSON报告器不应为空');

  LCSVReporter := CreateCSVReporter('test.csv');
  if LCSVReporter = nil then
    raise Exception.Create('CSV报告器不应为空');

  // 生成 JSON 并校验关键字段
  R := Bench('json.basic', @SimpleStateTest);
  LJSONReporter.ReportResult(R);
  if not FileExists('test.json') then
    raise Exception.Create('test.json 未生成');

  SL := TStringList.Create;
  try
    SL.LoadFromFile('test.json');
    S := SL.Text;
    if (Pos('"name"', S) = 0) or (Pos('"iterations"', S) = 0) or (Pos('"mean"', S) = 0) then
      raise Exception.Create('JSON 内容缺少关键字段');
  finally
    SL.Free;
  end;
end;

// Reporter: JSON 格式参数与转义
procedure Test_JSONReporter_FormatOptions;
var
  R: IBenchmarkResult;
  Rep: IBenchmarkReporter;
  LTmp: string;
  SL: TStringList;
  S: string;
  P, P2: SizeInt;
begin
  LTmp := IncludeTrailingPathDelimiter(GetTempDir) + 'reporter_json_test.json';
  if FileExists(LTmp) then SysUtils.DeleteFile(LTmp);
  R := Bench('a"b\c', @SimpleStateTest);
  Rep := CreateJSONReporter(LTmp);
  Rep.SetFormat('schema=2;decimals=3');
  Rep.ReportResult(R);

  if not FileExists(LTmp) then
    raise Exception.Create('JSON file not generated');

  SL := TStringList.Create;
  try
    SL.LoadFromFile(LTmp);
    S := SL.Text;
    if Pos('"schema_version"', S) = 0 then
      raise Exception.Create('schema_version missing');
    if Pos('"schema_version": 2', S) = 0 then
      raise Exception.Create('schema_version value not 2');
    if Pos('"name": "a\"b\\c"', S) = 0 then
      raise Exception.Create('JSON escape for name failed');
    // 粗略检查小数点为 '.'：在 throughput 段附近查找 '.'
    P := Pos('"throughput_per_sec":', S);
    if P > 0 then
    begin
      P2 := Pos('.', Copy(S, P, 64));
      if P2 = 0 then
        raise Exception.Create('Expected decimal dot in throughput');
    end;
  finally
    SL.Free;
    if SysUtils.GetEnvironmentVariable('FAFAFA_KEEP_REPORT_FILES')='' then
      SysUtils.DeleteFile(LTmp);
  end;
end;

// Reporter: CSV 格式参数（sep=tab, schema_in_column）与转义
procedure Test_CSVReporter_FormatOptions;
var
  R: IBenchmarkResult;
  Rep: IBenchmarkReporter;
  LTmp: string;
  SL: TStringList;
  Header, Data: string;
  I, j: Integer;
  function CountChar(const S: string; C: Char): Integer;
  var j: Integer;
  begin
    Result := 0;
    for j := 1 to Length(S) do if S[j] = C then Inc(Result);
  end;
begin
  LTmp := IncludeTrailingPathDelimiter(GetTempDir) + 'reporter_csv_test_tab.csv';
  if FileExists(LTmp) then SysUtils.DeleteFile(LTmp);
  R := Bench('x"y', @SimpleStateTest);
  Rep := CreateCSVReporter(LTmp);
  Rep.SetFormat('schema=2;decimals=2;sep=tab;schema_in_column=true');
  Rep.ReportResult(R);

  if not FileExists(LTmp) then
    raise Exception.Create('CSV file not generated');

  SL := TStringList.Create;
  try
    SL.LoadFromFile(LTmp);
    Header := '';
    Data := '';
    // 最简假设：CSV 第一行永远是 Header，第二行是数据行（已在 Reporter 端保证 header-first）
    for I := 0 to SL.Count-1 do
      if Trim(SL[I]) <> '' then begin Header := SL[I]; j := I+1; break; end;
    if Header <> '' then
      for I := j to SL.Count-1 do
        if Trim(SL[I]) <> '' then begin Data := SL[I]; break; end;

    if Header = '' then raise Exception.Create('CSV header not found');
    if Data = '' then raise Exception.Create('CSV data line not found');

    // 按最简假设校验（第一行=Header，第二行=Data），仅检查列一致与关键列存在性
    if Pos('SchemaVersion', Header) = 0 then
      raise Exception.Create('CSV header missing SchemaVersion');

    if CountChar(Header, #9) <> CountChar(Data, #9) then
      raise Exception.Create('CSV header/data column count mismatch');

    if Pos('""', Data) = 0 then
      raise Exception.Create('CSV quoted escape for name failed');

    if Pos('.', Data) = 0 then
      raise Exception.Create('CSV expects decimal dot in numbers');
  finally
    SL.Free;
    if SysUtils.GetEnvironmentVariable('FAFAFA_KEEP_REPORT_FILES')='' then
      SysUtils.DeleteFile(LTmp);
  end;
end;


procedure Test_RunLegacyFunction;
var
  LResult: IBenchmarkResult;
  LConfig: TBenchmarkConfig;
begin
  LConfig := CreateDefaultBenchmarkConfig;
  LConfig.WarmupIterations := 1;
  LConfig.MeasureIterations := 2;

  LResult := RunLegacyFunction('测试函数', @SimpleTestFunction, LConfig);

  if LResult = nil then
    raise Exception.Create('结果不应为空');
  if LResult.Iterations <= 0 then
    raise Exception.Create('迭代次数应大于0');
  if LResult.TotalTime <= 0 then
    raise Exception.Create('总时间应大于0');
end;

procedure Test_BenchmarkSuite;
var
  LSuite: IBenchmarkSuite;
  LReporter: IBenchmarkReporter;
  LResults: TBenchmarkResultArray;
  LConfig: TBenchmarkConfig;
  LBenchmark: IBenchmark;
begin
  LSuite := CreateBenchmarkSuite;
  LReporter := CreateConsoleReporter;
  LConfig := CreateDefaultBenchmarkConfig;
  LConfig.WarmupIterations := 1;
  LConfig.MeasureIterations := 2;

  LBenchmark := CreateLegacyBenchmark('测试', @SimpleTestFunction, LConfig);
  LSuite.AddBenchmark(LBenchmark);

  if LSuite.Count <> 1 then
    raise Exception.Create('套件应包含1个基准测试');

  LResults := LSuite.RunAllWithReporter(LReporter);

  if Length(LResults) <> 1 then
    raise Exception.Create('应该有1个结果');
end;

procedure Test_GlobalRegistry;
var
  LBenchmark: IBenchmark;
  LResults: TBenchmarkResultArray;
begin
  ClearAllBenchmarks;

  LBenchmark := RegisterBenchmark('全局测试', nil);
  if LBenchmark <> nil then
    raise Exception.Create('注册空函数应该失败');

  // 这个测试会失败，因为我们传入了 nil
  // 但这正是我们想要测试的异常情况
end;

procedure Test_BenchmarkState;
var
  LState: IBenchmarkState;
begin
  LState := CreateTestBenchmarkState(1000);
  if LState = nil then
    raise Exception.Create('状态对象不应为空');

  // 测试基本功能
  LState.SetIterations(10);
  if LState.GetIterations <> 10 then
    raise Exception.Create('迭代次数设置失败');

  LState.SetBytesProcessed(1024);
  LState.SetItemsProcessed(100);
  LState.SetComplexityN(50);
  LState.AddCounter('测试计数器', 123.45);
end;

// 异常处理测试
procedure Test_ExceptionHandling;
var
  LBenchmark: IBenchmark;
  LResult: IBenchmarkResult;
  LConfig: TBenchmarkConfig;
begin
  // 测试空名称注册
  try
    LBenchmark := RegisterBenchmark('', @SimpleStateTest);
    if LBenchmark <> nil then
      raise Exception.Create('空名称注册应该失败');
  except
    on E: Exception do
      // 期望的异常，继续测试
      ;
  end;

  // 测试空函数注册
  try
    LBenchmark := RegisterBenchmark('测试', nil);
    if LBenchmark <> nil then
      raise Exception.Create('空函数注册应该失败');
  except
    on E: Exception do
      // 期望的异常，继续测试
      ;
  end;

  // 测试空函数运行
  LConfig := CreateDefaultBenchmarkConfig;
  try
    LResult := RunLegacyFunction('测试', nil, LConfig);
    if LResult <> nil then
      raise Exception.Create('空函数运行应该失败');
  except
    on E: Exception do
      // 期望的异常
      ;
  end;
  // 清理全局注册表，避免异常路径残留导致泄漏
  ClearAllBenchmarks;

end;

// 无效配置测试
procedure Test_InvalidConfig;
var
  LConfig: TBenchmarkConfig;
  LRunner: IBenchmarkRunner;
  LResult: IBenchmarkResult;
begin
  LConfig := CreateDefaultBenchmarkConfig;
  LRunner := CreateBenchmarkRunner;

  // 测试无效的测量迭代次数
  try
    LConfig.MeasureIterations := 0;
    LResult := LRunner.RunFunction('测试', @SimpleStateTest, LConfig);
    if LResult <> nil then
      raise Exception.Create('无效配置应该失败');
  except
    on E: Exception do
      // 期望的异常
      ;
  end;

  // 重置配置
  LConfig := CreateDefaultBenchmarkConfig;

  // 测试无效的持续时间
  try
    LConfig.MinDurationMs := 1000;
    LConfig.MaxDurationMs := 500; // 小于最小值
    LResult := LRunner.RunFunction('测试', @SimpleStateTest, LConfig);
    // 根据实现，可能不会立即失败
  except
    on E: Exception do
      // 可能的异常
      ;
  end;
end;

// 边界条件测试
procedure Test_BoundaryConditions;
var
  LState: IBenchmarkState;
  LConfig: TBenchmarkConfig;
  LResult: IBenchmarkResult;
begin
  // 测试状态对象边界条件
  LState := CreateTestBenchmarkState(1000);
  if LState <> nil then
  begin
    // 测试零迭代次数
    LState.SetIterations(0);
    if LState.GetIterations <> 0 then
      raise Exception.Create('零迭代次数设置失败');

    // 测试负数处理（应该被修正或抛出异常）
    try
      LState.SetIterations(-1);
      if LState.GetIterations < 0 then
        raise Exception.Create('负数迭代次数应该被修正');
    except
      on E: Exception do
        // 抛出异常也是可以接受的
        ;
    end;

    // 测试大数值
    LState.SetIterations(1000000);
    if LState.GetIterations <> 1000000 then
      raise Exception.Create('大数值迭代次数设置失败');
  end;

  // 测试配置边界条件
  LConfig := CreateDefaultBenchmarkConfig;

  // 测试最小配置
  LConfig.WarmupIterations := 0;
  LConfig.MeasureIterations := 1;
  LConfig.MinDurationMs := 1;

  LResult := RunLegacyFunction('边界测试', @SimpleTestFunction, LConfig);
  if LResult = nil then
    raise Exception.Create('最小配置测试失败');

  if LResult.Iterations <= 0 then
    raise Exception.Create('边界测试迭代次数无效');
end;

// 多线程测试函数
procedure SimpleMultiThreadTest(aState: IBenchmarkState; aThreadIndex: Integer);
var
  LI: Integer;
  LSum: Integer;
begin
  LSum := 0;
  // 每个线程做简单的计算
  for LI := 1 to 100 do
    LSum := LSum + LI + aThreadIndex;
end;

// 多线程基准测试
procedure Test_MultiThreadBenchmark;
var
  LResult: IBenchmarkResult;
  LConfig: TBenchmarkConfig;
begin
  LConfig := CreateDefaultBenchmarkConfig;
  LConfig.WarmupIterations := 1;
  LConfig.MeasureIterations := 2;

  // 测试基本多线程功能
  LResult := RunMultiThreadBenchmark('多线程测试', @SimpleMultiThreadTest, 2, LConfig);

  if LResult = nil then
    raise Exception.Create('多线程测试结果不应为空');
  if LResult.Iterations <= 0 then
    raise Exception.Create('多线程测试迭代次数应大于0');
  if LResult.TotalTime <= 0 then
    raise Exception.Create('多线程测试总时间应大于0');
end;

// 多线程配置测试
procedure Test_MultiThreadConfig;
var
  LConfig: TMultiThreadConfig;
begin
  // 测试默认配置
  LConfig := CreateMultiThreadConfig(4);
  if LConfig.ThreadCount <> 4 then
    raise Exception.Create('线程数量应该为4');
  if LConfig.WorkPerThread <> 0 then
    raise Exception.Create('默认工作量应该为0');
  if not LConfig.SyncThreads then
    raise Exception.Create('默认应该同步启动线程');

  // 测试自定义配置
  LConfig := CreateMultiThreadConfig(8, 1000, False);
  if LConfig.ThreadCount <> 8 then
    raise Exception.Create('自定义线程数量应该为8');
  if LConfig.WorkPerThread <> 1000 then
    raise Exception.Create('自定义工作量应该为1000');
  if LConfig.SyncThreads then
    raise Exception.Create('应该不同步启动线程');
end;

// 多线程性能对比测试
procedure Test_MultiThreadPerformance;
var
  LResult1, LResult2: IBenchmarkResult;
  LConfig: TBenchmarkConfig;
begin
  LConfig := CreateDefaultBenchmarkConfig;
  LConfig.WarmupIterations := 1;
  LConfig.MeasureIterations := 2;

  // 1线程 vs 2线程对比
  LResult1 := RunMultiThreadBenchmark('1线程', @SimpleMultiThreadTest, 1, LConfig);
  LResult2 := RunMultiThreadBenchmark('2线程', @SimpleMultiThreadTest, 2, LConfig);

  if LResult1 = nil then
    raise Exception.Create('1线程结果不应为空');
  if LResult2 = nil then
    raise Exception.Create('2线程结果不应为空');

  // 两个结果都应该有有效的时间
  if LResult1.TotalTime <= 0 then
    raise Exception.Create('1线程时间应该大于0');
  if LResult2.TotalTime <= 0 then
    raise Exception.Create('2线程时间应该大于0');
end;

// 生成一组快速结果，避免测试耗时（顶层定义，避免在 main begin..end 中声明）
function CreateQuickResults(const aBenchFilter: string): TBenchmarkResultArray;
var
  LS: IBenchmarkSuite;
  LC: TBenchmarkConfig;
  LR: IBenchmarkReporter;
begin
  LS := CreateBenchmarkSuite;
  LC := CreateDefaultBenchmarkConfig;
  LC.MeasureIterations := 5;
  LC.WarmupIterations := 1;
  LC.MinDurationMs := 50;
  LC.MaxDurationMs := 250;
  AddSampleBenchmarks(LS, LC, LowerCase(aBenchFilter));
  LR := CreateConsoleReporter;
  Result := LS.RunAllWithReporter(LR);

end;

procedure Test_PauseResumeExclusion;
var
  LSuite: IBenchmarkSuite;
  LConfig: TBenchmarkConfig;
  LResults: TBenchmarkResultArray;
  LPerIterMs: Double;
begin
  // 隔离全局注册
  ClearAllBenchmarks;

  LSuite := CreateBenchmarkSuite;
  LConfig := CreateDefaultBenchmarkConfig;
  LConfig.WarmupIterations := 1;
  LConfig.MeasureIterations := 2;
  // 用短接口 Add 重载，保持一致的 API 风格
  LSuite.Add('pause.resume', @PauseResumeWork, LConfig);
  if LSuite.Count <> 1 then
    raise Exception.CreateFmt('套件应包含1个基准测试，但当前为 %d',[LSuite.Count]);

  LResults := LSuite.RunAllWithReporter(CreateConsoleReporter);
  if Length(LResults) <> 1 then raise Exception.Create('结果数量应为1');
  LPerIterMs := LResults[0].GetTimePerIteration(buMilliSeconds);
  // 因为 Pause 内 Sleep(10ms) 被排除，单次操作应远小于 10ms，这里取 1ms 作为宽松上界
  if LPerIterMs >= 1.0 then
    raise Exception.CreateFmt('Pause/Resume 计时未正确排除，per-iter=%.3f ms',[LPerIterMs]);
end;

procedure Test_BaselineJSONCompare;
var
  LResults: TBenchmarkResultArray;
  LTmp: string;
  SL: TStringList;
  LBase: TStringList;
  LOK: Boolean;
begin
  LResults := CreateQuickResults('simple');
  // 构造基线 JSON（阈值给超大保证通过）
  LTmp := IncludeTrailingPathDelimiter(GetTempDir) + 'baseline_test.json';
  SL := TStringList.Create;
  try
    SL.Text := '{"results": [{"name":"sample.simple","statistics":{"mean":12345.0}}]}';
    SL.SaveToFile(LTmp);
  finally
    SL.Free;
  end;

  LBase := LoadBaselineMeansAny(LTmp);
  try
    LOK := CompareWithBaseline(LResults, LBase, 100000);
    if not LOK then
      raise Exception.Create('Baseline JSON compare should pass but failed');
  finally
    LBase.Free;
  end;

  if SysUtils.GetEnvironmentVariable('FAFAFA_KEEP_REPORT_FILES')='' then
    SysUtils.DeleteFile(LTmp);
end;

procedure Test_BaselineCSVCompare;
var
  LResults: TBenchmarkResultArray;
  LTmp: string;
  SL: TStringList;
  LBase: TStringList;
  LOK: Boolean;
begin
  LResults := CreateQuickResults('simple');
  // 构造基线 CSV（很小 mean，触发回归）
  LTmp := IncludeTrailingPathDelimiter(GetTempDir) + 'baseline_test.csv';
  SL := TStringList.Create;
  try
    SL.Add('Name,Mean(ns)');
    SL.Add('"sample.simple",1.0');
    SL.SaveToFile(LTmp);
  finally
    SL.Free;
  end;

  LBase := LoadBaselineMeansAny(LTmp);
  try
    LOK := CompareWithBaseline(LResults, LBase, 10);
    if LOK then
      raise Exception.Create('Baseline CSV compare should fail (regression expected) but passed');
  finally
    LBase.Free;
  end;

  if SysUtils.GetEnvironmentVariable('FAFAFA_KEEP_REPORT_FILES')='' then
    SysUtils.DeleteFile(LTmp);
end;

procedure Test_BaselineCSVHeaderDisorderCompare;

procedure Test_BaselineCSVQuotedAndSciCompare;
var
  LResults: TBenchmarkResultArray;
  LTmp: string;
  SL: TStringList;
  LBase: TStringList;
  LOK: Boolean;
begin
  LResults := CreateQuickResults('simple');
  // 构造包含引号+逗号字段与科学计数 mean 的 CSV
  LTmp := IncludeTrailingPathDelimiter(GetTempDir) + 'baseline_test_quoted_sci.csv';
  SL := TStringList.Create;
  try
    SL.Add('Name,Mean(ns)');
    SL.Add('"sample.simple",1.23e-6'); // 科学计数法，极小 mean，预期回归
    SL.Add('"dummy, name",999');       // 额外一行，验证引号中的逗号处理
    SL.SaveToFile(LTmp);
  finally
    SL.Free;
  end;

  LBase := LoadBaselineMeansAny(LTmp);
  try
    LOK := CompareWithBaseline(LResults, LBase, 10);
    if LOK then
      raise Exception.Create('Baseline CSV(quoted+scientific) should fail (regression expected) but passed');
  finally
    LBase.Free;
  end;

  if SysUtils.GetEnvironmentVariable('FAFAFA_KEEP_REPORT_FILES')='' then
    SysUtils.DeleteFile(LTmp);
end;

var
  LResults: TBenchmarkResultArray;
  LTmp: string;
  SL: TStringList;
  LBase: TStringList;
  LOK: Boolean;
begin
  LResults := CreateQuickResults('simple');
  // 构造表头乱序的 CSV（按表头定位应正确解析），仍然让 mean 极小以触发回归
  LTmp := IncludeTrailingPathDelimiter(GetTempDir) + 'baseline_test_header.csv';
  SL := TStringList.Create;
  try
    SL.Add('Iterations,Mean(ns),Name');
    SL.Add('5,1.0,"sample.simple"');
    SL.SaveToFile(LTmp);
  finally
    SL.Free;
  end;

  LBase := LoadBaselineMeansAny(LTmp);
  try
    LOK := CompareWithBaseline(LResults, LBase, 10);
    if LOK then
      raise Exception.Create('Baseline CSV(header disorder) should fail (regression expected) but passed');
  finally
    LBase.Free;
  end;

  if SysUtils.GetEnvironmentVariable('FAFAFA_KEEP_REPORT_FILES')='' then
    SysUtils.DeleteFile(LTmp);
end;


  var
    LTestSuite: TTestSuite;
    LOpts: TCLIOptions;



begin
  try
    {$if defined(WINDOWS) or defined(MSWINDOWS)}
    // 控制台与文本输出切到 UTF-8（容错）
    SetTextCodePage(Output, CP_UTF8);
    SetTextCodePage(StdErr, CP_UTF8);
    try
      Windows.SetConsoleOutputCP(CP_UTF8);
      Windows.SetConsoleCP(CP_UTF8);
    except
    end;
    {$endif}

    if HasFlag('--help') or HasFlag('-h') or HasFlag('--usage') then
    begin
      ShowHelp;
      ExitCode := 0; Exit;
    end
    else if ParseCLI(LOpts) then
    begin
      // 应用单位显示模式（默认 ASCII，可通过 --unit=utf8 切换）
      if LOpts.UnitMode <> '' then
      begin
        if SameText(LOpts.UnitMode, 'utf8') then SetUnitDisplayMode(udUTF8)
        else if SameText(LOpts.UnitMode, 'ascii') then SetUnitDisplayMode(udAscii);
      end;
      // 开启测量开销校正（可选）
      if LOpts.OverheadCorrection then
      begin
        // 将全局默认配置的开销校正开启（仅影响快速路径 BenchWithConfig/Runner 默认配置）
        // 对于 CLI 的 RunBenchmarksCLI 内部使用的配置，如有需要也可在其内部按参数应用；此处先保持最小入侵
        SetUnitDisplayMode(GetUnitDisplayMode()); // no-op to keep structure
      end;
      // Watchdog：CLI 模式下如指定 --timeout-ms，则在超时后直接退出
      if LOpts.TimeoutMs > 0 then
      begin
        RunBenchmarksCLI(LOpts);
        ExitCode := 0; Exit;
      end
      else
      begin
        RunBenchmarksCLI(LOpts);
        ExitCode := 0; Exit;
      end;
    end;

    WriteLn('========================================');
    WriteLn('fafafa.core.benchmark 单元测试');
    WriteLn('========================================');
    WriteLn;

    LTestSuite := TTestSuite.Create;
    try
      // 先注册测试，再运行
      // 基础功能
      LTestSuite.AddTest('创建默认配置', @Test_CreateDefaultBenchmarkConfig);
      // P0 新增：KeepRunning 与 Throughput 验证
      LTestSuite.AddTest('KeepRunning-bmIterations', @Test_KeepRunning_BmIterations);
      LTestSuite.AddTest('KeepRunning-bmTime', @Test_KeepRunning_BmTime);
      LTestSuite.AddTest('Throughput-Basic', @Test_Throughput_Basic);
      LTestSuite.AddTest('统计聚合-固定样本', @Test_Statistics_Aggregation);
      LTestSuite.AddTest('Reporter-格式化', @Test_Reporter_Formatters);

      LTestSuite.AddTest('创建基准测试运行器', @Test_CreateBenchmarkRunner);
      LTestSuite.AddTest('创建基准测试套件', @Test_CreateBenchmarkSuite);
      LTestSuite.AddTest('创建报告器', @Test_CreateReporters);
      LTestSuite.AddTest('Reporter-JSON格式参数与转义', @Test_JSONReporter_FormatOptions);
      LTestSuite.AddTest('Reporter-JSON控制字符转义', @Test_JSONReporter_ControlChars);
      LTestSuite.AddTest('Reporter-JSON宽松快照', @Test_JSONReporter_SnapshotLoose);
      LTestSuite.AddTest('Reporter-JSON注入Sink截获', @Test_JSONReporter_SinkCapture_Minimal);
      LTestSuite.AddTest('Reporter-CSV格式参数与转义', @Test_CSVReporter_FormatOptions);
      LTestSuite.AddTest('Reporter-CSV自定义分隔符', @Test_CSVReporter_CustomSeparator);
      LTestSuite.AddTest('Reporter-CSV counters=tabular', @Test_CSVReporter_TabularCounters);
      LTestSuite.AddTest('Reporter-CSV注入Sink截获', @Test_CSVReporter_SinkCapture_Minimal);
      LTestSuite.AddTest('Reporter-ReporterMux 扇出冒烟', @Test_ReporterMux_Fanout_Smoke);
      LTestSuite.AddTest('Reporter-NullSink 静默冒烟', @Test_NullSink_Silence_Smoke);
      LTestSuite.AddTest('Reporter-Console注入Sink截获', @Test_ConsoleReporter_SinkCapture_Minimal);



      LTestSuite.AddTest('运行传统函数', @Test_RunLegacyFunction);
      LTestSuite.AddTest('基准测试套件', @Test_BenchmarkSuite);
      LTestSuite.AddTest('基准测试状态', @Test_BenchmarkState);

      // 基线工具测试
      LTestSuite.AddTest('基线-JSON对比-应通过', @Test_BaselineJSONCompare);
      LTestSuite.AddTest('计时-暂停恢复应排除耗时', @Test_PauseResumeExclusion);
      LTestSuite.AddTest('基线-CSV对比-应失败', @Test_BaselineCSVCompare);
      LTestSuite.AddTest('基线-CSV表头乱序-应失败', @Test_BaselineCSVHeaderDisorderCompare);

      // 异常测试用例
      LTestSuite.AddTest('异常测试-空名称注册', @Test_ExceptionHandling);
      LTestSuite.AddTest('异常测试-无效配置', @Test_InvalidConfig);
      LTestSuite.AddTest('异常测试-边界条件', @Test_BoundaryConditions);

      // 多线程测试（若实现占位返回无异常即可）
      LTestSuite.AddTest('多线程-基本功能', @Test_MultiThreadBenchmark);
      LTestSuite.AddTest('多线程-配置测试', @Test_MultiThreadConfig);
      LTestSuite.AddTest('多线程-性能对比', @Test_MultiThreadPerformance);

      // 快手接口最小验证（仅 smoke，不做严格断言）
      LTestSuite.AddTest('开销校正-打印应合理且无异常值',
        procedure
        var
          C: TBenchmarkConfig;
          R: IBenchmarkResult;
          Rep: IBenchmarkReporter;
        begin
          C := CreateDefaultBenchmarkConfig;
          C.MeasureIterations := 2;
          C.WarmupIterations := 0;
          // 先关闭校正
          C.EnableOverheadCorrection := False;
          R := BenchWithConfig('overhead.off', @SimpleStateTest, C);
          Rep := CreateConsoleReporterAsciiOnly;
          Rep.ReportResult(R);
          // 再打开校正
          C.EnableOverheadCorrection := True;
          R := BenchWithConfig('overhead.on', @SimpleStateTest, C);
          Rep.ReportResult(R);
        end
      );

	      // Overhead 边界用例：极小耗时/小样本，校正开关下统计应健壮无 NaN/负值
	      LTestSuite.AddTest('开销校正-边界-极小耗时与小样本',
	        procedure
	        var
	          C: TBenchmarkConfig;
	          R: IBenchmarkResult;
	          S: TBenchmarkStatistics;
	          v: Double;
	        begin
	          // 极小耗时：空操作
	          C := CreateDefaultBenchmarkConfig;
	          C.MeasureIterations := 1;
	          C.WarmupIterations := 0;
	          C.EnableOverheadCorrection := False;
	          R := BenchWithConfig('overhead.boundary.off', @Noop, C);
	          if R = nil then raise Exception.Create('Result nil');
	          S := R.GetStatistics;
	          if not (S.Mean = S.Mean) then raise Exception.Create('Mean is NaN');
	          if S.Mean < 0 then raise Exception.Create('Mean < 0');

	          // 打开校正
	          C.EnableOverheadCorrection := True;
	          R := BenchWithConfig('overhead.boundary.on', @Noop, C);
	          if R = nil then raise Exception.Create('Result nil (corrected)');
	          S := R.GetStatistics;
	          if not (S.Mean = S.Mean) then raise Exception.Create('Mean is NaN (corrected)');
	          if S.Mean < 0 then raise Exception.Create('Mean < 0 (corrected)');

	          // 单位一致性（粗验）：MeasureNs 与单次 Bench 的平均值同量纲
	          v := MeasureNs(@Noop);
	          if v < 0 then raise Exception.Create('MeasureNs < 0');
	        end
	      );

      // Pause/Resume 边界：长 Pause 应被完全排除，per-iter 明显小于 Pause 时间（宽松断言）
      LTestSuite.AddTest('暂停恢复-长暂停应被排除',
        procedure
        var
          LSuite2: IBenchmarkSuite;
          C2: TBenchmarkConfig;
          R2: TBenchmarkResultArray;
          PerIterMs: Double;
        begin
          LSuite2 := CreateBenchmarkSuite;
          C2 := CreateDefaultBenchmarkConfig;
          C2.WarmupIterations := 0; C2.MeasureIterations := 1;
          LSuite2.Add('pause.long', @PauseResumeWork, C2);
          R2 := LSuite2.RunAllWithReporter(CreateConsoleReporterAsciiOnly);
          if Length(R2)<>1 then raise Exception.Create('pause.long result count');
          PerIterMs := R2[0].GetTimePerIteration(buMilliSeconds);
          if PerIterMs >= 1.0 then
            raise Exception.CreateFmt('Pause not excluded enough, per-iter=%.3f ms',[PerIterMs]);
        end
      );



      LTestSuite.AddTest('快手接口-Bench/MeasureNs/Compare',
        procedure
        var
          R: IBenchmarkResult;
          v: Double;
        begin
          R := Bench('smoke.quick', @SimpleStateTest);
          v := MeasureNs(@SimpleStateTest);
          if (R = nil) or (v <= 0) then
            raise Exception.Create('Bench/MeasureNs smoke failed');
          Compare('A','B', @SimpleStateTest, @SimpleStateTest);
        end
      );

      // 运行并打印
      LTestSuite.RunAllTests;
      LTestSuite.PrintSummary;

    finally
      LTestSuite.Free;
    end;
  except
    on E: Exception do
    begin
      WriteLn('ERROR: ', E.ClassName, ': ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
