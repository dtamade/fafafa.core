{$CODEPAGE UTF8}
program example_advanced_patterns;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils,
  fafafa.core.sync.base,
  fafafa.core.sync.mutex;

type
  { 线程安全的队列 }
  TThreadSafeQueue = class
  private
    FQueue: TList;
    FMutex: IMutex;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Enqueue(Item: Pointer);
    function TryDequeue(out Item: Pointer): Boolean;
    function Count: Integer;
    procedure Clear;
  end;

  { 对象池 }
  TPooledObject = class
  private
    FData: string;
  public
    constructor Create(const AData: string);
    property Data: string read FData write FData;
  end;

  TObjectPool = class
  private
    FPool: TList;
    FMutex: IMutex;
    FMaxSize: Integer;
  public
    constructor Create(AMaxSize: Integer);
    destructor Destroy; override;
    function Acquire: TPooledObject;
    procedure Release(Obj: TPooledObject);
    function PoolSize: Integer;
  end;

{ TThreadSafeQueue }

constructor TThreadSafeQueue.Create;
begin
  inherited Create;
  FQueue := TList.Create;
  FMutex := MakeMutex;
end;

destructor TThreadSafeQueue.Destroy;
begin
  FQueue.Free;
  inherited Destroy;
end;

procedure TThreadSafeQueue.Enqueue(Item: Pointer);
var
  Guard: ILockGuard;
begin
  Guard := MakeLockGuard(FMutex);
  FQueue.Add(Item);
end;

function TThreadSafeQueue.TryDequeue(out Item: Pointer): Boolean;
var
  Guard: ILockGuard;
begin
  Guard := MakeLockGuard(FMutex);
  Result := FQueue.Count > 0;
  if Result then
  begin
    Item := FQueue[0];
    FQueue.Delete(0);
  end
  else
    Item := nil;
end;

function TThreadSafeQueue.Count: Integer;
var
  Guard: ILockGuard;
begin
  Guard := MakeLockGuard(FMutex);
  Result := FQueue.Count;
end;

procedure TThreadSafeQueue.Clear;
var
  Guard: ILockGuard;
begin
  Guard := MakeLockGuard(FMutex);
  FQueue.Clear;
end;

{ TPooledObject }

constructor TPooledObject.Create(const AData: string);
begin
  inherited Create;
  FData := AData;
end;

{ TObjectPool }

constructor TObjectPool.Create(AMaxSize: Integer);
begin
  inherited Create;
  FPool := TList.Create;
  FMutex := MakeMutex;
  FMaxSize := AMaxSize;
end;

destructor TObjectPool.Destroy;
var
  i: Integer;
begin
  for i := 0 to FPool.Count - 1 do
    TPooledObject(FPool[i]).Free;
  FPool.Free;
  inherited Destroy;
end;

function TObjectPool.Acquire: TPooledObject;
var
  Guard: ILockGuard;
begin
  Guard := MakeLockGuard(FMutex);
  
  if FPool.Count > 0 then
  begin
    Result := TPooledObject(FPool[FPool.Count - 1]);
    FPool.Delete(FPool.Count - 1);
  end
  else
  begin
    Result := TPooledObject.Create('新对象');
  end;
end;

procedure TObjectPool.Release(Obj: TPooledObject);
var
  Guard: ILockGuard;
begin
  if Obj = nil then Exit;
  
  Guard := MakeLockGuard(FMutex);
  
  if FPool.Count < FMaxSize then
  begin
    Obj.Data := '已重置';
    FPool.Add(Obj);
  end
  else
  begin
    Obj.Free; // 池已满，直接释放
  end;
end;

function TObjectPool.PoolSize: Integer;
var
  Guard: ILockGuard;
begin
  Guard := MakeLockGuard(FMutex);
  Result := FPool.Count;
end;

{ 示例程序 }

procedure DemoThreadSafeQueue;
var
  Queue: TThreadSafeQueue;
  Producer, Consumer: TThread;
  Item: Pointer;
  ProducedCount, ConsumedCount: Integer;
