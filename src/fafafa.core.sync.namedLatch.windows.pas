unit fafafa.core.sync.namedLatch.windows;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, Windows,
  fafafa.core.sync.base, fafafa.core.sync.namedLatch.base;

type
  TNamedLatch = class(TSynchronizable, INamedLatch)
  private
    FMutex: THandle;
    FEvent: THandle;
    FMapping: THandle;
    FShared: PInt32;  // [0]=Count, [1]=InitialCount
    FOriginalName: string;
    FIsCreator: Boolean;
    FConfig: TNamedLatchConfig;
    FLastError: TWaitError;

    function CreateNames(const AName: string; out AMutexName, AEventName, AMapName: string): Boolean;
  public
    constructor Create(const AName: string; AInitialCount: Cardinal); overload;
    constructor Create(const AName: string; AInitialCount: Cardinal;
      const AConfig: TNamedLatchConfig); overload;
    destructor Destroy; override;

    // ISynchronizable
    function GetLastError: TWaitError;

    // INamedLatch
    procedure CountDown;
    procedure CountDownBy(ACount: Cardinal);
    function Wait(ATimeoutMs: Cardinal = INFINITE): Boolean;
    function TryWait: Boolean;
    function GetCount: Cardinal;
    function IsOpen: Boolean;
    function GetName: string;
  end;

function MakeNamedLatch(const AName: string; AInitialCount: Cardinal): INamedLatch;
function MakeNamedLatch(const AName: string; AInitialCount: Cardinal;
  const AConfig: TNamedLatchConfig): INamedLatch;

implementation

const
  PREFIX_MUTEX = 'Global\fafafa_latch_m_';
  PREFIX_EVENT = 'Global\fafafa_latch_e_';
  PREFIX_MAP = 'Global\fafafa_latch_s_';

function MakeNamedLatch(const AName: string; AInitialCount: Cardinal): INamedLatch;
begin
  Result := TNamedLatch.Create(AName, AInitialCount);
end;

function MakeNamedLatch(const AName: string; AInitialCount: Cardinal;
  const AConfig: TNamedLatchConfig): INamedLatch;
begin
  Result := TNamedLatch.Create(AName, AInitialCount, AConfig);
end;

{ TNamedLatch }

constructor TNamedLatch.Create(const AName: string; AInitialCount: Cardinal);
begin
  Create(AName, AInitialCount, DefaultNamedLatchConfig);
end;

constructor TNamedLatch.Create(const AName: string; AInitialCount: Cardinal;
  const AConfig: TNamedLatchConfig);
var
  MutexName, EventName, MapName: string;
begin
  inherited Create;
  FOriginalName := AName;
  FConfig := AConfig;
  FMutex := 0;
  FEvent := 0;
  FMapping := 0;
  FShared := nil;
  FIsCreator := False;
  FLastError := weNone;

  if not CreateNames(AName, MutexName, EventName, MapName) then
    raise ELockError.CreateFmt('Invalid name for named latch: %s', [AName]);

  // 创建或打开互斥锁
  FMutex := CreateMutexW(nil, False, PWideChar(UnicodeString(MutexName)));
  if FMutex = 0 then
    raise ELockError.CreateFmt('Failed to create mutex for named latch: %s', [AName]);

  FIsCreator := GetLastError <> ERROR_ALREADY_EXISTS;

  // 创建或打开事件（手动重置，初始无信号）
  FEvent := CreateEventW(nil, True, False, PWideChar(UnicodeString(EventName)));
  if FEvent = 0 then
  begin
    CloseHandle(FMutex);
    raise ELockError.CreateFmt('Failed to create event for named latch: %s', [AName]);
  end;

  // 创建或打开共享内存
  FMapping := CreateFileMappingW(INVALID_HANDLE_VALUE, nil, PAGE_READWRITE,
    0, SizeOf(Int32) * 4, PWideChar(UnicodeString(MapName)));
  if FMapping = 0 then
  begin
    CloseHandle(FEvent);
    CloseHandle(FMutex);
    raise ELockError.CreateFmt('Failed to create mapping for named latch: %s', [AName]);
  end;

  FShared := MapViewOfFile(FMapping, FILE_MAP_ALL_ACCESS, 0, 0, 0);
  if FShared = nil then
  begin
    CloseHandle(FMapping);
    CloseHandle(FEvent);
    CloseHandle(FMutex);
    raise ELockError.CreateFmt('Failed to map view for named latch: %s', [AName]);
  end;

  // 初始化计数（如果是创建者）
  if FIsCreator then
  begin
    FShared^ := Int32(AInitialCount);
    PInt32(PtrUInt(FShared) + SizeOf(Int32))^ := Int32(AInitialCount);
    if AInitialCount = 0 then
      SetEvent(FEvent);
  end;
end;

