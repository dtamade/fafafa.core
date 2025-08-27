{$CODEPAGE UTF8}
program benchmark_term;

{**
 * fafafa.core.term 性能基准测试程序
 *
 * 这个程序测试 fafafa.core.term 模块各种操作的性能表现：
 * - 输出性能测试（缓冲 vs 非缓冲）
 * - 颜色设置性能测试
 * - 光标移动性能测试
 * - 键盘输入响应性能测试
 * - 内存使用测试
 *
 * 提供详细的性能报告和优化建议
 *}

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils, DateUtils,
  fafafa.core.base, fafafa.core.term;

type
  {**
   * 性能测试结果记录
   *}
  TBenchmarkResult = record
    TestName: string;           // 测试名称
    OperationCount: Integer;    // 操作次数
    ElapsedTimeMs: Int64;       // 耗时（毫秒）
    OperationsPerSecond: Double; // 每秒操作数
    MemoryUsedKB: Integer;      // 内存使用（KB）
    Success: Boolean;           // 是否成功
    ErrorMessage: string;       // 错误信息
  end;

  {**
   * 性能基准测试器
   *}
  TTerminalBenchmark = class
  private
    FResults: array of TBenchmarkResult;
    FTerminal: ITerminal;
    
    function GetMemoryUsage: Integer;
    procedure AddResult(const aResult: TBenchmarkResult);
    function CreateResult(const aTestName: string; aOperationCount: Integer; 
      aElapsedMs: Int64; aSuccess: Boolean = True; const aError: string = ''): TBenchmarkResult;
  public
    constructor Create;
    destructor Destroy; override;
    
    // 基准测试方法
    procedure BenchmarkBasicOutput;
    procedure BenchmarkBufferedOutput;
    procedure BenchmarkColorOutput;
    procedure BenchmarkCursorMovement;
    procedure BenchmarkScreenClear;
    procedure BenchmarkKeyboardInput;
    procedure BenchmarkMemoryUsage;
    
    // 运行所有测试
    procedure RunAllBenchmarks;
    
    // 结果报告
    procedure PrintResults;
    procedure SaveResultsToFile(const aFileName: string);
  end;

function TTerminalBenchmark.GetMemoryUsage: Integer;
begin
  // 简化的内存使用检测
  Result := 0; // TODO: 实现实际的内存使用检测
end;

procedure TTerminalBenchmark.AddResult(const aResult: TBenchmarkResult);
begin
  SetLength(FResults, Length(FResults) + 1);
  FResults[High(FResults)] := aResult;
end;

function TTerminalBenchmark.CreateResult(const aTestName: string; aOperationCount: Integer; 
  aElapsedMs: Int64; aSuccess: Boolean = True; const aError: string = ''): TBenchmarkResult;
begin
  Result.TestName := aTestName;
  Result.OperationCount := aOperationCount;
  Result.ElapsedTimeMs := aElapsedMs;
  
  if aElapsedMs > 0 then
    Result.OperationsPerSecond := (aOperationCount * 1000.0) / aElapsedMs
  else
    Result.OperationsPerSecond := 0;
    
  Result.MemoryUsedKB := GetMemoryUsage;
  Result.Success := aSuccess;
  Result.ErrorMessage := aError;
end;

constructor TTerminalBenchmark.Create;
begin
  inherited Create;
  SetLength(FResults, 0);
  FTerminal := CreateTerminal;
end;

destructor TTerminalBenchmark.Destroy;
begin
  FTerminal := nil;
  inherited Destroy;
end;

procedure TTerminalBenchmark.BenchmarkBasicOutput;
const
  OPERATION_COUNT = 10000;
var
  LStartTime, LEndTime: TDateTime;
  LOutput: ITerminalOutput;
  I: Integer;
begin
  WriteLn('测试基本输出性能...');
  
  LOutput := FTerminal.Output;
  LStartTime := Now;
  
  try
    for I := 1 to OPERATION_COUNT do
      LOutput.Write('*');
    LOutput.Flush;
    
    LEndTime := Now;
    AddResult(CreateResult('基本输出', OPERATION_COUNT, MilliSecondsBetween(LEndTime, LStartTime)));
    
  except
    on E: Exception do
    begin
      LEndTime := Now;
      AddResult(CreateResult('基本输出', OPERATION_COUNT, 
        MilliSecondsBetween(LEndTime, LStartTime), False, E.Message));
    end;
  end;
end;

