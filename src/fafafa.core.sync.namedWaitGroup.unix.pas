unit fafafa.core.sync.namedWaitGroup.unix;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, BaseUnix, Unix, UnixType,
  fafafa.core.sync.base, fafafa.core.sync.namedWaitGroup.base;

type
  // 共享内存结构
  PNamedWaitGroupShared = ^TNamedWaitGroupShared;
  TNamedWaitGroupShared = record
    Count: Int32;           // 当前计数
    Waiters: Int32;         // 等待者数量
    Generation: Int32;      // 代数（用于区分不同的等待周期）
    Padding: Int32;         // 对齐填充
  end;

  TNamedWaitGroup = class(TSynchronizable, INamedWaitGroup)
  private
    FShared: PNamedWaitGroupShared;
    FShmHeader: Pointer;  // PNamedShmHeader
    FShmFd: cint;
    FShmPath: AnsiString;
    FOriginalName: string;
    FIsCreator: Boolean;
    FConfig: TNamedWaitGroupConfig;
    FLastError: TWaitError;

    function InitializeShm: Boolean;
  public
    constructor Create(const AName: string); overload;
    constructor Create(const AName: string; const AConfig: TNamedWaitGroupConfig); overload;
    destructor Destroy; override;

    // ISynchronizable
    function GetLastError: TWaitError;

    // INamedWaitGroup
    procedure Add(ACount: Cardinal = 1);
    procedure Done;
    function Wait(ATimeoutMs: Cardinal = High(Cardinal)): Boolean;
    function GetCount: Cardinal;
    function IsZero: Boolean;
    function GetName: string;
  end;

function MakeNamedWaitGroup(const AName: string): INamedWaitGroup;
function MakeNamedWaitGroup(const AName: string;
  const AConfig: TNamedWaitGroupConfig): INamedWaitGroup;

implementation

uses
  fafafa.core.atomic, fafafa.core.sync.namedShm.unix;

const
  SHM_PREFIX = '/fafafa_wg_';

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
begin
  inherited Create;
  FOriginalName := AName;
  FConfig := AConfig;
  FShared := nil;
  FShmHeader := nil;
  FShmFd := -1;
  FIsCreator := False;
  FLastError := weNone;

  if not ValidateShmName(SHM_PREFIX, AName) then
  begin
    FLastError := weInvalidParameter;
    raise ELockError.CreateFmt('Invalid name for named wait group: %s', [AName]);
  end;

  FShmPath := CreateSafeShmPath(SHM_PREFIX, AName);

  if not InitializeShm then
  begin
    FLastError := weSystemError;
    raise ELockError.CreateFmt('Failed to create named wait group: %s', [AName]);
  end;
end;

destructor TNamedWaitGroup.Destroy;
var
  IsLastRef: Boolean;
  Header: PNamedShmHeader;
begin
  IsLastRef := False;
  Header := PNamedShmHeader(FShmHeader);

  if Header <> nil then
    IsLastRef := ShmRelease(Header);

  UnmapAndCloseShm(Header, SizeOf(TNamedWaitGroupShared),
    FShmFd, FShmPath, IsLastRef);

  FShmHeader := nil;
  FShared := nil;
  FShmFd := -1;

  inherited Destroy;
end;

function TNamedWaitGroup.InitializeShm: Boolean;
var
  Header: PNamedShmHeader;
begin
  Result := False;

  FShmFd := OpenOrCreateShm(FShmPath, SizeOf(TNamedWaitGroupShared),
    FIsCreator, DEFAULT_INIT_TIMEOUT_MS);

  if FShmFd < 0 then
    Exit;

  FShared := MapShm(FShmFd, SizeOf(TNamedWaitGroupShared), Header);
  if FShared = nil then
  begin
    FpClose(FShmFd);
    FShmFd := -1;
    if FIsCreator then
      shm_unlink(PAnsiChar(FShmPath));
    Exit;
  end;

  FShmHeader := Header;

  if FIsCreator then
  begin
    // ★ 立即初始化头部，设置 CreatorPid
    ShmInitCreatorHeader(Header);
    Header^.RefCount := 1;
    Header^.DataSize := SizeOf(TNamedWaitGroupShared);
    FShared^.Count := 0;
    FShared^.Waiters := 0;
    FShared^.Generation := 0;
    ShmMarkInitialized(Header);
  end
  else
  begin
    if not ShmWaitInitialized(Header, DEFAULT_INIT_TIMEOUT_MS) then
    begin
      Fpmunmap(Header, SizeOf(TNamedShmHeader) + SizeOf(TNamedWaitGroupShared));
      FpClose(FShmFd);
      FShmHeader := nil;
      FShared := nil;
      FShmFd := -1;
      Exit;
    end;
    // ★ 检查 ShmAddRef 是否成功
    if not ShmAddRef(Header) then
    begin
      Fpmunmap(Header, SizeOf(TNamedShmHeader) + SizeOf(TNamedWaitGroupShared));
      FpClose(FShmFd);
      FShmHeader := nil;
      FShared := nil;
      FShmFd := -1;
      Exit;
    end;
  end;

  Result := True;
