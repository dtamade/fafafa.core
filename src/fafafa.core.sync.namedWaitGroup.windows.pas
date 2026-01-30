unit fafafa.core.sync.namedWaitGroup.windows;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, Windows,
  fafafa.core.sync.base, fafafa.core.sync.namedWaitGroup.base;

type
  TNamedWaitGroup = class(TSynchronizable, INamedWaitGroup)
  private
    FMutex: THandle;
    FEvent: THandle;
    FMapping: THandle;
    FShared: PInt32;  // [0]=Count, [1]=Waiters, [2]=Generation
    FOriginalName: string;
    FIsCreator: Boolean;
    FConfig: TNamedWaitGroupConfig;
    FLastError: TWaitError;

    function CreateNames(const AName: string; out AMutexName, AEventName, AMapName: string): Boolean;
  public
    constructor Create(const AName: string); overload;
    constructor Create(const AName: string; const AConfig: TNamedWaitGroupConfig); overload;
    destructor Destroy; override;

    // ISynchronizable
    function GetLastError: TWaitError;

    // INamedWaitGroup
    procedure Add(ACount: Cardinal = 1);
    procedure Done;
    function Wait(ATimeoutMs: Cardinal = INFINITE): Boolean;
    function GetCount: Cardinal;
    function IsZero: Boolean;
    function GetName: string;
  end;

function MakeNamedWaitGroup(const AName: string): INamedWaitGroup;
function MakeNamedWaitGroup(const AName: string;
  const AConfig: TNamedWaitGroupConfig): INamedWaitGroup;

implementation

const
  PREFIX_MUTEX = 'Global\fafafa_wg_m_';
  PREFIX_EVENT = 'Global\fafafa_wg_e_';
  PREFIX_MAP = 'Global\fafafa_wg_s_';

  // 共享内存偏移量
  OFF_COUNT = 0;
  OFF_WAITERS = 1;
  OFF_GEN = 2;

function MakeNamedWaitGroup(const AName: string): INamedWaitGroup;
begin
  Result := TNamedWaitGroup.Create(AName);
end;

function MakeNamedWaitGroup(const AName: string;
  const AConfig: TNamedWaitGroupConfig): INamedWaitGroup;
begin
  Result := TNamedWaitGroup.Create(AName, AConfig);
end;

{ TNamedWaitGroup }

constructor TNamedWaitGroup.Create(const AName: string);
begin
  Create(AName, DefaultNamedWaitGroupConfig);
end;

constructor TNamedWaitGroup.Create(const AName: string;
  const AConfig: TNamedWaitGroupConfig);
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
    raise ELockError.CreateFmt('Invalid name for named wait group: %s', [AName]);

  // 创建或打开互斥锁
  FMutex := CreateMutexW(nil, False, PWideChar(UnicodeString(MutexName)));
  if FMutex = 0 then
    raise ELockError.CreateFmt('Failed to create mutex for named wait group: %s', [AName]);

  FIsCreator := GetLastError <> ERROR_ALREADY_EXISTS;

  // 创建或打开事件（自动重置，初始无信号）
  FEvent := CreateEventW(nil, True, False, PWideChar(UnicodeString(EventName)));
  if FEvent = 0 then
  begin
    CloseHandle(FMutex);
    raise ELockError.CreateFmt('Failed to create event for named wait group: %s', [AName]);
  end;

  // 创建或打开共享内存
  FMapping := CreateFileMappingW(INVALID_HANDLE_VALUE, nil, PAGE_READWRITE,
    0, SizeOf(Int32) * 4, PWideChar(UnicodeString(MapName)));
  if FMapping = 0 then
  begin
    CloseHandle(FEvent);
    CloseHandle(FMutex);
    raise ELockError.CreateFmt('Failed to create mapping for named wait group: %s', [AName]);
  end;

  FShared := MapViewOfFile(FMapping, FILE_MAP_ALL_ACCESS, 0, 0, 0);
  if FShared = nil then
  begin
    CloseHandle(FMapping);
    CloseHandle(FEvent);
    CloseHandle(FMutex);
    raise ELockError.CreateFmt('Failed to map view for named wait group: %s', [AName]);
  end;

  // 初始化（如果是创建者）
  if FIsCreator then
  begin
    PInt32(PtrUInt(FShared) + OFF_COUNT * SizeOf(Int32))^ := 0;
    PInt32(PtrUInt(FShared) + OFF_WAITERS * SizeOf(Int32))^ := 0;
    PInt32(PtrUInt(FShared) + OFF_GEN * SizeOf(Int32))^ := 0;
  end;
end;

destructor TNamedWaitGroup.Destroy;
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

