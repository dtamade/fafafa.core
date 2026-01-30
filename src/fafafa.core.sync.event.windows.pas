unit fafafa.core.sync.event.windows;

{
┌──────────────────────────────────────────────────────────────────────────────┐
│                                                                              │
│          ______   ______     ______   ______     ______   ______             │
│         /\  ___\ /\  __ \   /\  ___\ /\  __ \   /\  ___\ /\  __ \            │
│         \ \  __\ \ \  __ \  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \           │
│          \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\          │
│           \/_/     \/_/\/_/   \/_/     \/_/\/_/   \/_/     \/_/\/_/          │
│                                                                              │
│                                Studio                                        │
└──────────────────────────────────────────────────────────────────────────────┘

📦 项目：fafafa.core.sync.event - 高性能事件同步原语实现

📖 概述：
  现代化、跨平台的 FreePascal 事件同步原语实现（Windows 平台）。

🔧 特性：
  • Windows 平台：基于内核事件对象的高效实现
  • 零开销：直接使用 Windows API，无额外用户态开销
  • 线程安全：由操作系统内核保证线程安全性
  • 双模式支持：自动重置和手动重置事件
  • 超时控制：支持无限等待和带超时的等待
  • 非阻塞检查：TryWait 方法提供非阻塞状态检查
  • 资源管理：自动句柄清理，异常安全

⚠️  重要说明：
  本文件为 Windows 平台的具体实现，使用 Windows 内核事件对象。
  自动重置事件一次信号只唤醒一个等待者，手动重置事件唤醒所有等待者。

🧵 线程安全性：
  所有事件操作都是线程安全的，可以从多个线程同时调用。

📜 声明：
  转发或用于个人/商业项目时，请保留本项目的版权声明。

👤 author  : fafafaStudio
📧 Email   : dtamade@gmail.com
💬 QQGroup : 685403987
💬 QQ      : 179033731

}

{$mode objfpc}
{$I fafafa.core.settings.inc}

interface

uses
  Windows,
  fafafa.core.sync.base, fafafa.core.sync.event.base;

type
  { TEvent
    Windows 平台纯内核事件实现：
    - 自动/手动重置语义由内核对象保证
    - 不引入额外临界区或本地状态
    - 使用 TryWait 进行非阻塞探测 }
  TEvent = class(TSynchronizable, IEvent)
  private
    FHandle: THandle;
    FManualReset: Boolean;
  public
    constructor Create(AManualReset: Boolean = False; AInitialState: Boolean = False);
    destructor Destroy; override;

    // IEvent - 基础操作
    procedure SetEvent;
    procedure ResetEvent;
    function Wait: TWaitResult; overload;
    function WaitFor: TWaitResult; overload;
    function WaitFor(ATimeoutMs: Cardinal): TWaitResult; overload;

    // IEvent - 扩展操作
    function TryWait: Boolean;
    function IsSignaled: Boolean;
    function IsManualReset: Boolean;

    // IEvent - 跨平台别名
    procedure Signal;  // SetEvent 别名
    procedure Clear;   // ResetEvent 别名
  end;

implementation

{ TEvent }

constructor TEvent.Create(AManualReset: Boolean; AInitialState: Boolean);
begin
  inherited Create;
  FManualReset := AManualReset;

  // 使用 Windows 内核事件对象，无需额外同步开销
  FHandle := Windows.CreateEvent(nil, AManualReset, AInitialState, nil);
  if FHandle = 0 then
    raise ELockError.CreateFmt('CreateEvent failed: %d', [GetLastError]);
end;

destructor TEvent.Destroy;
begin
  if FHandle <> 0 then
  begin
    CloseHandle(FHandle);
    FHandle := 0;
  end;
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
var
  wr: DWORD;
begin
  wr := WaitForSingleObject(FHandle, ATimeoutMs);
  case wr of
    WAIT_OBJECT_0:
      Exit(wrSignaled);
    WAIT_TIMEOUT:
      Exit(wrTimeout);
    WAIT_ABANDONED:
      Exit(wrAbandoned);
    WAIT_FAILED:
      Exit(wrError);
  else
    Exit(wrError);
  end;
end;

function TEvent.TryWait: Boolean;
begin
  Result := WaitFor(0) = wrSignaled;
end;

function TEvent.IsManualReset: Boolean;
begin
  Result := FManualReset;
end;

function TEvent.Wait: TWaitResult;
begin
  // Wait is an alias for WaitFor with infinite timeout
  Result := WaitFor(INFINITE);
end;

function TEvent.IsSignaled: Boolean;
begin
  // Non-blocking check if event is signaled
  // Use WaitForSingleObject with 0 timeout for immediate return
  Result := WaitForSingleObject(FHandle, 0) = WAIT_OBJECT_0;

  // For manual reset events, if signaled, restore the signaled state
  // since WaitForSingleObject would have consumed it for auto-reset events
  if Result and (not FManualReset) then
  begin
    // For auto-reset events, the signal was consumed by the check
    // We need to re-signal it to maintain state consistency
    Windows.SetEvent(FHandle);
  end;
end;

procedure TEvent.Signal;
begin
  SetEvent;
end;

procedure TEvent.Clear;
begin
  ResetEvent;
end;

end.