end;

function TNamedWaitGroup.GetLastError: TWaitError;
begin
  Result := FLastError;
end;

procedure TNamedWaitGroup.Add(ACount: Cardinal = 1);
var
  OldCount, NewCount: Int32;
begin
  if FShared = nil then
  begin
    FLastError := weInvalidState;
    Exit;
  end;
  if ACount = 0 then Exit;

  repeat
    OldCount := atomic_load(FShared^.Count);
    NewCount := OldCount + Int32(ACount);
    if NewCount < 0 then
    begin
      FLastError := weResourceExhausted;
      raise ELockError.Create('WaitGroup counter overflow');
    end;
  until atomic_compare_exchange_strong(FShared^.Count, OldCount, NewCount);

  FLastError := weNone;
end;

procedure TNamedWaitGroup.Done;
var
  OldCount, NewCount: Int32;
begin
  if FShared = nil then
  begin
    FLastError := weInvalidState;
    Exit;
  end;

  repeat
    OldCount := atomic_load(FShared^.Count);
    if OldCount <= 0 then
    begin
      FLastError := weInvalidState;
      raise ELockError.Create('WaitGroup counter is already zero');
    end;
    NewCount := OldCount - 1;
  until atomic_compare_exchange_strong(FShared^.Count, OldCount, NewCount);

  // 如果归零，增加代数并唤醒等待者
  if NewCount = 0 then
  begin
    atomic_fetch_add(FShared^.Generation, 1);
    FutexWakeAll(@FShared^.Generation);
  end;

  FLastError := weNone;
end;

function TNamedWaitGroup.Wait(ATimeoutMs: Cardinal): Boolean;
var
  StartTime, Elapsed: QWord;
  CurrentCount, CurrentGen: Int32;
  RemainingMs: Cardinal;
begin
  if FShared = nil then
  begin
    FLastError := weInvalidState;
    Exit(False);
  end;

  // 快速路径
  if atomic_load(FShared^.Count) = 0 then
  begin
    FLastError := weNone;
    Exit(True);
  end;

  StartTime := GetTickCount64;

  // 增加等待者计数
  atomic_fetch_add(FShared^.Waiters, 1);
  try
    while True do
    begin
      CurrentCount := atomic_load(FShared^.Count);
      if CurrentCount = 0 then
      begin
        FLastError := weNone;
        Exit(True);
      end;

      Elapsed := GetTickCount64 - StartTime;
      if (ATimeoutMs <> High(Cardinal)) and (Elapsed >= ATimeoutMs) then
      begin
        FLastError := weTimeout;
        Exit(False);
      end;

      CurrentGen := atomic_load(FShared^.Generation);

      // 计算剩余超时时间
      if ATimeoutMs = High(Cardinal) then
        RemainingMs := 100
      else
      begin
        RemainingMs := ATimeoutMs - Cardinal(Elapsed);
        if RemainingMs > 100 then
          RemainingMs := 100;
      end;

      FutexWait(@FShared^.Generation, CurrentGen, RemainingMs);
    end;
  finally
    atomic_fetch_sub(FShared^.Waiters, 1);
  end;
end;

function TNamedWaitGroup.GetCount: Cardinal;
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
    C := atomic_load(FShared^.Count);
    if C < 0 then
      Result := 0
    else
      Result := Cardinal(C);
  end;
end;

function TNamedWaitGroup.IsZero: Boolean;
begin
  if FShared = nil then
  begin
    FLastError := weInvalidState;
    Result := False;
  end
  else
  begin
    FLastError := weNone;
    Result := atomic_load(FShared^.Count) = 0;
  end;
end;

function TNamedWaitGroup.GetName: string;
begin
  Result := FOriginalName;
end;

end.
