unit fafafa.core.sync.parker.windows;

{$mode objfpc}
{$I fafafa.core.settings.inc}

{
  Windows 平台 Parker 实现

  实现策略：
  - 布尔 permit 标志表示许可状态
  - TRTLCriticalSection 保护状态
  - 自动重置事件 (Auto Reset Event) 进行等待/唤醒
  - Unpark 设置 permit 并 signal
  - Park 检查并消费 permit，或等待

  性能特性：
  - 无许可时快速路径检查
  - 低开销的 permit 机制
}

interface

uses
  Windows, SysUtils,
  fafafa.core.sync.base, fafafa.core.sync.parker.base,
  fafafa.core.time.duration;

type
  TParker = class(TSynchronizable, IParker)
  private
    FPermit: Boolean;                   // 许可标志
    FCS: TRTLCriticalSection;           // 保护状态
    FEvent: THandle;                    // 自动重置事件
    FLastError: TWaitError;
  public
    constructor Create;
    destructor Destroy; override;

    // ISynchronizable
    function GetLastError: TWaitError;

    // IParker
    procedure Park;
    function ParkTimeout(ATimeoutMs: Cardinal): Boolean;
    function ParkDuration(const ADuration: TDuration): TWaitResult;
    procedure Unpark;
  end;

function MakeParker: IParker;

implementation

resourcestring
  rsParkerInitFailed = 'Parker: failed to initialize';

{ TParker }

constructor TParker.Create;
begin
  inherited Create;
  FPermit := False;
  FLastError := weNone;

  // 初始化临界区
  InitializeCriticalSection(FCS);

  // 创建自动重置事件，初始状态为无信号
  FEvent := CreateEventW(nil, False, False, nil);
  if FEvent = 0 then
  begin
    DeleteCriticalSection(FCS);
    raise ELockError.Create(rsParkerInitFailed);
  end;
end;

destructor TParker.Destroy;
begin
  if FEvent <> 0 then
    CloseHandle(FEvent);
  DeleteCriticalSection(FCS);
  inherited Destroy;
end;

function TParker.GetLastError: TWaitError;
begin
  Result := FLastError;
end;

procedure TParker.Park;
var
  NeedWait: Boolean;
  WaitResult: DWORD;
begin
  EnterCriticalSection(FCS);
  try
    // 如果有许可，消费并返回
    if FPermit then
    begin
      FPermit := False;
      FLastError := weNone;
      Exit;
    end;
    NeedWait := True;
  finally
    LeaveCriticalSection(FCS);
  end;

  // 等待许可
  if NeedWait then
  begin
    WaitResult := WaitForSingleObject(FEvent, INFINITE);
    case WaitResult of
      WAIT_OBJECT_0:
        FLastError := weNone;
      WAIT_FAILED:
        FLastError := weSystemError;
      else
        FLastError := weSystemError;
    end;

    // 消费许可（事件已自动重置）
    EnterCriticalSection(FCS);
    try
      FPermit := False;
    finally
      LeaveCriticalSection(FCS);
    end;
  end;
end;

function TParker.ParkTimeout(ATimeoutMs: Cardinal): Boolean;
var
  NeedWait: Boolean;
  WaitResult: DWORD;
begin
  EnterCriticalSection(FCS);
  try
    // 如果有许可，消费并返回
    if FPermit then
    begin
      FPermit := False;
      FLastError := weNone;
      Exit(True);
    end;
    NeedWait := True;
  finally
    LeaveCriticalSection(FCS);
  end;

  // 等待许可或超时
  if NeedWait then
  begin
    WaitResult := WaitForSingleObject(FEvent, ATimeoutMs);
    case WaitResult of
      WAIT_OBJECT_0:
      begin
        // 消费许可（事件已自动重置）
        EnterCriticalSection(FCS);
        try
          FPermit := False;
        finally
          LeaveCriticalSection(FCS);
        end;
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
  end
  else
    Result := True;
end;

function TParker.ParkDuration(const ADuration: TDuration): TWaitResult;
var
  TimeoutMs: Int64;
begin
  // 将 TDuration 转换为毫秒
  TimeoutMs := ADuration.AsMs;
  if TimeoutMs < 0 then
    TimeoutMs := 0;

  if ParkTimeout(Cardinal(TimeoutMs)) then
    Result := wrSignaled
  else
    Result := wrTimeout;
end;

procedure TParker.Unpark;
begin
  EnterCriticalSection(FCS);
  try
    // 设置许可（多次 unpark 只存储一个许可）
    FPermit := True;
    // 唤醒等待的线程
    SetEvent(FEvent);
  finally
    LeaveCriticalSection(FCS);
  end;
end;

function MakeParker: IParker;
begin
  Result := TParker.Create;
end;

end.
