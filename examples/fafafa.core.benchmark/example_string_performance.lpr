program example_string_performance;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils, Classes,
  fafafa.core.base,
  fafafa.core.benchmark;

// 测试不同字符串处理方法的性能

// 字符串连接 - 直接连接
procedure BenchmarkStringConcat(aState: IBenchmarkState);
var
  LResult: string;
  LI: Integer;
begin
  while aState.KeepRunning do
  begin
    LResult := '';
    
    // 连接 1000 个字符串
    for LI := 1 to 1000 do
      LResult := LResult + IntToStr(LI) + ',';
    
    // 设置处理的字节数和项目数
    aState.SetBytesProcessed(Length(LResult));
    aState.SetItemsProcessed(1000);
    
    // 添加自定义计数器
    aState.AddCounter('最终长度', Length(LResult), cuBytes);
  end;
end;

// 字符串连接 - 使用 TStringList
procedure BenchmarkStringListConcat(aState: IBenchmarkState);
var
  LStringList: TStringList;
  LResult: string;
  LI: Integer;
begin
  while aState.KeepRunning do
  begin
    LStringList := TStringList.Create;
    try
      LStringList.Delimiter := ',';
      LStringList.QuoteChar := #0;
      
      // 添加 1000 个字符串
      for LI := 1 to 1000 do
        LStringList.Add(IntToStr(LI));
      
      // 连接成一个字符串
      LResult := LStringList.DelimitedText;
      
      // 设置处理的字节数和项目数
      aState.SetBytesProcessed(Length(LResult));
      aState.SetItemsProcessed(1000);
      
    finally
      LStringList.Free;
    end;
  end;
end;

// 字符串查找 - Pos 函数
procedure BenchmarkStringSearch(aState: IBenchmarkState);
var
  LText: string;
  LSearchTerm: string;
  LPos: Integer;
  LI: Integer;
begin
  // 准备测试数据
  LText := '';
  for LI := 1 to 10000 do
    LText := LText + 'Hello World ' + IntToStr(LI) + ' ';
  
  LSearchTerm := 'World 5000';
  
  while aState.KeepRunning do
  begin
    // 查找字符串
    LPos := Pos(LSearchTerm, LText);
    
    // 设置处理的字节数
    aState.SetBytesProcessed(Length(LText));
    
    // 添加计数器
    aState.AddCounter('查找结果', LPos, cuItems);
  end;
end;

// 字符串替换性能
procedure BenchmarkStringReplace(aState: IBenchmarkState);
var
  LText: string;
  LResult: string;
  LI: Integer;
begin
  // 准备测试数据
  LText := '';
  for LI := 1 to 1000 do
    LText := LText + 'Hello World ' + IntToStr(LI) + ' ';
  
  while aState.KeepRunning do
  begin
    // 字符串替换
    LResult := StringReplace(LText, 'World', 'Pascal', [rfReplaceAll]);
    
    // 设置处理的字节数
    aState.SetBytesProcessed(Length(LText) + Length(LResult));
    
    // 添加计数器
    aState.AddCounter('原始长度', Length(LText), cuBytes);
    aState.AddCounter('结果长度', Length(LResult), cuBytes);
  end;
end;

// 字符串分割性能
procedure BenchmarkStringSplit(aState: IBenchmarkState);
var
  LText: string;
  LParts: TStringArray;
  LI: Integer;
begin
  // 准备测试数据
  LText := '';
  for LI := 1 to 1000 do
  begin
    if LI > 1 then LText := LText + ',';
    LText := LText + 'Item' + IntToStr(LI);
  end;
  
  while aState.KeepRunning do
  begin
    // 字符串分割
    LParts := LText.Split(',');
    
    // 设置处理的字节数和项目数
    aState.SetBytesProcessed(Length(LText));
    aState.SetItemsProcessed(Length(LParts));
    
    // 添加计数器
    aState.AddCounter('分割数量', Length(LParts), cuItems);
  end;
end;

// 字符串格式化性能
procedure BenchmarkStringFormat(aState: IBenchmarkState);
var
  LResult: string;
  LI: Integer;
begin
  while aState.KeepRunning do
  begin
    LResult := '';
    
    // 格式化 100 个字符串
    for LI := 1 to 100 do
      LResult := LResult + Format('Item %d: Value %.2f, Status %s' + sLineBreak, 
        [LI, LI * 3.14159, IIF(LI mod 2 = 0, 'Even', 'Odd')]);
    
    // 设置处理的字节数和项目数
    aState.SetBytesProcessed(Length(LResult));
    aState.SetItemsProcessed(100);
  end;
end;

// 字符串编码转换性能
procedure BenchmarkStringEncoding(aState: IBenchmarkState);
var
  LUTFText: string;
  LAnsiText: AnsiString;
  LI: Integer;
begin
  // 准备 UTF-8 文本
  LUTFText := '';
  for LI := 1 to 1000 do
    LUTFText := LUTFText + '测试文本' + IntToStr(LI) + ' ';
  
  while aState.KeepRunning do
  begin
    // UTF-8 到 ANSI 转换
    LAnsiText := AnsiString(LUTFText);
    
    // ANSI 到 UTF-8 转换
    LUTFText := string(LAnsiText);
    
    // 设置处理的字节数
    aState.SetBytesProcessed(Length(LUTFText) + Length(LAnsiText));
  end;
end;

procedure RunStringPerformanceTests;
var
  LSuite: IBenchmarkSuite;
  LReporter: IBenchmarkReporter;
  LResults: TBenchmarkResultArray;
  LConfig: TBenchmarkConfig;
  LI: Integer;