function TNamedWaitGroup.CreateNames(const AName: string; out AMutexName, AEventName, AMapName: string): Boolean;
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
    AMutexName := 'Local\fafafa_wg_m_' + SafeName;
    AEventName := 'Local\fafafa_wg_e_' + SafeName;
    AMapName := 'Local\fafafa_wg_s_' + SafeName;
  end;
  Result := True;
end;

function TNamedWaitGroup.GetLastError: TWaitError;
begin
  Result := FLastError;
end;

procedure TNamedWaitGroup.Add(ACount: Cardinal = 1);
var
  PCount: PInt32;
  OldVal, NewVal: Int32;
begin
  if FShared = nil then
  begin
    FLastError := weInvalidState;
    raise ELockError.Create('WaitGroup not properly initialized');
  end;

  if ACount = 0 then
  begin
    FLastError := weNone;
    Exit;
  end;

  PCount := PInt32(PtrUInt(FShared) + OFF_COUNT * SizeOf(Int32));

  repeat
    OldVal := InterlockedCompareExchange(PCount^, 0, 0);
    NewVal := OldVal + Int32(ACount);
    if NewVal < 0 then
    begin
      FLastError := weInvalidState;
      raise ELockError.Create('WaitGroup counter overflow');
    end;
  until InterlockedCompareExchange(PCount^, NewVal, OldVal) = OldVal;

  FLastError := weNone;
end;

procedure TNamedWaitGroup.Done;
var
  PCount, PGen: PInt32;
  OldVal, NewVal: Int32;
begin
  if FShared = nil then
  begin
    FLastError := weInvalidState;
    raise ELockError.Create('WaitGroup not properly initialized');
  end;

  PCount := PInt32(PtrUInt(FShared) + OFF_COUNT * SizeOf(Int32));
  PGen := PInt32(PtrUInt(FShared) + OFF_GEN * SizeOf(Int32));

  repeat
    OldVal := InterlockedCompareExchange(PCount^, 0, 0);
    if OldVal <= 0 then
    begin
      FLastError := weInvalidState;
      raise ELockError.Create('WaitGroup counter is already zero');
    end;
    NewVal := OldVal - 1;
  until InterlockedCompareExchange(PCount^, NewVal, OldVal) = OldVal;

  // 如果归零，增加代数并唤醒等待者
  if NewVal = 0 then
  begin
    InterlockedIncrement(PGen^);
    SetEvent(FEvent);
  end;

  FLastError := weNone;
end;

function TNamedWaitGroup.Wait(ATimeoutMs: Cardinal): Boolean;
var
  StartTime, Elapsed: QWord;
  CurrentCount: Int32;
  WaitMs: DWORD;
  PWaiters, PCount: PInt32;
begin
  if FShared = nil then
  begin
    FLastError := weInvalidState;
    Exit(False);
  end;

  PCount := PInt32(PtrUInt(FShared) + OFF_COUNT * SizeOf(Int32));
  PWaiters := PInt32(PtrUInt(FShared) + OFF_WAITERS * SizeOf(Int32));

  // 快速路径
  CurrentCount := InterlockedCompareExchange(PCount^, 0, 0);
  if CurrentCount = 0 then
  begin
    FLastError := weNone;
    Exit(True);
  end;

  StartTime := GetTickCount64;

  // 增加等待者计数
  InterlockedIncrement(PWaiters^);
  try
    while True do
    begin
      CurrentCount := InterlockedCompareExchange(PCount^, 0, 0);
      if CurrentCount = 0 then
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

      // 检查后重置事件（如果计数不为零）
      if InterlockedCompareExchange(PCount^, 0, 0) <> 0 then
        ResetEvent(FEvent);
    end;
  finally
    InterlockedDecrement(PWaiters^);
  end;
end;

function TNamedWaitGroup.GetCount: Cardinal;
var
  PCount: PInt32;
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
    PCount := PInt32(PtrUInt(FShared) + OFF_COUNT * SizeOf(Int32));
    C := InterlockedCompareExchange(PCount^, 0, 0);
    if C < 0 then
      Result := 0
    else
      Result := Cardinal(C);
  end;
end;

function TNamedWaitGroup.IsZero: Boolean;
var
  PCount: PInt32;
begin
  if FShared = nil then
  begin
    FLastError := weInvalidState;
    Result := False;
  end
  else
  begin
    FLastError := weNone;
    PCount := PInt32(PtrUInt(FShared) + OFF_COUNT * SizeOf(Int32));
    Result := InterlockedCompareExchange(PCount^, 0, 0) = 0;
  end;
end;

function TNamedWaitGroup.GetName: string;
begin
  Result := FOriginalName;
end;

end.
