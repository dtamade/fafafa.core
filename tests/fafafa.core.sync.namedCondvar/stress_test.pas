program stress_test;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  SysUtils, Classes, Process,
  fafafa.core.sync.namedCondvar,
  fafafa.core.sync.namedMutex,
  fafafa.core.sync.base,
  fafafa.core.sync.mutex.base;

const
  TEST_CONDVAR_NAME = 'stress_test_condvar';
  TEST_MUTEX_NAME = 'stress_test_mutex';
  NUM_THREADS = 4;
  NUM_OPERATIONS = 100;
  NUM_PROCESSES = 2;

type
  TStressTestThread = class(TThread)
  private
    FWorkerID: Integer;  // 避免与 TThread.ThreadID 冲突
    FCondVar: INamedConditionVariable;
    FMutex: INamedMutex;
    FSuccessCount: Integer;
    FErrorCount: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(AThreadId: Integer; ACondVar: INamedConditionVariable; AMutex: INamedMutex);
    property SuccessCount: Integer read FSuccessCount;
    property ErrorCount: Integer read FErrorCount;
  end;

var
  GCondVar: INamedConditionVariable;
  GMutex: INamedMutex;
  GSharedCounter: Integer = 0;

constructor TStressTestThread.Create(AThreadId: Integer; ACondVar: INamedConditionVariable; AMutex: INamedMutex);
begin
  FWorkerID := AThreadId;
  FCondVar := ACondVar;
  FMutex := AMutex;
  FSuccessCount := 0;
  FErrorCount := 0;
  inherited Create(False);
end;

procedure TStressTestThread.Execute;
var
  i: Integer;
  LResult: Boolean;
  LGuard: INamedMutexGuard;
begin
  WriteLn(Format('[Thread %d] Starting stress test', [FWorkerID]));

  for i := 1 to NUM_OPERATIONS do
  begin
    try
      // 随机选择操作类型
      case Random(4) of
        0: begin // Wait with timeout
          LGuard := FMutex.Lock;
          try
            LResult := FCondVar.Wait(ILock(FMutex), 10); // 10ms timeout
            if LResult then
              Inc(FSuccessCount)
            else
              Inc(FSuccessCount); // 超时也算成功
          finally
            LGuard := nil;
          end;
        end;
        
        1: begin // Signal
          FCondVar.Signal;
          Inc(FSuccessCount);
        end;
        
        2: begin // Broadcast
          FCondVar.Broadcast;
          Inc(FSuccessCount);
        end;
        
        3: begin // Shared counter increment
          LGuard := FMutex.Lock;
          try
            Inc(GSharedCounter);
            if GSharedCounter mod 10 = 0 then
              FCondVar.Broadcast; // Broadcast every 10 increments
            Inc(FSuccessCount);
          finally
            LGuard := nil;
          end;
        end;
      end;
      
      // Random delay to simulate real workload
      if Random(10) = 0 then
        Sleep(1);
        
    except
      on E: Exception do
      begin
        Inc(FErrorCount);
        WriteLn(Format('[Thread %d] Error: %s', [FWorkerID, E.Message]));
      end;
    end;
  end;

  WriteLn(Format('[Thread %d] Completed: Success=%d, Errors=%d', [FWorkerID, FSuccessCount, FErrorCount]));
end;

procedure RunMultiThreadTest;
var
  Threads: array[0..NUM_THREADS-1] of TStressTestThread;
  i: Integer;
  TotalSuccess, TotalErrors: Integer;
  StartTime: QWord;
begin
  WriteLn('=== Multi-Thread Stress Test ===');
  
  // 创建共享对象
  GMutex := MakeNamedMutex(TEST_MUTEX_NAME);
  GCondVar := MakeNamedConditionVariable(TEST_CONDVAR_NAME);
  
  StartTime := GetTickCount64;
  
  // 创建并启动线程
  for i := 0 to NUM_THREADS-1 do
    Threads[i] := TStressTestThread.Create(i+1, GCondVar, GMutex);
  
  // 等待所有线程完成
  TotalSuccess := 0;
  TotalErrors := 0;
  for i := 0 to NUM_THREADS-1 do
  begin
    Threads[i].WaitFor;
    TotalSuccess := TotalSuccess + Threads[i].SuccessCount;
    TotalErrors := TotalErrors + Threads[i].ErrorCount;
    Threads[i].Free;
  end;
  
  WriteLn(Format('Multi-thread test completed: Time=%dms, Total Success=%d, Total Errors=%d, Shared Counter=%d',
    [GetTickCount64 - StartTime, TotalSuccess, TotalErrors, GSharedCounter]));
