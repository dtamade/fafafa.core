unit fafafa.core.parallel;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, SyncObjs;

type
  { 并行任务接口 }
  IParallelTask = interface
    ['{B8F5E2A1-9C3D-4F2E-8A1B-5D7C9E4F6A8B}']
    procedure Execute;
    function GetResult: Pointer;
  end;

  { 并行工作项 }
  TParallelWorkItem = record
    StartIndex: SizeUInt;
    EndIndex: SizeUInt;
    Task: IParallelTask;
  end;

  { 工作线程 }
  TWorkerThread = class(TThread)
  private
    FWorkQueue: TThreadList;
    FEvent: TEvent;
    FTerminating: Boolean;
  protected
    procedure Execute; override;
  public
    constructor Create;
    destructor Destroy; override;
    procedure AddWork(const AWorkItem: TParallelWorkItem);
    procedure Terminate;
  end;

  { 线程池管理器 }
  TThreadPool = class
  private
    FWorkers: array of TWorkerThread;
    FWorkerCount: Integer;
    FCriticalSection: TCriticalSection;
    class var FInstance: TThreadPool;
  public
    constructor Create(AWorkerCount: Integer = 0);
    destructor Destroy; override;
    
    class function Instance: TThreadPool;
    class procedure FreeInstance;
    
    procedure SubmitWork(const AWorkItems: array of TParallelWorkItem);
    procedure WaitForCompletion;
    function GetWorkerCount: Integer;
  end;

  { 并行操作工具类 }
  TParallelUtils = class
  public
    class function GetCPUCount: Integer;
    class function ShouldUseParallel(ADataSize: SizeUInt): Boolean;
    class function CalculateOptimalChunkSize(ADataSize, AWorkerCount: SizeUInt): SizeUInt;
  end;

  { 并行排序任务 }
  TParallelSortTask = class(TInterfacedObject, IParallelTask)
  private
    FData: Pointer;
    FStartIndex, FEndIndex: SizeUInt;
    FCompareFunc: Pointer;
    FUserData: Pointer;
    FSortAlgorithm: Integer;
  public
    constructor Create(AData: Pointer; AStart, AEnd: SizeUInt; 
                      ACompareFunc: Pointer; AUserData: Pointer; ASortAlgorithm: Integer);
    procedure Execute;
    function GetResult: Pointer;
  end;

implementation

{ TWorkerThread }

constructor TWorkerThread.Create;
begin
  inherited Create(False);
  FWorkQueue := TThreadList.Create;
  FEvent := TEvent.Create(nil, False, False, '');
  FTerminating := False;
end;

destructor TWorkerThread.Destroy;
begin
  Terminate;
  FEvent.SetEvent;
  WaitFor;
  FWorkQueue.Free;
  FEvent.Free;
  inherited Destroy;
end;

procedure TWorkerThread.Execute;
var
  LList: TList;
  LWorkItem: TParallelWorkItem;
begin
  while not FTerminating do
  begin
    FEvent.WaitFor(INFINITE);
    
    if FTerminating then
      Break;
      
    LList := FWorkQueue.LockList;
    try
      if LList.Count > 0 then
      begin
        LWorkItem := TParallelWorkItem(LList[0]^);
        LList.Delete(0);
      end
      else
        Continue;
    finally
      FWorkQueue.UnlockList;
    end;
    
    try
      if Assigned(LWorkItem.Task) then
        LWorkItem.Task.Execute;
    except
      // 记录异常但继续执行
    end;
  end;
end;

procedure TWorkerThread.AddWork(const AWorkItem: TParallelWorkItem);
var
  LList: TList;
  LItem: ^TParallelWorkItem;
begin
  New(LItem);
  LItem^ := AWorkItem;
  
  LList := FWorkQueue.LockList;
  try
    LList.Add(LItem);
  finally
    FWorkQueue.UnlockList;
  end;
  
  FEvent.SetEvent;
end;

procedure TWorkerThread.Terminate;
begin
  FTerminating := True;
  inherited Terminate;
end;

{ TThreadPool }