begin
  WriteLn('=== 字符串处理性能测试 ===');
  WriteLn;
  
  // 创建套件和配置
  LSuite := CreateBenchmarkSuite;
  LConfig := CreateDefaultBenchmarkConfig;
  LConfig.WarmupIterations := 2;
  LConfig.MeasureIterations := 5;
  LConfig.MinDurationMs := 300;
  
  // 添加字符串测试
  LSuite.AddBenchmark(CreateLegacyBenchmark('字符串直接连接', @BenchmarkStringConcat, LConfig));
  LSuite.AddBenchmark(CreateLegacyBenchmark('TStringList连接', @BenchmarkStringListConcat, LConfig));
  LSuite.AddBenchmark(CreateLegacyBenchmark('字符串查找', @BenchmarkStringSearch, LConfig));
  LSuite.AddBenchmark(CreateLegacyBenchmark('字符串替换', @BenchmarkStringReplace, LConfig));
  LSuite.AddBenchmark(CreateLegacyBenchmark('字符串分割', @BenchmarkStringSplit, LConfig));
  LSuite.AddBenchmark(CreateLegacyBenchmark('字符串格式化', @BenchmarkStringFormat, LConfig));
  LSuite.AddBenchmark(CreateLegacyBenchmark('编码转换', @BenchmarkStringEncoding, LConfig));
  
  WriteLn('开始运行 ', LSuite.Count, ' 个字符串性能测试...');
  WriteLn;
  
  // 运行所有测试
  LReporter := CreateConsoleReporter;
  LResults := LSuite.RunAllWithReporter(LReporter);
  
  WriteLn;
  WriteLn('=== 字符串性能分析 ===');
  
  // 分析字节处理吞吐量
  WriteLn('字节处理吞吐量排名:');
  for LI := 0 to High(LResults) do
  begin
    var LThroughputMBps: Double := LResults[LI].GetBytesPerSecond / 1024 / 1024;
    WriteLn('  ', LResults[LI].Name, ': ', Format('%.2f MB/s', [LThroughputMBps]));
  end;
  
  WriteLn;
  WriteLn('项目处理效率排名:');
  for LI := 0 to High(LResults) do
  begin
    var LItemsPerSec: Double := LResults[LI].GetItemsPerSecond;
    WriteLn('  ', LResults[LI].Name, ': ', Format('%.0f items/s', [LItemsPerSec]));
  end;
  
  WriteLn;
  WriteLn('操作延迟排名:');
  for LI := 0 to High(LResults) do
  begin
    var LLatencyUs: Double := LResults[LI].GetTimePerIteration(buMicroSeconds);
    WriteLn('  ', LResults[LI].Name, ': ', Format('%.2f μs/op', [LLatencyUs]));
  end;
end;

procedure TestStringConcatComparison;
var
  LRunner: IBenchmarkRunner;
  LResult1, LResult2: IBenchmarkResult;
  LConfig: TBenchmarkConfig;
  LReporter: IBenchmarkReporter;
begin
  WriteLn;
  WriteLn('=== 字符串连接方法对比 ===');
  
  LRunner := CreateBenchmarkRunner;
  LConfig := CreateDefaultBenchmarkConfig;
  LConfig.WarmupIterations := 3;
  LConfig.MeasureIterations := 8;
  
  // 测试直接连接
  LResult1 := LRunner.RunFunction('直接连接详细测试', @BenchmarkStringConcat, LConfig);
  
  // 测试 TStringList 连接
  LResult2 := LRunner.RunFunction('TStringList连接详细测试', @BenchmarkStringListConcat, LConfig);
  
  LReporter := CreateConsoleReporter;
  LReporter.ReportResult(LResult1);
  LReporter.ReportResult(LResult2);
  
  WriteLn;
  WriteLn('性能对比:');
  var LSpeedRatio: Double := LResult1.GetTimePerIteration() / LResult2.GetTimePerIteration();
  if LSpeedRatio > 1 then
    WriteLn('TStringList 比直接连接快 ', Format('%.2fx', [LSpeedRatio]))
  else
    WriteLn('直接连接比 TStringList 快 ', Format('%.2fx', [1/LSpeedRatio]));
end;

procedure SaveStringReport;
var
  LRunner: IBenchmarkRunner;
  LResult: IBenchmarkResult;
  LConfig: TBenchmarkConfig;
  LCSVReporter: IBenchmarkReporter;
begin
  WriteLn;
  WriteLn('=== 保存字符串性能报告 ===');
  
  LRunner := CreateBenchmarkRunner;
  LConfig := CreateDefaultBenchmarkConfig;
  LConfig.WarmupIterations := 2;
  LConfig.MeasureIterations := 10;
  
  // 运行详细的字符串查找测试
  LResult := LRunner.RunFunction('字符串查找详细测试', @BenchmarkStringSearch, LConfig);
  
  // 保存 CSV 报告
  LCSVReporter := CreateCSVReporter('string_performance.csv');
  LCSVReporter.ReportResult(LResult);
  WriteLn('字符串性能报告已保存到: string_performance.csv');
end;

begin
  WriteLn('========================================');
  WriteLn('字符串处理性能测试示例');
  WriteLn('========================================');
  WriteLn;
  
  try
    RunStringPerformanceTests;
    TestStringConcatComparison;
    SaveStringReport;
    
    WriteLn;
    WriteLn('========================================');
    WriteLn('字符串性能测试完成！');
    WriteLn('========================================');
    
  except
    on E: Exception do
    begin
      WriteLn('示例运行出错: ', E.Message);
      ExitCode := 1;
    end;
  end;
  
  WriteLn;
  WriteLn('按回车键退出...');
  ReadLn;
end.
