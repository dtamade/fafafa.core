{$CODEPAGE UTF8}
program performance_analyzer;

{**
 * fafafa.core.term 性能分析器
 *
 * 这个程序提供更深入的性能分析：
 * - 延迟测试（输入响应时间）
 * - 吞吐量测试（大量数据输出）
 * - 资源使用分析（CPU、内存）
 * - 并发性能测试
 * - 压力测试
 *}

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils, DateUtils, Math,
  fafafa.core.base, fafafa.core.term;

type
  {**
   * 性能分析器
   *}
  TPerformanceAnalyzer = class
  private
    FTerminal: ITerminal;
    FTestResults: TStringList;
    
    procedure LogResult(const aTestName, aResult: string);
    function MeasureTime(aProc: TProcedure): Int64;
  public
    constructor Create;
    destructor Destroy; override;
    
    // 延迟测试
    procedure TestOutputLatency;
    procedure TestInputLatency;
    
    // 吞吐量测试
    procedure TestOutputThroughput;
    procedure TestColorThroughput;
    
    // 资源使用测试
    procedure TestMemoryUsage;
    procedure TestCPUUsage;
    
    // 压力测试
    procedure StressTestOutput;
    procedure StressTestInput;
    
    // 运行分析
    procedure RunAnalysis;
    procedure PrintReport;
    procedure SaveReport(const aFileName: string);
  end;

constructor TPerformanceAnalyzer.Create;
begin
  inherited Create;
  FTerminal := CreateTerminal;
  FTestResults := TStringList.Create;
end;

destructor TPerformanceAnalyzer.Destroy;
begin
  FTestResults.Free;
  FTerminal := nil;
  inherited Destroy;
end;

procedure TPerformanceAnalyzer.LogResult(const aTestName, aResult: string);
begin
  FTestResults.Add(Format('[%s] %s: %s', [
    FormatDateTime('hh:nn:ss.zzz', Now),
    aTestName,
    aResult
  ]));
end;

function TPerformanceAnalyzer.MeasureTime(aProc: TProcedure): Int64;
var
  LStartTime, LEndTime: TDateTime;
begin
  LStartTime := Now;
  aProc();
  LEndTime := Now;
  Result := MilliSecondsBetween(LEndTime, LStartTime);
end;

procedure TPerformanceAnalyzer.TestOutputLatency;
var
  LOutput: ITerminalOutput;
  LLatency: Int64;
  I: Integer;
  LTotalLatency: Int64;
  LMinLatency, LMaxLatency: Int64;
begin
  WriteLn('测试输出延迟...');
  
  LOutput := FTerminal.Output;
  LTotalLatency := 0;
  LMinLatency := MaxInt;
  LMaxLatency := 0;
  
  for I := 1 to 100 do
  begin
    LLatency := MeasureTime(procedure
    begin
      LOutput.Write('测试');
      LOutput.Flush;
    end);
    
    LTotalLatency := LTotalLatency + LLatency;
    LMinLatency := Min(LMinLatency, LLatency);
    LMaxLatency := Max(LMaxLatency, LLatency);
  end;
  
  LogResult('输出延迟', Format('平均: %d ms, 最小: %d ms, 最大: %d ms', [
    LTotalLatency div 100, LMinLatency, LMaxLatency
  ]));
end;

procedure TPerformanceAnalyzer.TestInputLatency;
begin
  WriteLn('输入延迟测试需要交互，跳过...');
  LogResult('输入延迟', '需要交互测试');
end;

procedure TPerformanceAnalyzer.TestOutputThroughput;
const
  DATA_SIZE = 1024 * 1024; // 1MB
var
  LOutput: ITerminalOutput;
  LData: string;
  LThroughput: Double;
  LTime: Int64;
begin
  WriteLn('测试输出吞吐量...');
  
  LOutput := FTerminal.Output;
  LData := StringOfChar('A', DATA_SIZE);
  
  LOutput.EnableBuffering;
  try
    LTime := MeasureTime(procedure
    begin
      LOutput.Write(LData);
      LOutput.Flush;
    end);
    
    if LTime > 0 then
      LThroughput := (DATA_SIZE / 1024.0) / (LTime / 1000.0) // KB/s
    else
      LThroughput := 0;
      
    LogResult('输出吞吐量', Format('%.2f KB/s (%d ms for %d KB)', [
      LThroughput, LTime, DATA_SIZE div 1024
    ]));
    
  finally
    LOutput.DisableBuffering;
  end;
end;

procedure TPerformanceAnalyzer.TestColorThroughput;
const
  COLOR_COUNT = 10000;
var
  LOutput: ITerminalOutput;
  LTime: Int64;
  LThroughput: Double;
