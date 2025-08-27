unit fafafa.core.sync.once.windows;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  Windows, SysUtils,
  fafafa.core.base, fafafa.core.sync.base, fafafa.core.sync.once.base, fafafa.core.atomic;

type
  TOnce = class(TInterfacedObject, IOnce)
  private
    FState: LongInt;  // 0=NotStarted, 1=InProgress, 2=Completed
    FLock: TRTLCriticalSection;
    FStoredProc: TOnceProc;
    FStoredMethod: TOnceMethod;
    FStoredAnonymousProc: TOnceAnonymousProc;
    FCallbackType: (ctNone, ctProc, ctMethod, ctAnonymous);

    const
      STATE_NOT_STARTED = 0;
      STATE_IN_PROGRESS = 1;
      STATE_COMPLETED = 2;

    procedure ExecuteStoredCallback;

  public
    constructor Create; overload;
    constructor Create(const AProc: TOnceProc); overload;
    constructor Create(const AMethod: TOnceMethod); overload;
    constructor Create(const AAnonymousProc: TOnceAnonymousProc); overload;
    destructor Destroy; override;

    // ILock 接口实现
    procedure Acquire;
    procedure Release;
    function TryAcquire: Boolean;

    // IOnce 核心接口实现
    procedure Execute;
    function GetState: TOnceState;
    function IsCompleted: Boolean;
    function IsInProgress: Boolean;
    procedure Reset;
  end;

implementation

{ TOnce }

constructor TOnce.Create;
begin
  inherited Create;
  FState := STATE_NOT_STARTED;
  FStoredProc := nil;
  FStoredMethod := nil;
  FStoredAnonymousProc := nil;
  FCallbackType := ctNone;
  InitializeCriticalSection(FLock);
end;

constructor TOnce.Create(const AProc: TOnceProc);
begin
  inherited Create;
  FState := STATE_NOT_STARTED;
  FStoredProc := AProc;
  FStoredMethod := nil;
  FStoredAnonymousProc := nil;
  FCallbackType := ctProc;
  InitializeCriticalSection(FLock);
end;

constructor TOnce.Create(const AMethod: TOnceMethod);
begin
  inherited Create;
  FState := STATE_NOT_STARTED;
  FStoredProc := nil;
  FStoredMethod := AMethod;
  FStoredAnonymousProc := nil;
  FCallbackType := ctMethod;
  InitializeCriticalSection(FLock);
end;

constructor TOnce.Create(const AAnonymousProc: TOnceAnonymousProc);
begin
  inherited Create;
  FState := STATE_NOT_STARTED;
  FStoredProc := nil;
  FStoredMethod := nil;
  FStoredAnonymousProc := AAnonymousProc;
  FCallbackType := ctAnonymous;
  InitializeCriticalSection(FLock);
end;

destructor TOnce.Destroy;
begin
  DeleteCriticalSection(FLock);
  inherited Destroy;
end;

procedure TOnce.ExecuteStoredCallback;
begin
  case FCallbackType of
    ctProc:
      if Assigned(FStoredProc) then
        FStoredProc();
    ctMethod:
      if Assigned(FStoredMethod) then
        FStoredMethod();
    ctAnonymous:
      if Assigned(FStoredAnonymousProc) then
        FStoredAnonymousProc();
    ctNone:
      ; // 无回调，什么都不做
  end;
end;

// ILock 接口实现
procedure TOnce.Acquire;
begin
  // Acquire 等同于 Execute
  Execute;
end;

procedure TOnce.Release;
begin
  // 对于 once 语义，Release 是空操作
  // 一旦执行完成，就不能"释放"
end;

function TOnce.TryAcquire: Boolean;
begin
  // 如果已经完成，立即返回 True
  if InterlockedCompareExchange(FState, FState, STATE_COMPLETED) = STATE_COMPLETED then
  begin
    Result := True;
    Exit;
  end;

  // 尝试执行一次性操作
  try
    Execute;
    Result := True;
  except
    Result := False;
  end;
end;

// IOnce 核心接口实现
procedure TOnce.Execute;
begin
  // 快速路径：如果已完成，直接返回
  if InterlockedCompareExchange(FState, FState, STATE_COMPLETED) = STATE_COMPLETED then
    Exit;

  // 慢速路径：需要同步
  EnterCriticalSection(FLock);
  try
    // 双重检查锁定模式
    case FState of
      STATE_NOT_STARTED:
        begin
          // 标记为进行中
          InterlockedExchange(FState, STATE_IN_PROGRESS);
          try
            // 执行存储的回调
            ExecuteStoredCallback;
            // 标记为已完成
            InterlockedExchange(FState, STATE_COMPLETED);
          except
            // 如果执行失败，重置状态以允许重试
            InterlockedExchange(FState, STATE_NOT_STARTED);
            raise;
          end;
        end;
      STATE_IN_PROGRESS:
        begin
          // 另一个线程正在执行，等待完成
          repeat
            LeaveCriticalSection(FLock);
            Sleep(1); // 短暂等待
            EnterCriticalSection(FLock);
          until FState = STATE_COMPLETED;
        end;
      STATE_COMPLETED:
        begin
          // 已完成，什么都不做
        end;
    end;
  finally
    LeaveCriticalSection(FLock);
  end;
end;



function TOnce.GetState: TOnceState;
begin
  case InterlockedCompareExchange(FState, FState, FState) of
    STATE_NOT_STARTED: Result := osNotStarted;
    STATE_IN_PROGRESS: Result := osInProgress;
    STATE_COMPLETED: Result := osCompleted;
  else
    Result := osNotStarted; // 默认值
  end;
end;

function TOnce.IsCompleted: Boolean;
begin
  Result := InterlockedCompareExchange(FState, FState, STATE_COMPLETED) = STATE_COMPLETED;
end;

function TOnce.IsInProgress: Boolean;
begin
  Result := InterlockedCompareExchange(FState, FState, STATE_IN_PROGRESS) = STATE_IN_PROGRESS;
end;

procedure TOnce.Reset;
begin
  EnterCriticalSection(FLock);
  try
    InterlockedExchange(FState, STATE_NOT_STARTED);
    FStoredProc := nil;
    FStoredMethod := nil;
    FStoredAnonymousProc := nil;
    FCallbackType := ctNone;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

end.
