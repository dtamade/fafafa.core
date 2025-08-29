program memory_stress_test;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  SysUtils, Classes,
  fafafa.core.sync.event;

type
  { 内存压力测试 }
  TMemoryStressTest = class
  private
    FEventCount: Integer;
    FThreadCount: Integer;
    FIterations: Integer;
    
    procedure TestMassiveEventCreation;
    procedure TestConcurrentEventUsage;
    procedure TestRAIIGuardStress;
    procedure TestInterruptStress;
    
    function GetMemoryUsage: Int64;
    procedure PrintMemoryInfo(const TestName: string; Before, After: Int64);
  public
    constructor Create(AEventCount: Integer = 10000; AThreadCount: Integer = 8; AIterations: Integer = 1000);
    procedure RunAllTests;
  end;

{ 并发事件使用线程 }
type
  TEventStressThread = class(TThread)
  private
    FEvents: array of IEvent;
    FIterations: Integer;
    FOperationCount: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(const AEvents: array of IEvent; AIterations: Integer);
    property OperationCount: Integer read FOperationCount;
  end;

{ RAII 守卫压力测试线程 }
type
  TGuardStressThread = class(TThread)
  private
    FEvent: IEvent;
    FIterations: Integer;
    FGuardCount: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(AEvent: IEvent; AIterations: Integer);
    property GuardCount: Integer read FGuardCount;
  end;

{ TMemoryStressTest }

constructor TMemoryStressTest.Create(AEventCount: Integer; AThreadCount: Integer; AIterations: Integer);
begin
  inherited Create;
  FEventCount := AEventCount;
  FThreadCount := AThreadCount;
  FIterations := AIterations;
end;

function TMemoryStressTest.GetMemoryUsage: Int64;
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
        Result := StrToInt64Def(VmRSS, 0) * 1024; // 转换为字节
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
  // Windows 下简化实现
  Result := 0;
end;
{$ENDIF}

procedure TMemoryStressTest.PrintMemoryInfo(const TestName: string; Before, After: Int64);
var
  Delta: Int64;
begin
  Delta := After - Before;
  WriteLn(Format('%-30s: %8.2f MB -> %8.2f MB (Δ %+8.2f MB)', 
    [TestName, Before / 1024 / 1024, After / 1024 / 1024, Delta / 1024 / 1024]));
end;

procedure TMemoryStressTest.TestMassiveEventCreation;
var
  Events: array of IEvent;
  i: Integer;
  MemBefore, MemAfter: Int64;
