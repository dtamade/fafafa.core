program stability_test;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  SysUtils, Classes, DateUtils,
  fafafa.core.sync.event, fafafa.core.sync.base;

type
  { 长时间稳定性测试 }
  TStabilityTest = class
  private
    FRunning: Boolean;
    FStartTime: TDateTime;
    FDurationMinutes: Integer;
    FThreadCount: Integer;
    FStatistics: record
      EventsCreated: Int64;
      EventsDestroyed: Int64;
      OperationsPerformed: Int64;
      ErrorsEncountered: Int64;
      InterruptsProcessed: Int64;
    end;
    
    procedure ResetStatistics;
    procedure PrintStatistics;
    procedure RunContinuousEventTest;
    procedure RunMemoryLeakTest;
    procedure RunConcurrencyStressTest;
    
  public
    constructor Create(ADurationMinutes: Integer = 5; AThreadCount: Integer = 8);
    procedure RunStabilityTest;
    procedure Stop;
  end;

{ 持续事件操作线程 }
type
  TContinuousEventThread = class(TThread)
  private
    FParent: TStabilityTest;
    FThreadId: Integer;
    FLocalStats: record
      Operations: Int64;
      Errors: Int64;
      Events: Int64;
    end;
  protected
    procedure Execute; override;
  public
    constructor Create(AParent: TStabilityTest; AThreadId: Integer);
    procedure GetStats(out Operations, Errors, Events: Int64);
  end;

{ 内存泄漏检测线程 }
type
  TMemoryLeakThread = class(TThread)
  private
    FParent: TStabilityTest;
    FInitialMemory: Int64;
    FPeakMemory: Int64;
    FCurrentMemory: Int64;
  protected
    procedure Execute; override;
    function GetMemoryUsage: Int64;
  public
    constructor Create(AParent: TStabilityTest);
    procedure GetMemoryStats(out Initial, Peak, Current: Int64);
  end;

{ 并发压力测试线程 }
type
  TConcurrencyStressThread = class(TThread)
  private
    FParent: TStabilityTest;
    FSharedEvents: array[0..9] of IEvent;
    FOperationCount: Int64;
  protected
    procedure Execute; override;
  public
    constructor Create(AParent: TStabilityTest);
    destructor Destroy; override;
    property OperationCount: Int64 read FOperationCount;
  end;

{ TStabilityTest }

constructor TStabilityTest.Create(ADurationMinutes: Integer; AThreadCount: Integer);
begin
  inherited Create;
  FDurationMinutes := ADurationMinutes;
  FThreadCount := AThreadCount;
  FRunning := False;
  ResetStatistics;
end;

procedure TStabilityTest.ResetStatistics;
begin
  FillChar(FStatistics, SizeOf(FStatistics), 0);
end;

procedure TStabilityTest.PrintStatistics;
var
  ElapsedMinutes: Double;
  OpsPerSecond: Double;
begin
  ElapsedMinutes := (Now - FStartTime) * 24 * 60;
  if ElapsedMinutes > 0 then
    OpsPerSecond := FStatistics.OperationsPerformed / (ElapsedMinutes * 60)
  else
    OpsPerSecond := 0;
    
  WriteLn(Format(#13'运行时间: %.1f 分钟 | 事件: %d/%d | 操作: %d (%.0f ops/s) | 错误: %d | 中断: %d',
    [ElapsedMinutes, FStatistics.EventsCreated, FStatistics.EventsDestroyed,
     FStatistics.OperationsPerformed, OpsPerSecond, FStatistics.ErrorsEncountered,
     FStatistics.InterruptsProcessed]));
end;

procedure TStabilityTest.RunContinuousEventTest;
var
  Threads: array of TContinuousEventThread;
  i: Integer;
  Operations, Errors, Events: Int64;
begin
  WriteLn('启动持续事件操作测试...');
  
  SetLength(Threads, FThreadCount);
  for i := 0 to FThreadCount - 1 do
  begin
    Threads[i] := TContinuousEventThread.Create(Self, i);
    Threads[i].Start;
  end;
  
  // 等待测试完成
  while FRunning do
  begin
    Sleep(1000);
    
    // 收集统计信息
    FStatistics.OperationsPerformed := 0;
    FStatistics.ErrorsEncountered := 0;
    FStatistics.EventsCreated := 0;
    
    for i := 0 to FThreadCount - 1 do
    begin
      Threads[i].GetStats(Operations, Errors, Events);
      Inc(FStatistics.OperationsPerformed, Operations);
      Inc(FStatistics.ErrorsEncountered, Errors);
      Inc(FStatistics.EventsCreated, Events);
    end;
    
    PrintStatistics;
  end;
  
  // 停止所有线程
  for i := 0 to FThreadCount - 1 do
  begin
    Threads[i].Terminate;
    Threads[i].WaitFor;
    Threads[i].Free;
  end;