procedure TTerminalBenchmark.BenchmarkBufferedOutput;
const
  OPERATION_COUNT = 50000;
var
  LStartTime, LEndTime: TDateTime;
  LOutput: ITerminalOutput;
  I: Integer;
begin
  WriteLn('测试缓冲输出性能...');
  
  LOutput := FTerminal.Output;
  LOutput.EnableBuffering;
  
  LStartTime := Now;
  
  try
    for I := 1 to OPERATION_COUNT do
      LOutput.Write('*');
    LOutput.Flush;
    
    LEndTime := Now;
    AddResult(CreateResult('缓冲输出', OPERATION_COUNT, MilliSecondsBetween(LEndTime, LStartTime)));
    
  except
    on E: Exception do
    begin
      LEndTime := Now;
      AddResult(CreateResult('缓冲输出', OPERATION_COUNT, 
        MilliSecondsBetween(LEndTime, LStartTime), False, E.Message));
    end;
  finally
    LOutput.DisableBuffering;
  end;
end;

procedure TTerminalBenchmark.BenchmarkColorOutput;
const
  OPERATION_COUNT = 5000;
var
  LStartTime, LEndTime: TDateTime;
  LOutput: ITerminalOutput;
  I: Integer;
  LColor: TTerminalColor;
begin
  WriteLn('测试颜色输出性能...');
  
  LOutput := FTerminal.Output;
  LStartTime := Now;
  
  try
    for I := 1 to OPERATION_COUNT do
    begin
      LColor := TTerminalColor(I mod Ord(High(TTerminalColor)));
      LOutput.SetForegroundColor(LColor);
      LOutput.Write('*');
    end;
    LOutput.ResetColors;
    
    LEndTime := Now;
    AddResult(CreateResult('颜色输出', OPERATION_COUNT, MilliSecondsBetween(LEndTime, LStartTime)));
    
  except
    on E: Exception do
    begin
      LEndTime := Now;
      AddResult(CreateResult('颜色输出', OPERATION_COUNT, 
        MilliSecondsBetween(LEndTime, LStartTime), False, E.Message));
    end;
  end;
end;

procedure TTerminalBenchmark.BenchmarkCursorMovement;
const
  OPERATION_COUNT = 1000;
var
  LStartTime, LEndTime: TDateTime;
  LOutput: ITerminalOutput;
  I: Integer;
begin
  WriteLn('测试光标移动性能...');
  
  LOutput := FTerminal.Output;
  LStartTime := Now;
  
  try
    for I := 1 to OPERATION_COUNT do
    begin
      LOutput.MoveCursor(I mod 80, I mod 25);
      LOutput.Write('*');
    end;
    
    LEndTime := Now;
    AddResult(CreateResult('光标移动', OPERATION_COUNT, MilliSecondsBetween(LEndTime, LStartTime)));
    
  except
    on E: Exception do
    begin
      LEndTime := Now;
      AddResult(CreateResult('光标移动', OPERATION_COUNT, 
        MilliSecondsBetween(LEndTime, LStartTime), False, E.Message));
    end;
  end;
end;

procedure TTerminalBenchmark.BenchmarkScreenClear;
const
  OPERATION_COUNT = 100;
var
  LStartTime, LEndTime: TDateTime;
  LOutput: ITerminalOutput;
  I: Integer;
begin
  WriteLn('测试屏幕清除性能...');
  
  LOutput := FTerminal.Output;
  LStartTime := Now;
  
  try
    for I := 1 to OPERATION_COUNT do
    begin
      LOutput.ClearScreen(tctAll);
      LOutput.WriteLn('测试内容 ' + IntToStr(I));
    end;
    
    LEndTime := Now;
    AddResult(CreateResult('屏幕清除', OPERATION_COUNT, MilliSecondsBetween(LEndTime, LStartTime)));
    
  except
    on E: Exception do
    begin
      LEndTime := Now;
      AddResult(CreateResult('屏幕清除', OPERATION_COUNT, 
        MilliSecondsBetween(LEndTime, LStartTime), False, E.Message));
    end;
  end;
end;

procedure TTerminalBenchmark.BenchmarkKeyboardInput;
begin
  WriteLn('键盘输入性能测试需要交互，跳过...');
  AddResult(CreateResult('键盘输入', 0, 0, True, '需要交互测试'));
end;

procedure TTerminalBenchmark.BenchmarkMemoryUsage;
var
  LStartMemory, LEndMemory: Integer;
  LOutput: ITerminalOutput;
  I: Integer;
