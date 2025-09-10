{$CODEPAGE UTF8}
unit fafafa.core.sync.sem.benchmark;

{$include fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes,
  fafafa.core.base, fafafa.core.sync.base, fafafa.core.sync.sem.base;

type
  TBenchmarkThread = class(TThread)
  private
    FSemaphore: ISem;
    FIterations: Integer;
    FThreadIndex: Integer;
    FAcquireTime: Double;
    FReleaseTime: Double;
    FTotalTime: Double;
    function GetCurrentTimeMs: Double;
  protected
    procedure Execute; override;
  public
    constructor Create(ASemaphore: ISem; AIterations, AThreadIndex: Integer);
    property AcquireTime: Double read FAcquireTime;
    property ReleaseTime: Double read FReleaseTime;
    property TotalTime: Double read FTotalTime;
  end;

  TSemaphoreBenchmark = class
  private
    FSemaphore: ISem;
    FIterations: Integer;
    FThreadCount: Integer;

    function GetCurrentTimeMs: Double;
  public
    constructor Create(AInitialCount, AMaxCount: Integer; AIterations: Integer = 10000; AThreadCount: Integer = 4);
    destructor Destroy; override;

    procedure RunBasicOperations;
    procedure RunConcurrentAccess;
    procedure RunTimeoutBehavior;
    procedure RunBatchOperations;
  end;

implementation

uses
  {$IFDEF WINDOWS}
  {$ELSE}
  BaseUnix, Unix,
  {$ENDIF}
  fafafa.core.sync.sem;

// TBenchmarkThread implementation

constructor TBenchmarkThread.Create(ASemaphore: ISem; AIterations, AThreadIndex: Integer);
begin
  inherited Create(False);
  FSemaphore := ASemaphore;
  FIterations := AIterations;
  FThreadIndex := AThreadIndex;
  FAcquireTime := 0;
  FReleaseTime := 0;
  FTotalTime := 0;
end;

function TBenchmarkThread.GetCurrentTimeMs: Double;
{$IFDEF WINDOWS}
begin
  Result := GetTickCount64;
{$ELSE}
var
  tv: TTimeVal;
begin
  fpgettimeofday(@tv, nil);
  Result := tv.tv_sec * 1000.0 + tv.tv_usec / 1000.0;
{$ENDIF}
end;

procedure TBenchmarkThread.Execute;
var
  i: Integer;
  StartTime, AcquireStart, AcquireEnd, ReleaseStart, ReleaseEnd: Double;
  TotalAcquireTime, TotalReleaseTime: Double;
begin
  TotalAcquireTime := 0;
  TotalReleaseTime := 0;
  StartTime := GetCurrentTimeMs;

  for i := 1 to FIterations do
  begin
    // 测量获取时间
    AcquireStart := GetCurrentTimeMs;
    FSemaphore.Acquire;
    AcquireEnd := GetCurrentTimeMs;
    TotalAcquireTime := TotalAcquireTime + (AcquireEnd - AcquireStart);

    // 模拟一些工作
    Sleep(0);

    // 测量释放时间
    ReleaseStart := GetCurrentTimeMs;
    FSemaphore.Release;
    ReleaseEnd := GetCurrentTimeMs;
    TotalReleaseTime := TotalReleaseTime + (ReleaseEnd - ReleaseStart);
  end;

  FAcquireTime := TotalAcquireTime;
  FReleaseTime := TotalReleaseTime;
  FTotalTime := GetCurrentTimeMs - StartTime;
end;

// TSemaphoreBenchmark implementation

constructor TSemaphoreBenchmark.Create(AInitialCount, AMaxCount: Integer; AIterations: Integer; AThreadCount: Integer);
begin
  inherited Create;
  FSemaphore := MakeSemaphore(AInitialCount, AMaxCount);
  FIterations := AIterations;
  FThreadCount := AThreadCount;
  SetLength(FResults, FThreadCount);
end;

destructor TSemaphoreBenchmark.Destroy;
begin
  FSemaphore := nil;
  inherited Destroy;
end;

function TSemaphoreBenchmark.GetCurrentTimeMs: Double;
{$IFDEF WINDOWS}
begin
  Result := GetTickCount64;
{$ELSE}
var
  tv: TTimeVal;
begin
  fpgettimeofday(@tv, nil);
  Result := tv.tv_sec * 1000.0 + tv.tv_usec / 1000.0;
{$ENDIF}
end;



procedure TSemaphoreBenchmark.RunBasicOperations;
var
  StartTime, EndTime: Double;
  i: Integer;
begin
  WriteLn('=== 基本操作性能测试 ===');
  WriteLn(Format('迭代次数: %d', [FIterations]));
  
  StartTime := GetCurrentTimeMs;
  for i := 1 to FIterations do
  begin
    FSemaphore.Acquire;
    FSemaphore.Release;
  end;
  EndTime := GetCurrentTimeMs;
  
  WriteLn(Format('总时间: %.2f ms', [EndTime - StartTime]));
  WriteLn(Format('平均每次操作: %.4f ms', [(EndTime - StartTime) / FIterations]));
  WriteLn(Format('每秒操作数: %.0f ops/sec', [FIterations * 1000.0 / (EndTime - StartTime)]));
  WriteLn;
end;

procedure TSemaphoreBenchmark.RunConcurrentAccess;
var
  Threads: array of TBenchmarkThread;
  i: Integer;
  StartTime, EndTime: Double;
  TotalAcquireTime, TotalReleaseTime: Double;
begin
  WriteLn('=== 并发访问性能测试 ===');
  WriteLn(Format('线程数: %d, 每线程迭代: %d', [FThreadCount, FIterations]));

  SetLength(Threads, FThreadCount);
  StartTime := GetCurrentTimeMs;

  // 启动所有线程
  for i := 0 to FThreadCount - 1 do
  begin
    Threads[i] := TBenchmarkThread.Create(FSemaphore, FIterations, i);
  end;

  // 等待所有线程完成
  for i := 0 to FThreadCount - 1 do
  begin
    Threads[i].WaitFor;
  end;

  EndTime := GetCurrentTimeMs;

  // 计算统计信息
  TotalAcquireTime := 0;
  TotalReleaseTime := 0;
  for i := 0 to FThreadCount - 1 do
  begin
    TotalAcquireTime := TotalAcquireTime + Threads[i].AcquireTime;
    TotalReleaseTime := TotalReleaseTime + Threads[i].ReleaseTime;
  end;

  // 清理线程
  for i := 0 to FThreadCount - 1 do
    Threads[i].Free;

  WriteLn(Format('总时间: %.2f ms', [EndTime - StartTime]));
  WriteLn(Format('总操作数: %d', [FThreadCount * FIterations]));
  WriteLn(Format('平均获取时间: %.4f ms', [TotalAcquireTime / (FThreadCount * FIterations)]));
  WriteLn(Format('平均释放时间: %.4f ms', [TotalReleaseTime / (FThreadCount * FIterations)]));
  WriteLn(Format('吞吐量: %.0f ops/sec', [FThreadCount * FIterations * 1000.0 / (EndTime - StartTime)]));
  WriteLn;
end;

procedure TSemaphoreBenchmark.RunTimeoutBehavior;
var
  StartTime, EndTime: Double;
  i: Integer;
  Success: Boolean;
begin
  WriteLn('=== 超时行为性能测试 ===');
  WriteLn(Format('测试次数: %d', [1000]));
  
  // 先获取所有信号量，使后续获取必然超时
  FSemaphore.Acquire;
  
  StartTime := GetCurrentTimeMs;
  for i := 1 to 1000 do
  begin
    Success := FSemaphore.TryAcquire(1); // 1ms 超时
    if Success then
      FSemaphore.Release; // 不应该发生
  end;
  EndTime := GetCurrentTimeMs;
  
  FSemaphore.Release; // 恢复状态
  
  WriteLn(Format('总时间: %.2f ms', [EndTime - StartTime]));
  WriteLn(Format('平均超时检测时间: %.4f ms', [(EndTime - StartTime) / 1000]));
  WriteLn;
end;

procedure TSemaphoreBenchmark.RunBatchOperations;
var
  StartTime, EndTime: Double;
  i: Integer;
  BatchSize: Integer;
begin
  WriteLn('=== 批量操作性能测试 ===');
  BatchSize := 10;
  WriteLn(Format('批量大小: %d, 测试次数: %d', [BatchSize, 1000]));
  
  StartTime := GetCurrentTimeMs;
  for i := 1 to 1000 do
  begin
    FSemaphore.Acquire(BatchSize);
    FSemaphore.Release(BatchSize);
  end;
  EndTime := GetCurrentTimeMs;
  
  WriteLn(Format('总时间: %.2f ms', [EndTime - StartTime]));
  WriteLn(Format('平均每次批量操作: %.4f ms', [(EndTime - StartTime) / 1000]));
  WriteLn(Format('批量操作吞吐量: %.0f batches/sec', [1000 * 1000.0 / (EndTime - StartTime)]));
  WriteLn;
end;



end.