end;

procedure TStabilityTest.RunMemoryLeakTest;
var
  MemThread: TMemoryLeakThread;
  Initial, Peak, Current: Int64;
begin
  WriteLn('启动内存泄漏检测...');
  
  MemThread := TMemoryLeakThread.Create(Self);
  MemThread.Start;
  
  // 在主测试结束后检查内存
  MemThread.WaitFor;
  MemThread.GetMemoryStats(Initial, Peak, Current);
  
  WriteLn;
  WriteLn(Format('内存使用情况: 初始=%.2f MB, 峰值=%.2f MB, 结束=%.2f MB',
    [Initial / 1024 / 1024, Peak / 1024 / 1024, Current / 1024 / 1024]));
    
  if Current > Initial * 1.1 then
    WriteLn('警告: 可能存在内存泄漏')
  else
    WriteLn('内存使用正常');
    
  MemThread.Free;
end;

procedure TStabilityTest.RunConcurrencyStressTest;
var
  Threads: array of TConcurrencyStressThread;
  i: Integer;
  TotalOps: Int64;
begin
  WriteLn('启动并发压力测试...');
  
  SetLength(Threads, FThreadCount div 2); // 使用一半线程进行并发测试
  for i := 0 to High(Threads) do
  begin
    Threads[i] := TConcurrencyStressThread.Create(Self);
    Threads[i].Start;
  end;
  
  // 等待测试完成
  TotalOps := 0;
  for i := 0 to High(Threads) do
  begin
    Threads[i].WaitFor;
    Inc(TotalOps, Threads[i].OperationCount);
    Threads[i].Free;
  end;
  
  WriteLn(Format('并发压力测试完成，总操作数: %d', [TotalOps]));
end;

procedure TStabilityTest.RunStabilityTest;
var
  MemThread: TMemoryLeakThread;
begin
  WriteLn('=== fafafa.core.sync.event 长时间稳定性测试 ===');
  WriteLn(Format('测试时长: %d 分钟, 线程数: %d', [FDurationMinutes, FThreadCount]));
  WriteLn;
  
  FRunning := True;
  FStartTime := Now;
  
  // 启动内存监控
  MemThread := TMemoryLeakThread.Create(Self);
  MemThread.Start;
  
  // 启动主测试
  TThread.CreateAnonymousThread(
    procedure
    begin
      RunContinuousEventTest;
    end).Start;
    
  // 启动并发压力测试
  TThread.CreateAnonymousThread(
    procedure
    begin
      RunConcurrencyStressTest;
    end).Start;
  
  // 等待指定时间
  Sleep(FDurationMinutes * 60 * 1000);
  
  // 停止测试
  Stop;
  
  // 等待内存监控完成
  MemThread.WaitFor;
  MemThread.Free;
  
  WriteLn;
  WriteLn('稳定性测试完成');
end;

procedure TStabilityTest.Stop;
begin
  FRunning := False;
end;

{ TContinuousEventThread }

constructor TContinuousEventThread.Create(AParent: TStabilityTest; AThreadId: Integer);
begin
  inherited Create(False);
  FParent := AParent;
  FThreadId := AThreadId;
  FillChar(FLocalStats, SizeOf(FLocalStats), 0);
end;

procedure TContinuousEventThread.Execute;
var
  Event: IEvent;
  Guard: IEventGuard;
  i: Integer;
