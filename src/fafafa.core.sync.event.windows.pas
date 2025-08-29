unit fafafa.core.sync.event.windows;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  Windows,
  fafafa.core.base, fafafa.core.sync.base, fafafa.core.sync.event.base;

type
  { TEvent
    Windows 平台纯内核事件实现：
    - 自动/手动重置语义由内核对象保证
    - 不引入额外临界区或本地状态
    - IsSignaled：
        * 手动重置：使用零超时 WaitForSingleObject 非破坏式观察
        * 自动重置：无可靠非破坏式观察，固定返回 False（请使用 WaitFor(0) 进行探测） }
  TEvent = class(TInterfacedObject, IEvent)
  private
    FHandle: THandle;
    FManualReset: Boolean;
    FLastError: TWaitError;
    FAtomicInterrupted: Integer;  // 原子中断标志 (0=未中断, 1=已中断)
  public
    constructor Create(AManualReset: Boolean = False; AInitialState: Boolean = False);
    destructor Destroy; override;

    // ISynchronizable
    function GetLastError: TWaitError;

    // IEvent - 基础操作
    procedure SetEvent;
    procedure ResetEvent;
    function WaitFor: TWaitResult; overload;
    function WaitFor(ATimeoutMs: Cardinal): TWaitResult; overload;
    function IsSignaled: Boolean;

    // IEvent - 扩展操作
    function TryWait: Boolean;
    procedure Pulse;
    function IsManualReset: Boolean;
    function GetWaitingThreadCount: Integer;

    // IEvent - 增强的错误处理
    function GetLastErrorMessage: string;
    procedure ClearLastError;

    // IEvent - RAII 守卫方法
    function WaitGuard: IEventGuard;
    function WaitGuard(ATimeoutMs: Cardinal): IEventGuard;
    function TryWaitGuard: IEventGuard;

    // IEvent - 中断支持
    function WaitForInterruptible(ATimeoutMs: Cardinal): TWaitResult;
    procedure Interrupt;
    function IsInterrupted: Boolean;



    // 已移除兼容性方法 - 事件不是锁
  end;

implementation

{ TEvent }

constructor TEvent.Create(AManualReset: Boolean; AInitialState: Boolean);
var
  LastErr: DWORD;
begin
  inherited Create;
  FLastError := weNone;
  FManualReset := AManualReset;

  // 使用 Windows 内核事件对象，无需额外同步开销
  FHandle := Windows.CreateEvent(nil, AManualReset, AInitialState, nil);
  if FHandle = 0 then
  begin
    LastErr := GetLastError;
    case LastErr of
      ERROR_NOT_ENOUGH_MEMORY,
      ERROR_OUTOFMEMORY: FLastError := weResourceExhausted;
      ERROR_ACCESS_DENIED: FLastError := weAccessDenied;
    else
      FLastError := weSystemError;
    end;
    raise ELockError.CreateFmt('CreateEvent failed: %d', [LastErr]);
  end;

  // 初始化中断相关变量
  FAtomicInterrupted := 0;
end;

destructor TEvent.Destroy;
begin
  if FHandle <> 0 then
  begin
    if not CloseHandle(FHandle) then
    begin
      // 析构函数中不应抛异常，只记录错误
      FLastError := weSystemError;
    end;
    FHandle := 0;
  end;
  inherited Destroy;
end;

procedure TEvent.SetEvent;
begin
  if not Windows.SetEvent(FHandle) then
  begin
    FLastError := weSystemError;
    raise ELockError.CreateFmt('SetEvent failed: %d', [GetLastError]);
  end
  else
    FLastError := weNone;
end;

procedure TEvent.ResetEvent;
begin
  if not Windows.ResetEvent(FHandle) then
  begin
    FLastError := weSystemError;
    raise ELockError.CreateFmt('ResetEvent failed: %d', [GetLastError]);
  end
  else
    FLastError := weNone;
end;

function TEvent.WaitFor: TWaitResult;
begin
  Result := WaitFor(INFINITE);
end;

function TEvent.WaitFor(ATimeoutMs: Cardinal): TWaitResult;
var
  wr: DWORD;
  LastErr: DWORD;
begin
  FLastError := weNone;
  wr := WaitForSingleObject(FHandle, ATimeoutMs);
  case wr of
    WAIT_OBJECT_0:
      Exit(wrSignaled);
    WAIT_TIMEOUT:
      Exit(wrTimeout);
    WAIT_ABANDONED:
      begin
        FLastError := weSystemError;
        Exit(wrAbandoned);
      end;
    WAIT_FAILED:
      begin
        LastErr := GetLastError;
        case LastErr of
          ERROR_INVALID_HANDLE: FLastError := weInvalidHandle;
          ERROR_ACCESS_DENIED:  FLastError := weAccessDenied;
        else
          FLastError := weSystemError;
        end;
        Exit(wrError);
      end;
  else
    FLastError := weSystemError;
    Exit(wrError);
  end;
end;

function TEvent.IsSignaled: Boolean;
var wr: DWORD;
begin
  if FManualReset then
  begin
    // 手动重置事件：使用零超时非破坏式检查
    wr := WaitForSingleObject(FHandle, 0);
    case wr of
      WAIT_OBJECT_0:
        begin
          FLastError := weNone;
          Result := True;
        end;
      WAIT_TIMEOUT:
        begin
          FLastError := weNone;
          Result := False;
        end;
    else
      // 出错时保守返回 False
      FLastError := weSystemError;
      Result := False;
    end;
  end
  else
  begin
    // 自动重置事件无法非破坏式探测是否为信号状态。
    // 为避免副作用（消耗信号），这里固定返回 False。
    // 如需检测，请使用 TryWait() 方法。
    FLastError := weNone;
    Result := False;
  end;