begin
  WriteLn('测试大量事件对象创建和销毁...');
  
  MemBefore := GetMemoryUsage;
  
  // 创建大量事件对象
  SetLength(Events, FEventCount);
  for i := 0 to FEventCount - 1 do
  begin
    if i mod 2 = 0 then
      Events[i] := CreateEvent(True, False)  // 手动重置
    else
      Events[i] := CreateEvent(False, False); // 自动重置
      
    // 执行一些基本操作
    Events[i].SetEvent;
    Events[i].TryWait;
    Events[i].ResetEvent;
    
    if i mod 1000 = 0 then
      Write(Format(#13'创建进度: %d/%d', [i + 1, FEventCount]));
  end;
  WriteLn;
  
  MemAfter := GetMemoryUsage;
  PrintMemoryInfo('大量事件创建', MemBefore, MemAfter);
  
  // 清理所有事件
  for i := 0 to FEventCount - 1 do
    Events[i] := nil;
  SetLength(Events, 0);
  
  // 强制垃圾回收（如果支持）
  {$IFDEF FPC}
  // FPC 没有显式的垃圾回收
  {$ENDIF}
  
  MemAfter := GetMemoryUsage;
  PrintMemoryInfo('事件清理后', MemBefore, MemAfter);
end;

procedure TMemoryStressTest.TestConcurrentEventUsage;
var
  Events: array of IEvent;
  Threads: array of TEventStressThread;
  i: Integer;
  MemBefore, MemAfter: Int64;
  TotalOps: Integer;
begin
  WriteLn('测试并发事件使用...');
  
  MemBefore := GetMemoryUsage;
  
  // 创建共享事件
  SetLength(Events, FThreadCount);
  for i := 0 to FThreadCount - 1 do
    Events[i] := CreateEvent(i mod 2 = 0, False);
  
  // 创建并启动压力测试线程
  SetLength(Threads, FThreadCount);
  for i := 0 to FThreadCount - 1 do
  begin
    Threads[i] := TEventStressThread.Create(Events, FIterations);
    Threads[i].Start;
  end;
  
  // 等待所有线程完成
  TotalOps := 0;
  for i := 0 to FThreadCount - 1 do
  begin
    Threads[i].WaitFor;
    Inc(TotalOps, Threads[i].OperationCount);
    Threads[i].Free;
  end;
  
  MemAfter := GetMemoryUsage;
  PrintMemoryInfo('并发事件使用', MemBefore, MemAfter);
  WriteLn(Format('总操作数: %d', [TotalOps]));
  
  // 清理
  for i := 0 to FThreadCount - 1 do
    Events[i] := nil;
end;

procedure TMemoryStressTest.TestRAIIGuardStress;
var
  Event: IEvent;
  Threads: array of TGuardStressThread;
  i: Integer;
  MemBefore, MemAfter: Int64;
  TotalGuards: Integer;
begin
  WriteLn('测试 RAII 守卫压力...');
  
  MemBefore := GetMemoryUsage;
  
  Event := CreateEvent(True, True); // 手动重置，初始信号状态
  
  // 创建并启动守卫压力测试线程
  SetLength(Threads, FThreadCount);
  for i := 0 to FThreadCount - 1 do
  begin
    Threads[i] := TGuardStressThread.Create(Event, FIterations);
    Threads[i].Start;
  end;
  
  // 等待所有线程完成
  TotalGuards := 0;
  for i := 0 to FThreadCount - 1 do
  begin
    Threads[i].WaitFor;
    Inc(TotalGuards, Threads[i].GuardCount);
    Threads[i].Free;
  end;
  
  MemAfter := GetMemoryUsage;
  PrintMemoryInfo('RAII 守卫压力', MemBefore, MemAfter);
  WriteLn(Format('总守卫数: %d', [TotalGuards]));
  
  Event := nil;
end;

procedure TMemoryStressTest.TestInterruptStress;
var
  Events: array of IEvent;
  i, j: Integer;
  MemBefore, MemAfter: Int64;
begin
  WriteLn('测试中断机制压力...');
  
  MemBefore := GetMemoryUsage;
  
  SetLength(Events, 100);
  
  // 重复创建、中断、销毁事件
  for i := 1 to FIterations do
  begin
    // 创建事件
    for j := 0 to 99 do
      Events[j] := CreateEvent(j mod 2 = 0, False);
    
    // 中断所有事件
    for j := 0 to 99 do
      Events[j].Interrupt;
    
    // 测试中断状态
    for j := 0 to 99 do
      Events[j].IsInterrupted;
    
    // 清理
    for j := 0 to 99 do
      Events[j] := nil;
      
    if i mod 100 = 0 then
      Write(Format(#13'中断测试进度: %d/%d', [i, FIterations]));
  end;
  WriteLn;
  
  MemAfter := GetMemoryUsage;
  PrintMemoryInfo('中断机制压力', MemBefore, MemAfter);
end;

procedure TMemoryStressTest.RunAllTests;
begin
  WriteLn('=== fafafa.core.sync.event 内存压力测试 ===');
  WriteLn(Format('事件数量: %d, 线程数: %d, 迭代次数: %d', [FEventCount, FThreadCount, FIterations]));
  WriteLn;
  
  TestMassiveEventCreation;
  WriteLn;
  TestConcurrentEventUsage;
  WriteLn;
  TestRAIIGuardStress;
  WriteLn;
  TestInterruptStress;
  
  WriteLn;
  WriteLn('内存压力测试完成');
end;

{ TEventStressThread }

constructor TEventStressThread.Create(const AEvents: array of IEvent; AIterations: Integer);
var
  i: Integer;
begin
  inherited Create(False);
  SetLength(FEvents, Length(AEvents));
  for i := 0 to High(AEvents) do
    FEvents[i] := AEvents[i];
  FIterations := AIterations;
  FOperationCount := 0;
end;

procedure TEventStressThread.Execute;
var
  i, j: Integer;
begin
  for i := 1 to FIterations do
  begin
    for j := 0 to High(FEvents) do
    begin
      FEvents[j].SetEvent;
      FEvents[j].TryWait;
      FEvents[j].ResetEvent;
      Inc(FOperationCount, 3);
    end;
  end;
end;

{ TGuardStressThread }

constructor TGuardStressThread.Create(AEvent: IEvent; AIterations: Integer);
begin
  inherited Create(False);
  FEvent := AEvent;
  FIterations := AIterations;
  FGuardCount := 0;
end;

procedure TGuardStressThread.Execute;
var
  i: Integer;
  Guard: IEventGuard;
begin
  for i := 1 to FIterations do
  begin
    Guard := FEvent.TryWaitGuard;
    if Guard.IsValid then
      Inc(FGuardCount);
    Guard := nil; // 显式释放
  end;
end;

{ 主程序 }
var
  StressTest: TMemoryStressTest;
begin
  try
    StressTest := TMemoryStressTest.Create(5000, 4, 1000);
    try
      StressTest.RunAllTests;
    finally
      StressTest.Free;
    end;
  except
    on E: Exception do
    begin
      WriteLn('错误: ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