begin
  while not Terminated and FParent.FRunning do
  begin
    try
      // 创建不同类型的事件
      if FThreadId mod 2 = 0 then
        Event := CreateEvent(True, False)  // 手动重置
      else
        Event := CreateEvent(False, False); // 自动重置
        
      Inc(FLocalStats.Events);
      
      // 执行各种操作
      for i := 1 to 100 do
      begin
        Event.SetEvent;
        Event.TryWait;
        Event.ResetEvent;
        Event.IsSignaled;
        
        // 测试守卫
        Guard := Event.TryWaitGuard;
        Guard := nil;
        
        // 测试中断
        if i mod 10 = 0 then
          Event.Interrupt;
          
        Inc(FLocalStats.Operations, 5);
        
        if Terminated or not FParent.FRunning then
          Break;
      end;
      
      Event := nil;
      
    except
      on E: Exception do
      begin
        Inc(FLocalStats.Errors);
        // 继续运行，不要因为单个错误停止
      end;
    end;
    
    // 短暂休息
    Sleep(1);
  end;
end;

procedure TContinuousEventThread.GetStats(out Operations, Errors, Events: Int64);
begin
  Operations := FLocalStats.Operations;
  Errors := FLocalStats.Errors;
  Events := FLocalStats.Events;
end;

{ TMemoryLeakThread }

constructor TMemoryLeakThread.Create(AParent: TStabilityTest);
begin
  inherited Create(False);
  FParent := AParent;
  FInitialMemory := GetMemoryUsage;
  FPeakMemory := FInitialMemory;
  FCurrentMemory := FInitialMemory;
end;

function TMemoryLeakThread.GetMemoryUsage: Int64;
{$IFDEF UNIX}
var
  StatusFile: TextFile;
  Line: string;
  VmRSS: string;
begin
  Result := 0;
  try
    AssignFile(StatusFile, '/proc/self/status');
    Reset(StatusFile);
    while not EOF(StatusFile) do
    begin
      ReadLn(StatusFile, Line);
      if Pos('VmRSS:', Line) = 1 then
      begin
        VmRSS := Copy(Line, 7, Length(Line));
        VmRSS := Trim(Copy(VmRSS, 1, Pos(' ', VmRSS) - 1));
        Result := StrToInt64Def(VmRSS, 0) * 1024;
        Break;
      end;
    end;
    CloseFile(StatusFile);
  except
    Result := 0;
  end;
end;
{$ELSE}
begin
  Result := 0; // Windows 简化实现
end;
{$ENDIF}

procedure TMemoryLeakThread.Execute;
begin
  while not Terminated and FParent.FRunning do
  begin
    FCurrentMemory := GetMemoryUsage;
    if FCurrentMemory > FPeakMemory then
      FPeakMemory := FCurrentMemory;
      
    Sleep(5000); // 每5秒检查一次内存
  end;
end;

procedure TMemoryLeakThread.GetMemoryStats(out Initial, Peak, Current: Int64);
begin
  Initial := FInitialMemory;
  Peak := FPeakMemory;
  Current := FCurrentMemory;
end;

{ TConcurrencyStressThread }

constructor TConcurrencyStressThread.Create(AParent: TStabilityTest);
var
  i: Integer;
begin
  inherited Create(False);
  FParent := AParent;
  FOperationCount := 0;
  
  // 创建共享事件
  for i := 0 to 9 do
    FSharedEvents[i] := CreateEvent(i mod 2 = 0, False);
end;

destructor TConcurrencyStressThread.Destroy;
var
  i: Integer;
begin
  for i := 0 to 9 do
    FSharedEvents[i] := nil;
  inherited Destroy;
end;

procedure TConcurrencyStressThread.Execute;
var
  i, j: Integer;
begin
  while not Terminated and FParent.FRunning do
  begin
    for i := 0 to 9 do
    begin
      for j := 1 to 10 do
      begin
        FSharedEvents[i].SetEvent;
        FSharedEvents[i].TryWait;
        FSharedEvents[i].ResetEvent;
        Inc(FOperationCount, 3);
        
        if Terminated or not FParent.FRunning then
          Exit;
      end;
    end;
    
    Sleep(10);
  end;
end;

{ 主程序 }
var
  StabilityTest: TStabilityTest;
  DurationMinutes: Integer;
begin
  try
    // 从命令行参数获取测试时长，默认5分钟
    if ParamCount > 0 then
      DurationMinutes := StrToIntDef(ParamStr(1), 5)
    else
      DurationMinutes := 5;
      
    StabilityTest := TStabilityTest.Create(DurationMinutes, 8);
    try
      StabilityTest.RunStabilityTest;
    finally
      StabilityTest.Free;
    end;
  except
    on E: Exception do
    begin
      WriteLn('严重错误: ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