destructor TNamedLatch.Destroy;
begin
  if FShared <> nil then
    UnmapViewOfFile(FShared);
  if FMapping <> 0 then
    CloseHandle(FMapping);
  if FEvent <> 0 then
    CloseHandle(FEvent);
  if FMutex <> 0 then
    CloseHandle(FMutex);
  inherited Destroy;
end;

function TNamedLatch.CreateNames(const AName: string; out AMutexName, AEventName, AMapName: string): Boolean;
var
  SafeName: string;
  I: Integer;
begin
  SafeName := AName;
  for I := 1 to Length(SafeName) do
    if not (SafeName[I] in ['a'..'z', 'A'..'Z', '0'..'9', '_']) then
      SafeName[I] := '_';

  if FConfig.UseGlobalNamespace then
  begin
    AMutexName := PREFIX_MUTEX + SafeName;
    AEventName := PREFIX_EVENT + SafeName;
    AMapName := PREFIX_MAP + SafeName;
  end
  else
  begin
    AMutexName := 'Local\fafafa_latch_m_' + SafeName;
    AEventName := 'Local\fafafa_latch_e_' + SafeName;
    AMapName := 'Local\fafafa_latch_s_' + SafeName;
  end;
  Result := True;
end;

function TNamedLatch.GetLastError: TWaitError;
begin
  Result := FLastError;
end;

procedure TNamedLatch.CountDown;
begin
  CountDownBy(1);
end;

procedure TNamedLatch.CountDownBy(ACount: Cardinal);
var
  OldCount, NewCount: Int32;
  WaitResult: DWORD;
begin
  if FShared = nil then
  begin
    FLastError := weInvalidState;
    Exit;
  end;

  WaitResult := WaitForSingleObject(FMutex, FConfig.TimeoutMs);
  if WaitResult <> WAIT_OBJECT_0 then
  begin
    FLastError := weTimeout;
    Exit;
  end;

  try
    OldCount := InterlockedCompareExchange(FShared^, 0, 0);
    if OldCount <= 0 then
    begin
      FLastError := weNone;
      Exit;
    end;

    if Int32(ACount) >= OldCount then
      NewCount := 0
    else
      NewCount := OldCount - Int32(ACount);

    InterlockedExchange(FShared^, NewCount);

    // 如果归零，发信号唤醒所有等待者
    if NewCount = 0 then
      SetEvent(FEvent);

    FLastError := weNone;
  finally
    ReleaseMutex(FMutex);
  end;
end;

function TNamedLatch.Wait(ATimeoutMs: Cardinal): Boolean;
var
  StartTime, Elapsed: QWord;
  CurrentCount: Int32;
  WaitMs: DWORD;
begin
  if FShared = nil then
  begin
    FLastError := weInvalidState;
    Exit(False);
  end;

  // 快速路径
  CurrentCount := InterlockedCompareExchange(FShared^, 0, 0);
  if CurrentCount <= 0 then
  begin
    FLastError := weNone;
    Exit(True);
  end;

  StartTime := GetTickCount64;

  while True do
  begin
    CurrentCount := InterlockedCompareExchange(FShared^, 0, 0);
    if CurrentCount <= 0 then
    begin
      FLastError := weNone;
      Exit(True);
    end;

    Elapsed := GetTickCount64 - StartTime;
    if (ATimeoutMs <> INFINITE) and (Elapsed >= ATimeoutMs) then
    begin
      FLastError := weTimeout;
      Exit(False);
    end;

    // 计算剩余等待时间
    if ATimeoutMs = INFINITE then
      WaitMs := 100
    else
    begin
      WaitMs := ATimeoutMs - DWORD(Elapsed);
      if WaitMs > 100 then
        WaitMs := 100;
    end;

    WaitForSingleObject(FEvent, WaitMs);
  end;
end;

function TNamedLatch.TryWait: Boolean;
begin
  if FShared = nil then
  begin
    FLastError := weInvalidState;
    Result := False;
  end
  else
  begin
    FLastError := weNone;
    Result := InterlockedCompareExchange(FShared^, 0, 0) <= 0;
  end;
end;

function TNamedLatch.GetCount: Cardinal;
var
  C: Int32;
begin
  if FShared = nil then
  begin
    FLastError := weInvalidState;
    Result := 0;
  end
  else
  begin
    FLastError := weNone;
    C := InterlockedCompareExchange(FShared^, 0, 0);
    if C < 0 then
      Result := 0
    else
      Result := Cardinal(C);
  end;
end;

function TNamedLatch.IsOpen: Boolean;
begin
  if FShared = nil then
  begin
    FLastError := weInvalidState;
    Result := False;
  end
  else
  begin
    FLastError := weNone;
    Result := InterlockedCompareExchange(FShared^, 0, 0) <= 0;
  end;
end;

function TNamedLatch.GetName: string;
begin
  Result := FOriginalName;
end;

end.