end;

procedure RunMultiProcessTest;
var
  Processes: array[0..NUM_PROCESSES-1] of TProcess;
  i: Integer;
  StartTime: QWord;
  AllSuccess: Boolean;
begin
  WriteLn('=== Multi-Process Stress Test ===');
  
  StartTime := GetTickCount64;
  AllSuccess := True;
  
  // 启动多个进程
  for i := 0 to NUM_PROCESSES-1 do
  begin
    Processes[i] := TProcess.Create(nil);
    Processes[i].Executable := ParamStr(0);
    Processes[i].Parameters.Add('worker');
    Processes[i].Parameters.Add(IntToStr(i+1));
    Processes[i].Options := [poWaitOnExit];
    Processes[i].Execute;
  end;
  
  // 等待所有进程完成
  for i := 0 to NUM_PROCESSES-1 do
  begin
    if Processes[i].ExitCode <> 0 then
    begin
      AllSuccess := False;
      WriteLn(Format('Process %d failed, exit code: %d', [i+1, Processes[i].ExitCode]));
    end;
    Processes[i].Free;
  end;
  
  if AllSuccess then
    WriteLn(Format('Multi-process test completed: Time=%dms, Result=SUCCESS', [GetTickCount64 - StartTime]))
  else
    WriteLn(Format('Multi-process test completed: Time=%dms, Result=FAILED', [GetTickCount64 - StartTime]));
end;

procedure RunWorkerProcess(AWorkerId: Integer);
var
  i: Integer;
  LResult: Boolean;
  SuccessCount, ErrorCount: Integer;
  LGuard: INamedMutexGuard;
begin
  WriteLn(Format('[Worker %d] Starting work', [AWorkerId]));

  // 创建共享对象
  GMutex := MakeNamedMutex(TEST_MUTEX_NAME);
  GCondVar := MakeNamedConditionVariable(TEST_CONDVAR_NAME);

  SuccessCount := 0;
  ErrorCount := 0;

  for i := 1 to NUM_OPERATIONS do
  begin
    try
      case (AWorkerId + i) mod 3 of
        0: begin // Wait
          LGuard := GMutex.Lock;
          try
            LResult := GCondVar.Wait(ILock(GMutex), 50);
            Inc(SuccessCount);
          finally
            LGuard := nil;
          end;
        end;
        
        1: begin // Signal
          GCondVar.Signal;
          Inc(SuccessCount);
        end;
        
        2: begin // Broadcast
          GCondVar.Broadcast;
          Inc(SuccessCount);
        end;
      end;
      
      if i mod 20 = 0 then
        Sleep(1); // Occasional rest
        
    except
      on E: Exception do
      begin
        Inc(ErrorCount);
        WriteLn(Format('[Worker %d] Error: %s', [AWorkerId, E.Message]));
      end;
    end;
  end;
  
  WriteLn(Format('[Worker %d] Completed: Success=%d, Errors=%d', [AWorkerId, SuccessCount, ErrorCount]));
  
  if ErrorCount > 0 then
    ExitCode := 1
  else
    ExitCode := 0;
end;

begin
  Randomize;
  
  try
    if ParamCount >= 1 then
    begin
      if ParamStr(1) = 'worker' then
      begin
        if ParamCount >= 2 then
          RunWorkerProcess(StrToInt(ParamStr(2)))
        else
          RunWorkerProcess(1);
      end;
    end
    else
    begin
      WriteLn('🚀 namedConditionVariable Concurrent Stress Test');
      WriteLn(Format('Config: %d threads × %d operations, %d processes × %d operations',
        [NUM_THREADS, NUM_OPERATIONS, NUM_PROCESSES, NUM_OPERATIONS]));
      WriteLn;
      
      RunMultiThreadTest;
      WriteLn;
      RunMultiProcessTest;
      
      WriteLn;
      WriteLn('✅ Stress test completed!');
    end;
    
  except
    on E: Exception do
    begin
      WriteLn('❌ Stress test failed: ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
