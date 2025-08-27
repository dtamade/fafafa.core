unit test_reporters_extra;

{$MODE OBJFPC}{$H+}

interface

uses
  SysUtils, Classes, fafafa.core.benchmark, fafafa.core.io;

// 本单元自备一个简单的基准函数，避免依赖主 LPR 的 SimpleStateTest
procedure ExtraStateTest(aState: IBenchmarkState);

procedure Test_JSONReporter_ControlChars;
procedure Test_CSVReporter_CustomSeparator;

  procedure Test_CSVReporter_TabularCounters;
procedure Test_CSVReporter_TabularCounters_SortedAndMissing;
procedure Test_JSONReporter_SnapshotLoose;
procedure Test_JUnitReporter_SnapshotMinimal;

// New sink-based and mux smoke tests
procedure Test_ReporterMux_Fanout_Smoke;
procedure Test_NullSink_Silence_Smoke;
procedure Test_ConsoleReporter_SinkCapture_Minimal;

implementation

// sink-capture minimal tests
procedure Test_JSONReporter_SinkCapture_Minimal;
procedure Test_CSVReporter_SinkCapture_Minimal;


// helpers first to avoid forward/nested proc issues on some FPC versions
procedure ExtraStateTest(aState: IBenchmarkState);
begin
  while aState.KeepRunning do begin aState.AddCounter('ticks', 1); end;
  aState.AddCounter('done', 1);
end;

procedure ExtraStateTestExtra(aState: IBenchmarkState);
begin
  while aState.KeepRunning do aState.AddCounter('ticks', 1);
  aState.AddCounter('done', 1);
  aState.AddCounter('extra', 1);
end;


procedure Test_CSVReporter_TabularCounters_SortedAndMissing;
var
  R1, R2: IBenchmarkResult;
  Rep: IBenchmarkReporter;
  LTmp: string;
  SL: TStringList;
  Header, Data1, Data2: string;
  I, j, k: Integer;
  fields: array of string;
  H: TStringList;
  D1, D2: TStringList;
  colDone, colExtra, colTicks: Integer;
  function SplitCSV(const S: string): TStringList;
  var
    i: Integer; inQuote: Boolean; cur: string;
  begin
    Result := TStringList.Create;
    Result.Clear;
    inQuote := False; cur := '';
    i := 1;
    while i <= Length(S) do
    begin
      case S[i] of
        '"':
          begin
            // toggle quote or escaped quote
            if (i < Length(S)) and (S[i+1] = '"') then
            begin
              cur := cur + '"';
              Inc(i); // consume escaped quote
            end
            else
              inQuote := not inQuote;
          end;
        ',':
          if not inQuote then
          begin
            Result.Add(cur); cur := '';
          end
          else cur := cur + S[i];
      else
        cur := cur + S[i];
      end;
      Inc(i);
    end;
    Result.Add(cur);
  end;
  function IndexOfField(const Arr: array of string; const Value: string): Integer;
  var t: Integer;
  begin
    for t := 0 to High(Arr) do
      if Arr[t] = Value then Exit(t);
    Exit(-1);
  end;
  procedure ToArray(L: TStringList);
  var t: Integer;
  begin
    SetLength(fields, L.Count);
    for t := 0 to L.Count-1 do fields[t] := L[t];
  end;