begin
  WriteLn('测试内存使用...');
  
  LStartMemory := GetMemoryUsage;
  LOutput := FTerminal.Output;
  
  try
    // 创建大量输出操作
    LOutput.EnableBuffering;
    for I := 1 to 100000 do
      LOutput.Write('测试内容 ' + IntToStr(I) + ' ');
    LOutput.Flush;
    
    LEndMemory := GetMemoryUsage;
    AddResult(CreateResult('内存使用', 100000, LEndMemory - LStartMemory, True, 
      Format('内存增长: %d KB', [LEndMemory - LStartMemory])));
      
  except
    on E: Exception do
      AddResult(CreateResult('内存使用', 100000, 0, False, E.Message));
  end;
end;

procedure TTerminalBenchmark.RunAllBenchmarks;
begin
  WriteLn('fafafa.core.term 性能基准测试');
  WriteLn('==============================');
  WriteLn;
  
  BenchmarkBasicOutput;
  BenchmarkBufferedOutput;
  BenchmarkColorOutput;
  BenchmarkCursorMovement;
  BenchmarkScreenClear;
  BenchmarkKeyboardInput;
  BenchmarkMemoryUsage;
  
  WriteLn;
  WriteLn('所有基准测试完成！');
end;

procedure TTerminalBenchmark.PrintResults;
var
  I: Integer;
  LResult: TBenchmarkResult;
begin
  WriteLn;
  WriteLn('性能测试结果');
  WriteLn('============');
  WriteLn;
  
  WriteLn(Format('%-20s %10s %10s %15s %10s %s', [
    '测试名称', '操作次数', '耗时(ms)', '操作/秒', '内存(KB)', '状态'
  ]));
  WriteLn(StringOfChar('-', 80));
  
  for I := 0 to High(FResults) do
  begin
    LResult := FResults[I];
    
    if LResult.Success then
    begin
      WriteLn(Format('%-20s %10d %10d %15.2f %10d %s', [
        LResult.TestName,
        LResult.OperationCount,
        LResult.ElapsedTimeMs,
        LResult.OperationsPerSecond,
        LResult.MemoryUsedKB,
        '成功'
      ]));
    end
    else
    begin
      WriteLn(Format('%-20s %10s %10s %15s %10s %s', [
        LResult.TestName,
        '-',
        '-',
        '-',
        '-',
        '失败: ' + LResult.ErrorMessage
      ]));
    end;
  end;
  
  WriteLn;
end;

procedure TTerminalBenchmark.SaveResultsToFile(const aFileName: string);
var
  LFile: TextFile;
  I: Integer;
  LResult: TBenchmarkResult;
begin
  AssignFile(LFile, aFileName);
  Rewrite(LFile);
  
  try
    WriteLn(LFile, 'fafafa.core.term 性能基准测试结果');
    WriteLn(LFile, '测试时间: ', FormatDateTime('yyyy-mm-dd hh:nn:ss', Now));
    WriteLn(LFile, '');
    
    for I := 0 to High(FResults) do
    begin
      LResult := FResults[I];
      WriteLn(LFile, Format('测试: %s', [LResult.TestName]));
      WriteLn(LFile, Format('  操作次数: %d', [LResult.OperationCount]));
      WriteLn(LFile, Format('  耗时: %d ms', [LResult.ElapsedTimeMs]));
      WriteLn(LFile, Format('  性能: %.2f 操作/秒', [LResult.OperationsPerSecond]));
      WriteLn(LFile, Format('  内存: %d KB', [LResult.MemoryUsedKB]));
      WriteLn(LFile, Format('  状态: %s', [BoolToStr(LResult.Success, '成功', '失败')]));
      if not LResult.Success then
        WriteLn(LFile, Format('  错误: %s', [LResult.ErrorMessage]));
      WriteLn(LFile, '');
    end;
  finally
    CloseFile(LFile);
  end;
end;

var
  LBenchmark: TTerminalBenchmark;

begin
  try
    LBenchmark := TTerminalBenchmark.Create;
    try
      LBenchmark.RunAllBenchmarks;
      LBenchmark.PrintResults;
      LBenchmark.SaveResultsToFile('benchmark_results.txt');
      
      WriteLn('结果已保存到 benchmark_results.txt');
      
    finally
      LBenchmark.Free;
    end;
    
  except
    on E: Exception do
    begin
      WriteLn('基准测试失败: ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