begin
  WriteLn('=== 线程安全队列示例 ===');
  
  Queue := TThreadSafeQueue.Create;
  try
    ProducedCount := 0;
    ConsumedCount := 0;
    
    // 生产者线程
    Producer := TThread.CreateAnonymousThread(
      procedure
      var
        i: Integer;
      begin
        for i := 1 to 50 do
        begin
          Queue.Enqueue(Pointer(i));
          InterlockedIncrement(ProducedCount);
          Sleep(10);
        end;
      end);
    
    // 消费者线程
    Consumer := TThread.CreateAnonymousThread(
      procedure
      var
        Item: Pointer;
      begin
        while ConsumedCount < 50 do
        begin
          if Queue.TryDequeue(Item) then
          begin
            InterlockedIncrement(ConsumedCount);
            WriteLn('消费项目: ', PtrInt(Item));
          end
          else
            Sleep(5);
        end;
      end);
    
    Producer.Start;
    Consumer.Start;
    
    Producer.WaitFor;
    Consumer.WaitFor;
    
    Producer.Free;
    Consumer.Free;
    
    WriteLn(Format('生产: %d, 消费: %d, 队列剩余: %d', 
      [ProducedCount, ConsumedCount, Queue.Count]));
    
  finally
    Queue.Free;
  end;
  
  WriteLn;
end;

procedure DemoObjectPool;
var
  Pool: TObjectPool;
  Objects: array[0..4] of TPooledObject;
  i: Integer;
begin
  WriteLn('=== 对象池示例 ===');
  
  Pool := TObjectPool.Create(3); // 最大池大小为 3
  try
    WriteLn('初始池大小: ', Pool.PoolSize);
    
    // 获取对象
    for i := 0 to 4 do
    begin
      Objects[i] := Pool.Acquire;
      WriteLn(Format('获取对象 %d: %s', [i, Objects[i].Data]));
    end;
    
    WriteLn('获取后池大小: ', Pool.PoolSize);
    
    // 释放对象
    for i := 0 to 4 do
    begin
      Pool.Release(Objects[i]);
      WriteLn(Format('释放对象 %d，池大小: %d', [i, Pool.PoolSize]));
    end;
    
  finally
    Pool.Free;
  end;
  
  WriteLn;
end;

procedure DemoRAIIPattern;
begin
  WriteLn('=== RAII 模式示例 ===');
  
  // 使用 MutexGuard 的便捷方式
  begin
    var Guard: ILockGuard := MutexGuard;
    WriteLn('✓ 锁已自动获取');
    Sleep(100);
    WriteLn('✓ 执行临界区代码');
    // Guard 超出作用域时自动释放锁
  end;
  
  WriteLn('✓ 锁已自动释放');
  WriteLn;
end;

procedure DemoPerformanceComparison;
const
  ITERATIONS = 10000;
var
  Mutex: IMutex;
  StartTime, EndTime: QWord;
  i: Integer;
  ManualTime, GuardTime: QWord;
begin
  WriteLn('=== 性能对比示例 ===');
  
  Mutex := MakeMutex;
  
  // 测试手动锁管理
  StartTime := GetTickCount64;
  for i := 1 to ITERATIONS do
  begin
    Mutex.Acquire;
    try
      // 空操作
    finally
      Mutex.Release;
    end;
  end;
  EndTime := GetTickCount64;
  ManualTime := EndTime - StartTime;
  
  // 测试锁保护器
  StartTime := GetTickCount64;
  for i := 1 to ITERATIONS do
  begin
    var Guard: ILockGuard := MakeLockGuard(Mutex);
    // 空操作
  end;
  EndTime := GetTickCount64;
  GuardTime := EndTime - StartTime;
  
  WriteLn(Format('手动管理: %d ms', [ManualTime]));
  WriteLn(Format('锁保护器: %d ms', [GuardTime]));
  WriteLn(Format('开销: %.2f%%', [(GuardTime - ManualTime) * 100.0 / ManualTime]));
  WriteLn;
end;

begin
  WriteLn('fafafa.core.sync.mutex 高级使用模式示例');
  WriteLn('=========================================');
  WriteLn;
  
  try
    DemoRAIIPattern;
    DemoThreadSafeQueue;
    DemoObjectPool;
    DemoPerformanceComparison;
    
    WriteLn('所有高级示例执行完成！');
    
  except
    on E: Exception do
    begin
      WriteLn('发生异常: ', E.ClassName, ': ', E.Message);
      ExitCode := 1;
    end;
  end;
  
  WriteLn;
  WriteLn('按回车键退出...');
  ReadLn;
end.
