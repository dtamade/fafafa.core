unit fafafa.core.sync.once.unix;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, BaseUnix, Unix, UnixType, pthreads,
  fafafa.core.base, fafafa.core.sync.base, fafafa.core.sync.once.base;

type
  // 用于存储回调信息的记录
  TOnceCallbackType = (octNone, octProc, octMethod, octAnonymous);

  TOnceCallbackInfo = record
    Proc: TOnceProc;
    Method: TOnceMethod;
    AnonymousProc: TOnceAnonymousProc;
    CallbackType: TOnceCallbackType;
  end;
  POnceCallbackInfo = ^TOnceCallbackInfo;

  TOnce = class(TInterfacedObject, IOnce)
  private
    FOnceControl: pthread_once_t;
    FCallbackInfo: TOnceCallbackInfo;
    FMutex: pthread_mutex_t;
    FCompleted: Boolean;

    // pthread_once 要求的静态回调函数
    class procedure StaticOnceCallback; cdecl; static;

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

// 全局变量用于在静态回调中访问当前实例
threadvar
  GCurrentOnceInstance: TOnce;

implementation

{ TOnce }

constructor TOnce.Create;
begin
  inherited Create;
  FOnceControl := PTHREAD_ONCE_INIT;
  FCompleted := False;

  // 初始化互斥锁
  if pthread_mutex_init(@FMutex, nil) <> 0 then
    raise ELockError.Create('Failed to initialize pthread mutex for Once');

  // 初始化回调信息
  FillChar(FCallbackInfo, SizeOf(FCallbackInfo), 0);
  FCallbackInfo.CallbackType := octNone;
end;

constructor TOnce.Create(const AProc: TOnceProc);
begin
  inherited Create;
  FOnceControl := PTHREAD_ONCE_INIT;
  FCompleted := False;

  // 初始化互斥锁
  if pthread_mutex_init(@FMutex, nil) <> 0 then
    raise ELockError.Create('Failed to initialize pthread mutex for Once');

  // 初始化回调信息
  FillChar(FCallbackInfo, SizeOf(FCallbackInfo), 0);
  FCallbackInfo.Proc := AProc;
  FCallbackInfo.CallbackType := octProc;
end;

constructor TOnce.Create(const AMethod: TOnceMethod);
begin
  inherited Create;
  FOnceControl := PTHREAD_ONCE_INIT;
  FCompleted := False;

  // 初始化互斥锁
  if pthread_mutex_init(@FMutex, nil) <> 0 then
    raise ELockError.Create('Failed to initialize pthread mutex for Once');

  // 初始化回调信息
  FillChar(FCallbackInfo, SizeOf(FCallbackInfo), 0);
  FCallbackInfo.Method := AMethod;
  FCallbackInfo.CallbackType := octMethod;
end;

constructor TOnce.Create(const AAnonymousProc: TOnceAnonymousProc);
begin
  inherited Create;
  FOnceControl := PTHREAD_ONCE_INIT;
  FCompleted := False;

  // 初始化互斥锁
  if pthread_mutex_init(@FMutex, nil) <> 0 then
    raise ELockError.Create('Failed to initialize pthread mutex for Once');

  // 初始化回调信息
  FillChar(FCallbackInfo, SizeOf(FCallbackInfo), 0);
  FCallbackInfo.AnonymousProc := AAnonymousProc;
  FCallbackInfo.CallbackType := octAnonymous;
end;

destructor TOnce.Destroy;
begin
  // 销毁互斥锁
  pthread_mutex_destroy(@FMutex);
  inherited Destroy;
end;

class procedure TOnce.StaticOnceCallback; cdecl;
var
  Instance: TOnce;
begin
  Instance := GCurrentOnceInstance;
  if Assigned(Instance) then
  begin
    try
      // 执行用户回调
      case Instance.FCallbackInfo.CallbackType of
        octProc:
          if Assigned(Instance.FCallbackInfo.Proc) then
            Instance.FCallbackInfo.Proc();
        octMethod:
          if Assigned(Instance.FCallbackInfo.Method) then
            Instance.FCallbackInfo.Method();
        octAnonymous:
          if Assigned(Instance.FCallbackInfo.AnonymousProc) then
            Instance.FCallbackInfo.AnonymousProc();
        octNone:
          ; // 无回调，什么都不做
      end;

      // 标记为已完成
      pthread_mutex_lock(@Instance.FMutex);
      try
        Instance.FCompleted := True;
      finally
        pthread_mutex_unlock(@Instance.FMutex);
      end;
    except
      // 如果回调执行失败，我们无法重置 pthread_once_t
      // 但可以标记状态，让后续调用知道执行失败了
      pthread_mutex_lock(@Instance.FMutex);
      try
        Instance.FCompleted := False;
      finally
        pthread_mutex_unlock(@Instance.FMutex);
      end;
      raise;
    end;
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
  pthread_mutex_lock(@FMutex);
  try
    Result := FCompleted;
  finally
    pthread_mutex_unlock(@FMutex);
  end;

  if not Result then
  begin
    // 尝试执行一次性操作
    try
      Execute;
      Result := True;
    except
      Result := False;
    end;
  end;
end;

// IOnce 核心接口实现
procedure TOnce.Execute;
begin
  // 对于 once 语义，Execute 执行存储的回调（如果有的话）
  if FCallbackInfo.CallbackType <> octNone then
  begin
    // 设置当前实例到线程局部变量
    GCurrentOnceInstance := Self;

    // 调用 pthread_once
    if pthread_once(@FOnceControl, @StaticOnceCallback) <> 0 then
      raise ELockError.Create('pthread_once failed in Execute');
  end
  else
  begin
    // 如果没有存储的回调，只是标记为已完成
    pthread_mutex_lock(@FMutex);
    try
      FCompleted := True;
    finally
      pthread_mutex_unlock(@FMutex);
    end;
  end;
end;



function TOnce.GetState: TOnceState;
var
  Completed: Boolean;
begin
  pthread_mutex_lock(@FMutex);
  try
    Completed := FCompleted;
  finally
    pthread_mutex_unlock(@FMutex);
  end;
  
  if Completed then
    Result := osCompleted
  else
  begin
    // pthread_once 不提供直接的方式检查是否正在进行
    // 我们简化为只有两种状态：未开始或已完成
    Result := osNotStarted;
  end;
end;

function TOnce.IsCompleted: Boolean;
begin
  pthread_mutex_lock(@FMutex);
  try
    Result := FCompleted;
  finally
    pthread_mutex_unlock(@FMutex);
  end;
end;

function TOnce.IsInProgress: Boolean;
begin
  // pthread_once 不提供检查进行中状态的方法
  // 返回 False，表示我们无法确定
  Result := False;
end;

procedure TOnce.Reset;
begin
  pthread_mutex_lock(@FMutex);
  try
    // 注意：pthread_once_t 一旦被调用就无法重置
    // 这个方法主要用于测试，实际使用中应该避免
    // 我们只能重置我们自己的状态标志
    FCompleted := False;
    FOnceControl := PTHREAD_ONCE_INIT;
    FillChar(FCallbackInfo, SizeOf(FCallbackInfo), 0);
    FCallbackInfo.CallbackType := octNone;
  finally
    pthread_mutex_unlock(@FMutex);
  end;
end;

end.
