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
  public
    constructor Create(AManualReset: Boolean = False; AInitialState: Boolean = False);
    destructor Destroy; override;
    // IEvent
    procedure SetEvent;
    procedure ResetEvent;
    function WaitFor: TWaitResult; overload;
    function WaitFor(ATimeoutMs: Cardinal): TWaitResult; overload;
    function IsSignaled: Boolean;
    // ILock
    procedure Acquire;
    procedure Release;
    function TryAcquire: Boolean;
  end;

implementation

{ TEvent }

constructor TEvent.Create(AManualReset: Boolean; AInitialState: Boolean);
begin
  inherited Create;
  FHandle := Windows.CreateEvent(nil, AManualReset, AInitialState, nil);
  if FHandle = 0 then
    raise ELockError.CreateFmt('CreateEvent failed: %d', [GetLastError]);
  FManualReset := AManualReset;
end;

destructor TEvent.Destroy;
begin
  if FHandle <> 0 then
    CloseHandle(FHandle);
  inherited Destroy;
end;

procedure TEvent.SetEvent;
begin
  if not Windows.SetEvent(FHandle) then
    raise ELockError.CreateFmt('SetEvent failed: %d', [GetLastError]);
end;

procedure TEvent.ResetEvent;
begin
  if not Windows.ResetEvent(FHandle) then
    raise ELockError.CreateFmt('ResetEvent failed: %d', [GetLastError]);
end;

function TEvent.WaitFor: TWaitResult;
begin
  Result := WaitFor(INFINITE);
end;

function TEvent.WaitFor(ATimeoutMs: Cardinal): TWaitResult;
var wr: DWORD;
begin
  wr := WaitForSingleObject(FHandle, ATimeoutMs);
  case wr of
    WAIT_OBJECT_0: Exit(wrSignaled);
    WAIT_TIMEOUT:  Exit(wrTimeout);
    WAIT_FAILED:   Exit(wrError);
  else
    Exit(wrError);
  end;
end;

function TEvent.IsSignaled: Boolean;
var wr: DWORD;
begin
  if FManualReset then
  begin
    wr := WaitForSingleObject(FHandle, 0);
    Exit(wr = WAIT_OBJECT_0);
  end
  else
  begin
    // 自动重置事件无法非破坏式探测是否为信号状态。
    // 为避免副作用（消耗信号），这里固定返回 False。
    Result := False;
  end;
end;

procedure TEvent.Acquire;
begin
  if WaitFor(INFINITE) <> wrSignaled then
    raise ELockError.Create('Event acquire (wait) failed');
end;

procedure TEvent.Release;
begin
  // Event 不是互斥量，Release 不应改变状态；使用 ResetEvent 控制手动重置
end;

function TEvent.TryAcquire: Boolean;
begin
  Result := WaitFor(0) = wrSignaled;
end;

end.