end;

{ 已移除的兼容性方法实现 - 事件不是锁
  如需这些功能，请使用：
  - WaitFor() 替代 Acquire()
  - TryWait() 替代 TryAcquire()
  - SetEvent()/ResetEvent() 替代 Release()
}

{ ISynchronizable 实现 }
function TEvent.GetLastError: TWaitError;
begin
  Result := FLastError;
end;

{ IEvent 扩展方法实现 }
function TEvent.TryWait: Boolean;
var
  WaitResult: TWaitResult;
begin
  WaitResult := WaitFor(0);
  Result := WaitResult = wrSignaled;
  // 对于超时情况，清除错误状态（这是正常的非阻塞行为）
  if WaitResult = wrTimeout then
    FLastError := weNone;
end;

procedure TEvent.Pulse;
begin
  // Windows 平台 Pulse 实现说明：
  // PulseEvent API 已被弃用且不可靠，我们提供基于 SetEvent 的实现
  // 注意：这个实现有固有的竞态条件，无法完全避免
  // 建议使用者考虑使用其他同步原语（如条件变量）来替代 Pulse 语义

  if not Windows.SetEvent(FHandle) then
  begin
    FLastError := weSystemError;
    Exit;
  end;

  // 对于自动重置事件，SetEvent 后会自动重置，无需手动操作
  // 对于手动重置事件，需要立即重置以模拟 Pulse 行为
  if FManualReset then
  begin
    // 使用 SwitchToThread 而不是 Sleep(0)，更精确的线程调度控制
    // 这给等待的线程一个被调度的机会，但仍然无法完全消除竞态条件
    SwitchToThread;

    if not Windows.ResetEvent(FHandle) then
    begin
      FLastError := weSystemError;
      Exit;
    end;
  end;

  FLastError := weNone;
end;

function TEvent.IsManualReset: Boolean;
begin
  Result := FManualReset;
end;

function TEvent.GetWaitingThreadCount: Integer;
begin
  // Windows 没有直接的 API 获取等待线程数
  // 设置错误码表示此功能不支持，返回 0
  FLastError := weNotSupported;
  Result := 0;
end;

{ IEvent 增强的错误处理实现 }
function TEvent.GetLastErrorMessage: string;
begin
  case FLastError of
    weNone:              Result := 'No error';
    weTimeout:           Result := 'Operation timed out';
    weInvalidHandle:     Result := 'Invalid handle';
    weResourceExhausted: Result := 'System resources exhausted';
    weAccessDenied:      Result := 'Access denied';
    weDeadlock:          Result := 'Deadlock detected';
    weNotSupported:      Result := 'Operation not supported on this platform';
    weSystemError:       Result := 'System error';
  else
    Result := 'Unknown error';
  end;
end;

procedure TEvent.ClearLastError;
begin
  FLastError := weNone;
end;

{ IEvent RAII 守卫方法实现 }
function TEvent.WaitGuard: IEventGuard;
begin
  Result := WaitGuard(INFINITE);
end;

function TEvent.WaitGuard(ATimeoutMs: Cardinal): IEventGuard;
var
  WaitResult: TWaitResult;
begin
  WaitResult := WaitFor(ATimeoutMs);
  Result := TEventGuard.Create(Self, WaitResult = wrSignaled);
end;

function TEvent.TryWaitGuard: IEventGuard;
begin
  Result := WaitGuard(0);
end;

{ IEvent 中断支持实现 }
function TEvent.WaitForInterruptible(ATimeoutMs: Cardinal): TWaitResult;
var
  WaitResult: DWORD;
begin
  // 使用原子操作检查中断状态，确保内存可见性
  if InterlockedCompareExchange(FAtomicInterrupted, 0, 0) <> 0 then
  begin
    FLastError := weNone;
    Exit(wrAbandoned); // 使用 wrAbandoned 表示中断
  end;

  // Windows 下的可中断等待实现
  // 注意：Windows 事件对象本身不支持中断，这里提供基础实现
  WaitResult := WaitForSingleObject(FHandle, ATimeoutMs);

  case WaitResult of
    WAIT_OBJECT_0:
    begin
      // 再次检查中断状态，因为可能在等待期间被中断
      // 使用原子操作确保内存可见性
      if InterlockedCompareExchange(FAtomicInterrupted, 0, 0) <> 0 then
      begin
        FLastError := weNone;
        Result := wrAbandoned;
      end
      else
      begin
        FLastError := weNone;
        Result := wrSignaled;
      end;
    end;
    WAIT_TIMEOUT:
    begin
      FLastError := weTimeout;
      Result := wrTimeout;
    end;
    WAIT_ABANDONED:
    begin
      FLastError := weNone;
      Result := wrAbandoned;
    end;
  else
    FLastError := weSystemError;
    Result := wrError;
  end;
end;

procedure TEvent.Interrupt;
begin
  // 使用原子操作设置中断标志，确保所有线程立即可见
  // 这里不再需要 FInterrupted 布尔变量，直接使用原子变量
  InterlockedExchange(FAtomicInterrupted, 1);

  // Windows 下通过设置事件来"中断"等待
  // 注意：这不是真正的中断，而是通过信号唤醒等待的线程
  // 等待的线程需要检查中断状态来确定是否被中断
  if not Windows.SetEvent(FHandle) then
    FLastError := weSystemError;
end;

function TEvent.IsInterrupted: Boolean;
begin
  // 使用无锁快速路径检查中断状态
  Result := InterlockedCompareExchange(FAtomicInterrupted, 0, 0) <> 0;
end;



end.