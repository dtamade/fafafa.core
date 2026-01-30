{$CODEPAGE UTF8}
program fafafa.core.sync.namedMutex.stress;

{$mode objfpc}{$H+}

uses
  SysUtils, Classes, DateUtils,
  fafafa.core.sync.namedMutex;

const
  MUTEX_NAME = 'fafafa_stress_test';
  STRESS_DURATION_SECONDS = 30;
  MAX_MUTEXES = 100;

type
  TStressTestThread = class(TThread)
  private
    FThreadId: Integer;
    FMutex: INamedMutex;
    FOperationCount: Integer;
    FErrorCount: Integer;
    FStartTime: TDateTime;
  protected
    procedure Execute; override;
  public
    constructor Create(AThreadId: Integer; AMutex: INamedMutex);
    property OperationCount: Integer read FOperationCount;
    property ErrorCount: Integer read FErrorCount;
  end;

var
  LMutex: INamedMutex;
  LThreads: array of TStressTestThread;
  LStartTime: TDateTime;
  i: Integer;
  LTotalOperations: Integer;
  LTotalErrors: Integer;

{ TStressTestThread }

constructor TStressTestThread.Create(AThreadId: Integer; AMutex: INamedMutex);
begin
  inherited Create(False);
  FThreadId := AThreadId;
  FMutex := AMutex;
  FOperationCount := 0;
  FErrorCount := 0;
  FStartTime := Now;
end;

procedure TStressTestThread.Execute;
var
  LGuard: INamedMutexGuard;
  LElapsed: Double;
begin
  WriteLn(Format('[线程 %d] 开始压力测试', [FThreadId]));
  
  while not Terminated do
  begin
    LElapsed := SecondsBetween(Now, FStartTime);
    if LElapsed >= STRESS_DURATION_SECONDS then
      Break;
    
    try
      // 随机选择操作类型
      case Random(4) of
        0: begin
          // 阻塞锁定
          LGuard := FMutex.Lock;
          Sleep(Random(5)); // 模拟工作
          LGuard := nil;
        end;
        1: begin
          // 非阻塞尝试
          LGuard := FMutex.TryLock;
          if Assigned(LGuard) then
          begin
            Sleep(Random(3)); // 模拟工作
            LGuard := nil;
          end;
        end;
        2: begin
          // 带超时的尝试
          LGuard := FMutex.TryLockFor(Random(50) + 10);
          if Assigned(LGuard) then
          begin
            Sleep(Random(2)); // 模拟工作
            LGuard := nil;
          end;
        end;
        3: begin
          // 快速锁定释放
          LGuard := FMutex.Lock;
          LGuard := nil;
        end;
      end;
      
      Inc(FOperationCount);
      
      // 偶尔短暂休眠
      if Random(100) < 5 then
        Sleep(1);
        
    except
      on E: Exception do
      begin
        Inc(FErrorCount);
        WriteLn(Format('[线程 %d] 错误: %s', [FThreadId, E.Message]));
      end;
    end;
  end;
  
  WriteLn(Format('[线程 %d] 完成，操作数: %d，错误数: %d', 
    [FThreadId, FOperationCount, FErrorCount]));
end;

function TestMultipleMutexes: Boolean;
var
  LMutexes: array of INamedMutex;
  LMutexName: string;
  j: Integer;
  LGuard: INamedMutexGuard;
begin
  Result := True;
  WriteLn('测试多个互斥锁的创建和使用...');
  
  try
    SetLength(LMutexes, MAX_MUTEXES);
    
    // 创建多个互斥锁
    for j := 0 to High(LMutexes) do
    begin
      LMutexName := Format('stress_mutex_%d', [j]);
      LMutexes[j] := CreateNamedMutex(LMutexName);
    end;
    
    // 快速使用所有互斥锁
    for j := 0 to High(LMutexes) do
    begin
      LGuard := LMutexes[j].Lock;
      LGuard := nil;
    end;
    
    WriteLn(Format('成功创建和使用 %d 个互斥锁', [MAX_MUTEXES]));
    
  except
    on E: Exception do
    begin
      WriteLn(Format('多互斥锁测试失败: %s', [E.Message]));
      Result := False;
    end;
  end;
end;

begin
  WriteLn('=== fafafa.core.sync.namedMutex 压力测试 ===');
  WriteLn(Format('测试持续时间: %d 秒', [STRESS_DURATION_SECONDS]));
  WriteLn;
  
  try
    // 创建主测试互斥锁
    LMutex := CreateNamedMutex(MUTEX_NAME);
    WriteLn('成功创建测试互斥锁');
    
    // 测试多个互斥锁
    if not TestMultipleMutexes then
    begin
      WriteLn('多互斥锁测试失败');
      ExitCode := 1;
      Exit;
    end;
    
    WriteLn;
    WriteLn('开始多线程压力测试...');
    
    // 创建多个线程进行压力测试
    SetLength(LThreads, 8);
    LStartTime := Now;
    
    for i := 0 to High(LThreads) do
    begin
      LThreads[i] := TStressTestThread.Create(i + 1, LMutex);
    end;
    
    // 等待所有线程完成
    for i := 0 to High(LThreads) do
    begin
      LThreads[i].WaitFor;
    end;
    
    // 统计结果
    LTotalOperations := 0;
    LTotalErrors := 0;
    
    for i := 0 to High(LThreads) do
    begin
      Inc(LTotalOperations, LThreads[i].OperationCount);
      Inc(LTotalErrors, LThreads[i].ErrorCount);
      LThreads[i].Free;
    end;
    
    WriteLn;
    WriteLn('=== 压力测试结果 ===');
    WriteLn(Format('总操作数: %d', [LTotalOperations]));
    WriteLn(Format('总错误数: %d', [LTotalErrors]));
    WriteLn(Format('错误率: %.2f%%', [(LTotalErrors / LTotalOperations) * 100]));
    WriteLn(Format('平均每秒操作数: %.0f ops/sec', 
      [LTotalOperations / STRESS_DURATION_SECONDS]));
    
    if LTotalErrors = 0 then
    begin
      WriteLn('✅ 压力测试成功！无错误发生。');
      ExitCode := 0;
    end
    else
    begin
      WriteLn('⚠️  压力测试完成，但有错误发生。');
      ExitCode := 1;
    end;
    
  except
    on E: Exception do
    begin
      WriteLn(Format('压力测试失败: %s', [E.Message]));
      ExitCode := 1;
    end;
  end;
end.
