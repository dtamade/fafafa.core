program example_data_structures;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils, Classes, Generics.Collections,
  fafafa.core.base,
  fafafa.core.benchmark;

// 测试不同数据结构的性能

// 动态数组插入性能
procedure BenchmarkDynamicArrayInsert(aState: IBenchmarkState);
var
  LArray: array of Integer;
  LI: Integer;
begin
  while aState.KeepRunning do
  begin
    SetLength(LArray, 0);
    
    // 插入 1000 个元素
    for LI := 1 to 1000 do
    begin
      SetLength(LArray, Length(LArray) + 1);
      LArray[High(LArray)] := LI;
    end;
    
    // 设置处理的项目数
    aState.SetItemsProcessed(Length(LArray));
    aState.SetBytesProcessed(Length(LArray) * SizeOf(Integer));
  end;
end;

// TList 插入性能
procedure BenchmarkTListInsert(aState: IBenchmarkState);
var
  LList: TList;
  LI: Integer;
begin
  while aState.KeepRunning do
  begin
    LList := TList.Create;
    try
      // 插入 1000 个元素
      for LI := 1 to 1000 do
        LList.Add(Pointer(PtrInt(LI)));
      
      // 设置处理的项目数
      aState.SetItemsProcessed(LList.Count);
      aState.SetBytesProcessed(LList.Count * SizeOf(Pointer));
      
    finally
      LList.Free;
    end;
  end;
end;

// TStringList 操作性能
procedure BenchmarkTStringListOps(aState: IBenchmarkState);
var
  LStringList: TStringList;
  LI: Integer;
begin
  while aState.KeepRunning do
  begin
    LStringList := TStringList.Create;
    try
      // 添加 1000 个字符串
      for LI := 1 to 1000 do
        LStringList.Add('Item' + IntToStr(LI));
      
      // 排序
      LStringList.Sort;
      
      // 查找
      for LI := 1 to 100 do
        LStringList.IndexOf('Item' + IntToStr(LI * 10));
      
      // 设置处理的项目数
      aState.SetItemsProcessed(LStringList.Count);
      
      // 计算总字节数
      var LTotalBytes: Integer := 0;
      for LI := 0 to LStringList.Count - 1 do
        Inc(LTotalBytes, Length(LStringList[LI]));
      aState.SetBytesProcessed(LTotalBytes);
      
    finally
      LStringList.Free;
    end;
  end;
end;

// 泛型 TList<Integer> 性能
procedure BenchmarkGenericList(aState: IBenchmarkState);
var
  LList: TList<Integer>;
  LI: Integer;
begin
  while aState.KeepRunning do
  begin
    LList := TList<Integer>.Create;
    try
      // 插入 1000 个元素
      for LI := 1 to 1000 do
        LList.Add(LI);
      
      // 查找
      for LI := 1 to 100 do
        LList.IndexOf(LI * 10);
      
      // 设置处理的项目数
      aState.SetItemsProcessed(LList.Count);
      aState.SetBytesProcessed(LList.Count * SizeOf(Integer));
      
    finally
      LList.Free;
    end;
  end;
end;

// 数组访问性能对比
procedure BenchmarkArrayAccess(aState: IBenchmarkState);
var
  LStaticArray: array[0..9999] of Integer;
  LDynamicArray: array of Integer;
  LI, LSum: Integer;
begin
  // 初始化数组
  SetLength(LDynamicArray, 10000);
  for LI := 0 to 9999 do
  begin
    LStaticArray[LI] := LI;
    LDynamicArray[LI] := LI;
  end;
  
  while aState.KeepRunning do
  begin
    LSum := 0;
    
    // 静态数组访问
    for LI := 0 to 9999 do
      LSum := LSum + LStaticArray[LI];
    
    // 动态数组访问
    for LI := 0 to 9999 do
      LSum := LSum + LDynamicArray[LI];
    
    // 设置处理的项目数
    aState.SetItemsProcessed(20000); // 两个数组
    aState.SetBytesProcessed(20000 * SizeOf(Integer));
    
    // 添加计数器
    aState.AddCounter('计算结果', LSum, cuItems);
  end;
end;

// 哈希表性能测试
procedure BenchmarkHashMap(aState: IBenchmarkState);
var
  LDict: TDictionary<string, Integer>;
  LI: Integer;
  LKey: string;
  LValue: Integer;
begin
  while aState.KeepRunning do
  begin
    LDict := TDictionary<string, Integer>.Create;
    try
      // 插入 1000 个键值对
      for LI := 1 to 1000 do
      begin
        LKey := 'Key' + IntToStr(LI);
        LDict.Add(LKey, LI);
      end;
      
      // 查找操作
      for LI := 1 to 500 do
      begin
        LKey := 'Key' + IntToStr(LI * 2);
        LDict.TryGetValue(LKey, LValue);
      end;
      
      // 设置处理的项目数
      aState.SetItemsProcessed(LDict.Count + 500); // 插入 + 查找
      
      // 计算键的总字节数
      var LTotalBytes: Integer := 0;
      for LKey in LDict.Keys do
        Inc(LTotalBytes, Length(LKey));
      aState.SetBytesProcessed(LTotalBytes);
      
    finally
      LDict.Free;
    end;
  end;
end;

procedure RunDataStructureTests;
var
  LSuite: IBenchmarkSuite;
  LReporter: IBenchmarkReporter;
  LResults: TBenchmarkResultArray;
  LConfig: TBenchmarkConfig;
  LI: Integer;