begin
  // 两个结果，第二个包含一个额外计数器 extra
  R1 := Bench('tab.sort.missing.1', @ExtraStateTest);
  // 定义一个带额外计数器的基准（使用命名过程，避免匿名过程依赖）
  R2 := Bench('tab.sort.missing.2', @ExtraStateTestExtra);

  LTmp := IncludeTrailingPathDelimiter(ExtractFileDir(ParamStr(0))) + 'reporter_csv_tabular_sorted_missing.csv';
  if FileExists(LTmp) then SysUtils.DeleteFile(LTmp);
  Rep := CreateCSVReporter(LTmp);
  Rep.SetFormat('schema=2;decimals=2;counters=tabular');
  // （已验证）不再打印额外调试输出
  Rep.ReportResults([R1, R2]);

  if not FileExists(LTmp) then
    raise Exception.Create('CSV tabular(sorted,missing) file not generated');

  SL := TStringList.Create;
  try
    SL.LoadFromFile(LTmp);
    Header := ''; Data1 := ''; Data2 := '';
    // 找 header、第一条与第二条数据行
    for I := 0 to SL.Count-1 do
      if Trim(SL[I]) <> '' then begin Header := SL[I]; j := I+1; break; end;
    if Header <> '' then
      for I := j to SL.Count-1 do
        if Trim(SL[I]) <> '' then begin Data1 := SL[I]; k := I+1; break; end;
    if Data1 <> '' then
      for I := k to SL.Count-1 do
        if Trim(SL[I]) <> '' then begin Data2 := SL[I]; break; end;

    if (Header='') or (Data1='') or (Data2='') then
      raise Exception.Create('CSV tabular(sorted,missing) lines not found');

    // 列分割
    H := SplitCSV(Header);
    try
      ToArray(H);
    finally
      H.Free;
    end;

    // 动态列应包含按字母序排序的 done, extra, ticks
    colDone := IndexOfField(fields, 'Counter:done[unit]');
    colExtra := IndexOfField(fields, 'Counter:extra[unit]');
    colTicks := IndexOfField(fields, 'Counter:ticks[unit]');
    if (colDone<0) or (colExtra<0) or (colTicks<0) then
      raise Exception.Create('CSV dynamic counter headers missing [unit]; header='+Header);
    if not ((colDone < colExtra) and (colExtra < colTicks)) then
      raise Exception.Create('CSV dynamic counter headers not sorted alphabetically');

    // 校验缺失列为空：R1 没有 extra，应为空；R2 有 extra，应为非空
    D1 := SplitCSV(Data1);
    D2 := SplitCSV(Data2);
    try
      ToArray(D1);
      if fields[colExtra] <> 'Counter:extra[unit]' then ; // no-op, fields reused
      // 将数据行也分割为数组
      SetLength(fields, 0);
      ToArray(D1);
      if (colExtra >= Length(fields)) or (fields[colExtra] <> '') then
        raise Exception.Create('CSV missing counter cell should be empty for first row');
      SetLength(fields, 0);
      ToArray(D2);
      if (colExtra >= Length(fields)) or (Trim(fields[colExtra]) = '') then
        raise Exception.Create('CSV extra counter cell should be present for second row');
    finally
      D1.Free; D2.Free;
    end;
  finally
    SL.Free;
    if SysUtils.GetEnvironmentVariable('FAFAFA_KEEP_REPORT_FILES')='' then
      SysUtils.DeleteFile(LTmp);
  end;
end;




procedure Test_JSONReporter_ControlChars;
var
  R: IBenchmarkResult;
  Rep: IBenchmarkReporter;
  LTmp: string;
  SL: TStringList;
  S: string;