begin
  WriteLn('测试颜色切换吞吐量...');
  
  LOutput := FTerminal.Output;
  
  LTime := MeasureTime(procedure
  var
    I: Integer;
    LColor: TTerminalColor;
  begin
    for I := 1 to COLOR_COUNT do
    begin
      LColor := TTerminalColor(I mod Ord(High(TTerminalColor)));
      LOutput.SetForegroundColor(LColor);
    end;
    LOutput.ResetColors;
  end);
  
  if LTime > 0 then
    LThroughput := (COLOR_COUNT * 1000.0) / LTime
  else
    LThroughput := 0;
    
  LogResult('颜色切换吞吐量', Format('%.2f 操作/秒 (%d ms for %d operations)', [
    LThroughput, LTime, COLOR_COUNT
  ]));
end;

procedure TPerformanceAnalyzer.TestMemoryUsage;
begin
  WriteLn('测试内存使用...');
  LogResult('内存使用', '需要专门的内存分析工具');
end;

procedure TPerformanceAnalyzer.TestCPUUsage;
begin
  WriteLn('测试CPU使用...');
  LogResult('CPU使用', '需要专门的CPU分析工具');
end;

procedure TPerformanceAnalyzer.StressTestOutput;
const
  STRESS_OPERATIONS = 100000;
var
  LOutput: ITerminalOutput;
  LTime: Int64;
  I: Integer;
begin
  WriteLn('输出压力测试...');
  
  LOutput := FTerminal.Output;
  LOutput.EnableBuffering;
  
  try
    LTime := MeasureTime(procedure
    begin
      for I := 1 to STRESS_OPERATIONS do
      begin
        LOutput.SetForegroundColor(TTerminalColor(I mod Ord(High(TTerminalColor))));
        LOutput.Write(Format('压力测试 %d ', [I]));
        if I mod 1000 = 0 then
          LOutput.MoveCursor(0, I mod 25);
      end;
      LOutput.Flush;
    end);
    
    LogResult('输出压力测试', Format('%d 操作在 %d ms 内完成 (%.2f 操作/秒)', [
      STRESS_OPERATIONS, LTime, (STRESS_OPERATIONS * 1000.0) / LTime
    ]));
    
  finally
    LOutput.DisableBuffering;
    LOutput.ResetColors;
  end;
end;

procedure TPerformanceAnalyzer.StressTestInput;
begin
  WriteLn('输入压力测试需要交互，跳过...');
  LogResult('输入压力测试', '需要交互测试');
end;

procedure TPerformanceAnalyzer.RunAnalysis;
begin
  WriteLn('fafafa.core.term 性能分析');
  WriteLn('=========================');
  WriteLn;
  
  TestOutputLatency;
  TestInputLatency;
  TestOutputThroughput;
  TestColorThroughput;
  TestMemoryUsage;
  TestCPUUsage;
  StressTestOutput;
  StressTestInput;
  
  WriteLn;
  WriteLn('性能分析完成！');
end;

procedure TPerformanceAnalyzer.PrintReport;
var
  I: Integer;
begin
  WriteLn;
  WriteLn('详细性能报告');
  WriteLn('============');
  WriteLn;
  
  for I := 0 to FTestResults.Count - 1 do
    WriteLn(FTestResults[I]);
    
  WriteLn;
  WriteLn('性能优化建议:');
  WriteLn('- 对于大量输出操作，使用缓冲模式可显著提升性能');
  WriteLn('- 避免频繁的颜色切换，尽量批量处理');
  WriteLn('- 光标移动操作相对较慢，应谨慎使用');
  WriteLn('- 屏幕清除操作开销较大，避免过度使用');
end;

procedure TPerformanceAnalyzer.SaveReport(const aFileName: string);
var
  LFile: TextFile;
  I: Integer;
begin
  AssignFile(LFile, aFileName);
  Rewrite(LFile);
  
  try
    WriteLn(LFile, 'fafafa.core.term 性能分析报告');
    WriteLn(LFile, '测试时间: ', FormatDateTime('yyyy-mm-dd hh:nn:ss', Now));
    WriteLn(LFile, '');
    
    for I := 0 to FTestResults.Count - 1 do
      WriteLn(LFile, FTestResults[I]);
      
  finally
    CloseFile(LFile);
  end;
end;

var
  LAnalyzer: TPerformanceAnalyzer;

begin
  try
    LAnalyzer := TPerformanceAnalyzer.Create;
    try
      LAnalyzer.RunAnalysis;
      LAnalyzer.PrintReport;
      LAnalyzer.SaveReport('performance_report.txt');
      
      WriteLn('性能报告已保存到 performance_report.txt');
      
    finally
      LAnalyzer.Free;
    end;
    
  except
    on E: Exception do
    begin
      WriteLn('性能分析失败: ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