begin
  WriteLn('=== 数据结构性能测试 ===');
  WriteLn;
  
  // 创建套件和配置
  LSuite := CreateBenchmarkSuite;
  LConfig := CreateDefaultBenchmarkConfig;
  LConfig.WarmupIterations := 2;
  LConfig.MeasureIterations := 5;
  LConfig.MinDurationMs := 200;
  
  // 添加数据结构测试
  LSuite.AddBenchmark(CreateLegacyBenchmark('动态数组插入', @BenchmarkDynamicArrayInsert, LConfig));
  LSuite.AddBenchmark(CreateLegacyBenchmark('TList插入', @BenchmarkTListInsert, LConfig));
  LSuite.AddBenchmark(CreateLegacyBenchmark('TStringList操作', @BenchmarkTStringListOps, LConfig));
  LSuite.AddBenchmark(CreateLegacyBenchmark('泛型List', @BenchmarkGenericList, LConfig));
  LSuite.AddBenchmark(CreateLegacyBenchmark('数组访问', @BenchmarkArrayAccess, LConfig));
  LSuite.AddBenchmark(CreateLegacyBenchmark('哈希表操作', @BenchmarkHashMap, LConfig));
  
  WriteLn('开始运行 ', LSuite.Count, ' 个数据结构性能测试...');
  WriteLn;
  
  // 运行所有测试
  LReporter := CreateConsoleReporter;
  LResults := LSuite.RunAllWithReporter(LReporter);
  
  WriteLn;
  WriteLn('=== 数据结构性能分析 ===');
  
  // 分析项目处理效率
  WriteLn('项目处理效率排名:');
  for LI := 0 to High(LResults) do
  begin
    var LItemsPerSec: Double := LResults[LI].GetItemsPerSecond;
    WriteLn('  ', LResults[LI].Name, ': ', Format('%.0f items/s', [LItemsPerSec]));
  end;
  
  WriteLn;
  WriteLn('内存吞吐量排名:');
  for LI := 0 to High(LResults) do
  begin
    var LThroughputMBps: Double := LResults[LI].GetBytesPerSecond / 1024 / 1024;
    WriteLn('  ', LResults[LI].Name, ': ', Format('%.2f MB/s', [LThroughputMBps]));
  end;
  
  WriteLn;
  WriteLn('操作延迟排名:');
  for LI := 0 to High(LResults) do
  begin
    var LLatencyUs: Double := LResults[LI].GetTimePerIteration(buMicroSeconds);
    WriteLn('  ', LResults[LI].Name, ': ', Format('%.2f μs/op', [LLatencyUs]));
  end;
end;

procedure CompareListTypes;
var
  LRunner: IBenchmarkRunner;
  LResult1, LResult2, LResult3: IBenchmarkResult;
  LConfig: TBenchmarkConfig;
  LReporter: IBenchmarkReporter;
begin
  WriteLn;
  WriteLn('=== 列表类型详细对比 ===');
  
  LRunner := CreateBenchmarkRunner;
  LConfig := CreateDefaultBenchmarkConfig;
  LConfig.WarmupIterations := 3;
  LConfig.MeasureIterations := 8;
  
  // 测试三种列表类型
  LResult1 := LRunner.RunFunction('动态数组详细测试', @BenchmarkDynamicArrayInsert, LConfig);
  LResult2 := LRunner.RunFunction('TList详细测试', @BenchmarkTListInsert, LConfig);
  LResult3 := LRunner.RunFunction('泛型List详细测试', @BenchmarkGenericList, LConfig);
  
  LReporter := CreateConsoleReporter;
  LReporter.ReportResult(LResult1);
  LReporter.ReportResult(LResult2);
  LReporter.ReportResult(LResult3);
  
  WriteLn;
  WriteLn('性能对比总结:');
  
  // 找出最快的
  var LFastest: IBenchmarkResult := LResult1;
  var LFastestName: string := '动态数组';
  
  if LResult2.GetTimePerIteration() < LFastest.GetTimePerIteration() then
  begin
    LFastest := LResult2;
    LFastestName := 'TList';
  end;
  
  if LResult3.GetTimePerIteration() < LFastest.GetTimePerIteration() then
  begin
    LFastest := LResult3;
    LFastestName := '泛型List';
  end;
  
  WriteLn('最快的列表类型: ', LFastestName);
  WriteLn('最快时间: ', Format('%.2f μs/op', [LFastest.GetTimePerIteration(buMicroSeconds)]));
end;

procedure SaveDataStructureReport;
var
  LRunner: IBenchmarkRunner;
  LResult: IBenchmarkResult;
  LConfig: TBenchmarkConfig;
  LJSONReporter: IBenchmarkReporter;
begin
  WriteLn;
  WriteLn('=== 保存数据结构性能报告 ===');
  
  LRunner := CreateBenchmarkRunner;
  LConfig := CreateDefaultBenchmarkConfig;
  LConfig.WarmupIterations := 2;
  LConfig.MeasureIterations := 10;
  
  // 运行详细的哈希表测试
  LResult := LRunner.RunFunction('哈希表详细测试', @BenchmarkHashMap, LConfig);
  
  // 保存 JSON 报告
  LJSONReporter := CreateJSONReporter('data_structures.json');
  LJSONReporter.ReportResult(LResult);
  WriteLn('数据结构性能报告已保存到: data_structures.json');
end;

begin
  WriteLn('========================================');
  WriteLn('数据结构性能测试示例');
  WriteLn('========================================');
  WriteLn;
  
  try
    RunDataStructureTests;
    CompareListTypes;
    SaveDataStructureReport;
    
    WriteLn;
    WriteLn('========================================');
    WriteLn('数据结构性能测试完成！');
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