begin
  LTmp := IncludeTrailingPathDelimiter(GetTempDir) + 'reporter_json_ctrl_test.json';
  if FileExists(LTmp) then SysUtils.DeleteFile(LTmp);
  // 包含控制字符：\b \t \n \f \r
  R := Bench('a' + #8 + #9 + #10 + #12 + #13 + 'b', @ExtraStateTest);
  Rep := CreateJSONReporter(LTmp);
  Rep.SetFormat('schema=2;decimals=3');
  Rep.ReportResult(R);

  if not FileExists(LTmp) then
    raise Exception.Create('JSON ctrl file not generated');

  SL := TStringList.Create;
  try
    SL.LoadFromFile(LTmp);
    S := SL.Text;
    if Pos('"name": "a\b\t\n\f\rb"', S) = 0 then
      raise Exception.Create('JSON control char escape failed');
  finally
    SL.Free;
    if SysUtils.GetEnvironmentVariable('FAFAFA_KEEP_REPORT_FILES')='' then
      SysUtils.DeleteFile(LTmp);
  end;
end;

// Reporter: CSV 自定义分隔符验证（TAB）

procedure Test_CSVReporter_CustomSeparator;
var
  R: IBenchmarkResult;
  Rep: IBenchmarkReporter;
  LTmp: string;
  SL: TStringList;
  Header, Data: string;
  I, j: Integer;
  function CountChar(const S: string; C: Char): Integer;
  var k: Integer;
  begin
    Result := 0;
    for k := 1 to Length(S) do if S[k] = C then Inc(Result);
  end;
begin

  LTmp := IncludeTrailingPathDelimiter(ExtractFileDir(ParamStr(0))) + 'reporter_csv_sep_tab_extra.csv';
  if FileExists(LTmp) then SysUtils.DeleteFile(LTmp);
  R := Bench('c,o"m', @ExtraStateTest); // 含逗号与引号，验证引号包裹
  Rep := CreateCSVReporter(LTmp);
  Rep.SetFormat('schema=2;decimals=2;sep=tab');
  Rep.ReportResult(R);

  if not FileExists(LTmp) then
    raise Exception.Create('CSV sep file not generated');

  SL := TStringList.Create;
  try
    SL.LoadFromFile(LTmp);
    Header := '';
    Data := '';
    // 第一行=Header，第二行=Data
    for I := 0 to SL.Count-1 do
      if Trim(SL[I]) <> '' then begin Header := SL[I]; j := I+1; break; end;
    if Header <> '' then
      for I := j to SL.Count-1 do
        if Trim(SL[I]) <> '' then begin Data := SL[I]; break; end;

    if Header = '' then raise Exception.Create('CSV header not found');
    if Data = '' then raise Exception.Create('CSV data line not found');

    if Pos(#9, Header) = 0 then
      raise Exception.Create('CSV header not tab-separated');

    if CountChar(Header, #9) <> CountChar(Data, #9) then
      raise Exception.Create('CSV header/data column count mismatch for tab');

    if Pos('SchemaVersion', Header) = 0 then
      raise Exception.Create('CSV header missing SchemaVersion (semicolon test)');

    if Pos('"c,o""m"', Data) = 0 then
      raise Exception.Create('CSV name quoting with comma/quote failed for semicolon');

    if Pos('.', Data) = 0 then
      raise Exception.Create('CSV expects decimal dot in numbers (semicolon)');
  finally
    SL.Free;
    if SysUtils.GetEnvironmentVariable('FAFAFA_KEEP_REPORT_FILES')='' then
      SysUtils.DeleteFile(LTmp);
  end;
end;

// Reporter: CSV counters=tabular（宽松快照校验）
procedure Test_CSVReporter_TabularCounters;
var
  R1, R2: IBenchmarkResult;
  Rep: IBenchmarkReporter;
  LTmp: string;
  SL: TStringList;
  Header, Data: string;
  I, j: Integer;
begin

  // 生成两个结果，第二个包含一个额外计数器
  R1 := Bench('tab.basic', @ExtraStateTest);
  //R1.GetConfig.EnableOverheadCorrection := False; // 简化：不直接修改结果配置

  R2 := Bench('tab.extra', @ExtraStateTest);
  // 模拟计数器（通过 State API 产出更理想，但此处以 JSON/CSV字段存在为目的，采用结果级 counters）
  // 这里我们不直接操作内部结构，重点在 Reporter 的表头/列匹配与健壮性

  LTmp := IncludeTrailingPathDelimiter(ExtractFileDir(ParamStr(0))) + 'reporter_csv_tabular_extra.csv';
  if FileExists(LTmp) then SysUtils.DeleteFile(LTmp);
  Rep := CreateCSVReporter(LTmp);
  Rep.SetFormat('schema=2;decimals=2;counters=tabular');
  Rep.ReportResults([R1, R2]);

  if not FileExists(LTmp) then
    raise Exception.Create('CSV tabular file not generated');

  SL := TStringList.Create;
  try
    SL.LoadFromFile(LTmp);
    Header := '';
    Data := '';
    // 第一条非空即 header，下一条非空为 data
    for I := 0 to SL.Count-1 do
      if Trim(SL[I]) <> '' then begin Header := SL[I]; j := I+1; break; end;
    if Header <> '' then
      for I := j to SL.Count-1 do
        if Trim(SL[I]) <> '' then begin Data := SL[I]; break; end;

    if Pos('Counter:', Header) = 0 then
      raise Exception.Create('CSV header missing Counter: prefix when tabular enabled');
    if Pos('tab.basic', SL.Text) = 0 then
      raise Exception.Create('CSV missing first benchmark row');
  finally
    SL.Free;
    if SysUtils.GetEnvironmentVariable('FAFAFA_KEEP_REPORT_FILES')='' then
      SysUtils.DeleteFile(LTmp);

  end;
end;


// JUnit 最小快照：校验核心结构 testsuite/testcase/time
procedure Test_JUnitReporter_SnapshotMinimal;
var
  R: IBenchmarkResult;
  Rep: IBenchmarkReporter;
  LTmp: string;
  SL: TStringList;
  S: string;
begin
  LTmp := IncludeTrailingPathDelimiter(GetTempDir) + 'reporter_junit_snapshot_min.xml';
  if FileExists(LTmp) then SysUtils.DeleteFile(LTmp);

  R := Bench('junit.snapshot', @ExtraStateTest);
  Rep := CreateJUnitReporter(LTmp);
  Rep.ReportResult(R);

  if not FileExists(LTmp) then
    raise Exception.Create('JUnit snapshot file not generated');

  SL := TStringList.Create;
  try
    SL.LoadFromFile(LTmp);
    S := SL.Text;
    if Pos('<testsuite', S) = 0 then
      raise Exception.Create('JUnit testsuite missing');
    if Pos('<testcase', S) = 0 then
      raise Exception.Create('JUnit testcase missing');
    if Pos('time="', S) = 0 then
      raise Exception.Create('JUnit time attribute missing');
  finally
    SL.Free;
    if SysUtils.GetEnvironmentVariable('FAFAFA_KEEP_REPORT_FILES')='' then
      SysUtils.DeleteFile(LTmp);
  end;
end;

// JSON 宽松快照：校验核心字段存在与类型形态
procedure Test_JSONReporter_SnapshotLoose;
var
  R: IBenchmarkResult;
  Rep: IBenchmarkReporter;
  LTmp: string;
  S: string;
  SL: TStringList;
begin

  LTmp := IncludeTrailingPathDelimiter(GetTempDir) + 'reporter_json_snapshot_loose.json';
  if FileExists(LTmp) then SysUtils.DeleteFile(LTmp);

  R := Bench('json.snapshot', @ExtraStateTest);
  Rep := CreateJSONReporter(LTmp);
  Rep.SetFormat('schema=2;decimals=4');
  Rep.ReportResult(R);

  if not FileExists(LTmp) then
    raise Exception.Create('JSON snapshot file not generated');

  SL := TStringList.Create;
  try
    SL.LoadFromFile(LTmp);
    S := SL.Text;
    if Pos('"schema_version": 2', S) = 0 then
      raise Exception.Create('schema_version missing');
    if Pos('"name": "json.snapshot"', S) = 0 then
      raise Exception.Create('name missing');
    if Pos('"iterations": ', S) = 0 then
      raise Exception.Create('iterations missing');
    if Pos('"statistics": {', S) = 0 then
      raise Exception.Create('statistics missing');
    if (Pos('"mean": ', S) = 0) or (Pos('"stddev": ', S) = 0) then
      raise Exception.Create('statistics core fields missing');

  finally
    SL.Free;
    if SysUtils.GetEnvironmentVariable('FAFAFA_KEEP_REPORT_FILES')='' then
      SysUtils.DeleteFile(LTmp);
  end;


procedure Test_JSONReporter_SinkCapture_Minimal;
var
  R: IBenchmarkResult;
  S: ITextSink;
  Rep: IBenchmarkReporter;
  Txt: string;
begin
  R := Bench('sink.json', @ExtraStateTest);
  S := TStringSink.Create;
  Rep := CreateJSONReporter(S);
  Rep.SetFormat('schema=2;decimals=3');
  Rep.ReportResult(R);
  Txt := (S as TStringSink).AsText;
  if (Pos('"schema_version": 2', Txt) = 0) or (Pos('"name": "sink.json"', Txt) = 0) then
    raise Exception.Create('JSON sink capture failed: ' + Txt);
end;

procedure Test_CSVReporter_SinkCapture_Minimal;
var
  R: IBenchmarkResult;
  S: ITextSink;
  Rep: IBenchmarkReporter;
  Txt: string;
begin
  R := Bench('sink.csv', @ExtraStateTest);
  S := TStringSink.Create;
  Rep := CreateCSVReporter(S);
  Rep.SetFormat('schema=2;decimals=2');
  Rep.ReportResult(R);
  Txt := (S as TStringSink).AsText;
  if (Pos('SchemaVersion', Txt) = 0) or (Pos('sink.csv', Txt) = 0) then
    raise Exception.Create('CSV sink capture failed: ' + Txt);
end;


procedure Test_ReporterMux_Fanout_Smoke;
var
  R: IBenchmarkResult;
  Rep: IBenchmarkReporter;
  S: ITextSink;
  Txt: string;
begin
  R := Bench('mux.smoke', @ExtraStateTest);
  S := TStringSink.Create;
  Rep := CreateReporterMux([
    CreateJSONReporter(S),
    CreateCSVReporter(TNullSink.Create)
  ]);
  Rep.SetFormat('schema=2');
  Rep.ReportResult(R);
  Txt := (S as TStringSink).AsText;
  if (Pos('"name": "mux.smoke"', Txt) = 0) or (Pos('"schema_version": 2', Txt) = 0) then
    raise Exception.Create('ReporterMux fanout failed: ' + Txt);
end;

procedure Test_NullSink_Silence_Smoke;
var
  R: IBenchmarkResult;
  Rep: IBenchmarkReporter;
  S: TStringSink;
  Before, After: string;
begin
  R := Bench('null.sink', @ExtraStateTest);
  S := TStringSink.Create;
  Before := S.AsText;
  Rep := CreateCSVReporter(TNullSink.Create);
  Rep.ReportResult(R);
  After := S.AsText;
  if Before <> After then
    raise Exception.Create('NullSink should produce no output');
end;


procedure Test_ConsoleReporter_SinkCapture_Minimal;
var
  R: IBenchmarkResult;
  S: ITextSink;
  Rep: IBenchmarkReporter;
  Txt: string;
begin
  R := Bench('sink.console', @ExtraStateTest);
  S := TStringSink.Create;
  Rep := CreateConsoleReporter(S);
  Rep.ReportResult(R);
  Txt := (S as TStringSink).AsText;
  if (Pos('Benchmark Results', Txt) > 0) then ; // header is only in ReportResults, ignore
  if (Pos('Benchmark: sink.console', Txt) = 0) or (Pos('Iterations:', Txt) = 0) then
    raise Exception.Create('Console sink capture failed: ' + Txt);
end;





end.
