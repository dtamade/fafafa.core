unit fafafa.core.sync.waitgroup.windows;

{$mode objfpc}
{$I fafafa.core.settings.inc}

{
  Windows 平台 WaitGroup 实现

  实现策略：
  - 原子计数器存储当前等待数量
  - TRTLCriticalSection 保护计数器更新
  - 手动重置事件 (Manual Reset Event) 进行等待/唤醒
  - 当计数变为 0 时设置事件，唤醒所有等待者

  性能特性：
  - Add/Done: 临界区保护 + 原子操作
  - Wait: 快速路径检查 + WaitForSingleObject 阻塞
  - 低竞争场景几乎无开销
}

interface

uses
  Windows, SysUtils,
  fafafa.core.sync.base, fafafa.core.sync.waitgroup.base,
  fafafa.core.time.duration;

type
  TWaitGroup = class(TSynchronizable, IWaitGroup)
  private
    FCount: LongInt;                    // 计数器
    FCS: TRTLCriticalSection;           // 保护计数器
    FEvent: THandle;                    // 手动重置事件
    FLastError: TWaitError;

    procedure CheckNonNegative(ANewCount: LongInt);
    procedure UpdateEventState;
  public
    constructor Create;
    destructor Destroy; override;

    // ISynchronizable
    function GetLastError: TWaitError;

    // IWaitGroup
    procedure Add(ADelta: Integer);
    procedure Done;
    procedure Wait;
    function WaitTimeout(ATimeoutMs: Cardinal): Boolean;
    function WaitDuration(const ADuration: TDuration): TWaitResult;
    function GetCount: Integer;
  end;

function MakeWaitGroup: IWaitGroup;

implementation

resourcestring
  rsWaitGroupNegativeCount = 'WaitGroup: negative count';
  rsWaitGroupInitFailed = 'WaitGroup: failed to initialize';

{ TWaitGroup }

constructor TWaitGroup.Create;
begin
  inherited Create;
  FCount := 0;
  FLastError := weNone;

  // 初始化临界区
  InitializeCriticalSection(FCS);

  // 创建手动重置事件，初始状态为有信号（计数为 0）
  FEvent := CreateEventW(nil, True, True, nil);
  if FEvent = 0 then
  begin
    DeleteCriticalSection(FCS);
    raise ELockError.Create(rsWaitGroupInitFailed);
  end;
end;

destructor TWaitGroup.Destroy;
begin
  if FEvent <> 0 then
    CloseHandle(FEvent);
  DeleteCriticalSection(FCS);
  inherited Destroy;
end;

function TWaitGroup.GetLastError: TWaitError;
begin
  Result := FLastError;
end;

procedure TWaitGroup.CheckNonNegative(ANewCount: LongInt);
begin
  if ANewCount < 0 then
    raise EInvalidArgument.Create(rsWaitGroupNegativeCount);
end;

procedure TWaitGroup.UpdateEventState;
begin
  // 必须在临界区内调用
  if FCount = 0 then
    SetEvent(FEvent)      // 唤醒所有等待者
  else
    ResetEvent(FEvent);   // 阻塞等待者
end;

procedure TWaitGroup.Add(ADelta: Integer);
var
  NewCount: LongInt;
begin
  EnterCriticalSection(FCS);
  try
    NewCount := FCount + ADelta;
    CheckNonNegative(NewCount);
    FCount := NewCount;
    UpdateEventState;
  finally
    LeaveCriticalSection(FCS);
  end;
end;

procedure TWaitGroup.Done;
begin
  Add(-1);
end;

procedure TWaitGroup.Wait;
var
  WaitResult: DWORD;
begin
  // 快速路径：检查计数是否已为 0
  EnterCriticalSection(FCS);
  try
    if FCount = 0 then
    begin
      FLastError := weNone;
      Exit;
    end;
  finally
    LeaveCriticalSection(FCS);
  end;

  // 慢速路径：等待事件
  WaitResult := WaitForSingleObject(FEvent, INFINITE);
  case WaitResult of
    WAIT_OBJECT_0:
      FLastError := weNone;
    WAIT_FAILED:
      FLastError := weSystemError;
    else
      FLastError := weSystemError;
  end;
end;

function TWaitGroup.WaitTimeout(ATimeoutMs: Cardinal): Boolean;
var
  WaitResult: DWORD;
begin
  // 快速路径：检查计数是否已为 0
  EnterCriticalSection(FCS);
  try
    if FCount = 0 then
    begin
      FLastError := weNone;
      Exit(True);
    end;
  finally
    LeaveCriticalSection(FCS);
  end;

  // 慢速路径：带超时等待
  WaitResult := WaitForSingleObject(FEvent, ATimeoutMs);
  case WaitResult of
    WAIT_OBJECT_0:
    begin
      FLastError := weNone;
      Result := True;
    end;
    WAIT_TIMEOUT:
    begin
      FLastError := weTimeout;
      Result := False;
    end;
    WAIT_FAILED:
    begin
      FLastError := weSystemError;
      Result := False;
    end;
    else
    begin
      FLastError := weSystemError;
      Result := False;
    end;
  end;
end;

function TWaitGroup.GetCount: Integer;
begin
  // 原子读取（在 x86/x64 上对齐的 32 位读取是原子的）
  Result := FCount;
end;

function TWaitGroup.WaitDuration(const ADuration: TDuration): TWaitResult;
var
  TimeoutMs: Int64;
begin
  // 将 TDuration 转换为毫秒
  TimeoutMs := ADuration.AsMs;
  if TimeoutMs < 0 then
    TimeoutMs := 0;

  if WaitTimeout(Cardinal(TimeoutMs)) then
    Result := wrSignaled
  else
    Result := wrTimeout;
end;

function MakeWaitGroup: IWaitGroup;
begin
  Result := TWaitGroup.Create;
end;

end.