constructor TThreadPool.Create(AWorkerCount: Integer);
var
  i: Integer;
begin
  inherited Create;
  FCriticalSection := TCriticalSection.Create;
  
  if AWorkerCount <= 0 then
    FWorkerCount := TParallelUtils.GetCPUCount
  else
    FWorkerCount := AWorkerCount;
    
  SetLength(FWorkers, FWorkerCount);
  for i := 0 to FWorkerCount - 1 do
    FWorkers[i] := TWorkerThread.Create;
end;

destructor TThreadPool.Destroy;
var
  i: Integer;
begin
  for i := 0 to Length(FWorkers) - 1 do
    FWorkers[i].Free;
  FCriticalSection.Free;
  inherited Destroy;
end;

class function TThreadPool.Instance: TThreadPool;
begin
  if not Assigned(FInstance) then
    FInstance := TThreadPool.Create;
  Result := FInstance;
end;

class procedure TThreadPool.FreeInstance;
begin
  if Assigned(FInstance) then
  begin
    FInstance.Free;
    FInstance := nil;
  end;
end;

procedure TThreadPool.SubmitWork(const AWorkItems: array of TParallelWorkItem);
var
  i, LWorkerIndex: Integer;
begin
  LWorkerIndex := 0;
  for i := 0 to Length(AWorkItems) - 1 do
  begin
    FWorkers[LWorkerIndex].AddWork(AWorkItems[i]);
    LWorkerIndex := (LWorkerIndex + 1) mod FWorkerCount;
  end;
end;

procedure TThreadPool.WaitForCompletion;
var
  i: Integer;
  LAllEmpty: Boolean;
begin
  repeat
    Sleep(1);
    LAllEmpty := True;
    for i := 0 to FWorkerCount - 1 do
    begin
      if FWorkers[i].FWorkQueue.LockList.Count > 0 then
      begin
        LAllEmpty := False;
        FWorkers[i].FWorkQueue.UnlockList;
        Break;
      end;
      FWorkers[i].FWorkQueue.UnlockList;
    end;
  until LAllEmpty;
end;

function TThreadPool.GetWorkerCount: Integer;
begin
  Result := FWorkerCount;
end;

{ TParallelUtils }

class function TParallelUtils.GetCPUCount: Integer;
var
  LCPUStr: String;
begin
  {$IFDEF WINDOWS}
  LCPUStr := GetEnvironmentVariable('NUMBER_OF_PROCESSORS');
  Result := StrToIntDef(LCPUStr, 1);
  if Result <= 0 then
    Result := 1;
  {$ELSE}
  Result := 1; // 简化实现，默认单核
  {$ENDIF}
end;

class function TParallelUtils.ShouldUseParallel(ADataSize: SizeUInt): Boolean;
const
  MIN_PARALLEL_SIZE = 1000; // 最小并行数据大小
begin
  Result := (ADataSize >= MIN_PARALLEL_SIZE) and (GetCPUCount > 1);
end;

class function TParallelUtils.CalculateOptimalChunkSize(ADataSize, AWorkerCount: SizeUInt): SizeUInt;
begin
  if AWorkerCount = 0 then
    AWorkerCount := 1;
  Result := (ADataSize + AWorkerCount - 1) div AWorkerCount;
  if Result < 100 then
    Result := 100; // 最小块大小
end;

{ TParallelSortTask }

constructor TParallelSortTask.Create(AData: Pointer; AStart, AEnd: SizeUInt; 
                                    ACompareFunc: Pointer; AUserData: Pointer; ASortAlgorithm: Integer);
begin
  inherited Create;
  FData := AData;
  FStartIndex := AStart;
  FEndIndex := AEnd;
  FCompareFunc := ACompareFunc;
  FUserData := AUserData;
  FSortAlgorithm := ASortAlgorithm;
end;

procedure TParallelSortTask.Execute;
begin
  // 这里将调用 VecDeque 的排序方法
  // 具体实现将在 VecDeque 中完成
end;

function TParallelSortTask.GetResult: Pointer;
begin
  Result := nil;
end;

initialization

finalization
  TThreadPool.FreeInstance;

end.
