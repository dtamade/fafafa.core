unit fafafa.core.sync.latch.windows;

{$mode objfpc}
{$I fafafa.core.settings.inc}

{
  Windows 平台 CountDownLatch 实现

  实现策略：
  - 计数器存储当前计数
  - TRTLCriticalSection 保护计数器更新
  - 手动重置事件 (Manual Reset Event) 进行等待/唤醒
  - 当计数变为 0 时设置事件，唤醒所有等待者
  - 与 WaitGroup 不同，计数只能减少不能增加
}

interface

uses
  Windows, SysUtils,
  fafafa.core.sync.base, fafafa.core.sync.latch.base,
  fafafa.core.time.duration;

type
  TLatch = class(TSynchronizable, ILatch)
  private
    FCount: LongInt;
    FCS: TRTLCriticalSection;
    FEvent: THandle;
    FLastError: TWaitError;
  public
    constructor Create(ACount: Integer);
    destructor Destroy; override;

    // ISynchronizable
    function GetLastError: TWaitError;

    // ILatch
    procedure CountDown;
    procedure Await;
    function AwaitTimeout(ATimeoutMs: Cardinal): Boolean;
    function AwaitDuration(const ADuration: TDuration): TWaitResult;
    function GetCount: Integer;
  end;

function MakeLatch(ACount: Integer): ILatch;

implementation

resourcestring
  rsLatchNegativeCount = 'Latch: initial count cannot be negative';
  rsLatchInitFailed = 'Latch: failed to initialize';

{ TLatch }

constructor TLatch.Create(ACount: Integer);
begin
  inherited Create;

  if ACount < 0 then
    raise EInvalidArgument.Create(rsLatchNegativeCount);

  FCount := ACount;
  FLastError := weNone;

  // 初始化临界区
  InitializeCriticalSection(FCS);

  // 创建手动重置事件
  // 如果初始计数为 0，则事件初始为有信号状态
  if ACount = 0 then
    FEvent := CreateEventW(nil, True, True, nil)
  else
    FEvent := CreateEventW(nil, True, False, nil);

  if FEvent = 0 then
  begin
    DeleteCriticalSection(FCS);
    raise ELockError.Create(rsLatchInitFailed);
  end;
end;

destructor TLatch.Destroy;
begin
  if FEvent <> 0 then
    CloseHandle(FEvent);
  DeleteCriticalSection(FCS);
  inherited Destroy;
end;

function TLatch.GetLastError: TWaitError;
begin
  Result := FLastError;
end;

procedure TLatch.CountDown;
begin
  EnterCriticalSection(FCS);
  try
    // 只有计数大于 0 时才减少
    if FCount > 0 then
    begin
      Dec(FCount);
      // 如果计数变为 0，唤醒所有等待者
      if FCount = 0 then
        SetEvent(FEvent);
    end;
  finally
    LeaveCriticalSection(FCS);
  end;
end;

procedure TLatch.Await;
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

function TLatch.AwaitTimeout(ATimeoutMs: Cardinal): Boolean;
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

function TLatch.GetCount: Integer;
begin
  Result := FCount;
end;

function TLatch.AwaitDuration(const ADuration: TDuration): TWaitResult;
var
  TimeoutMs: Int64;
begin
  // 将 TDuration 转换为毫秒
  TimeoutMs := ADuration.AsMs;
  if TimeoutMs < 0 then
    TimeoutMs := 0;

  if AwaitTimeout(Cardinal(TimeoutMs)) then
    Result := wrSignaled
  else
    Result := wrTimeout;
end;

function MakeLatch(ACount: Integer): ILatch;
begin
  Result := TLatch.Create(ACount);
end;

end.
