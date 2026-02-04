unit fafafa.core.sync.namedLatch.unix;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, BaseUnix, Unix, UnixType,
  fafafa.core.sync.base, fafafa.core.sync.namedLatch.base;

type
  // 共享内存结构
  PNamedLatchShared = ^TNamedLatchShared;
  TNamedLatchShared = record
    Count: Int32;           // 当前计数
    InitialCount: Int32;    // 初始计数
    Padding: array[0..1] of Int32;  // 对齐填充
  end;

  TNamedLatch = class(TSynchronizable, INamedLatch)
  private
    FShared: PNamedLatchShared;
    FShmHeader: Pointer;  // PNamedShmHeader
    FShmFd: cint;
    FShmPath: AnsiString;
    FOriginalName: string;
    FIsCreator: Boolean;
    FConfig: TNamedLatchConfig;
    FLastError: TWaitError;
    FInitialCount: Cardinal;

    function InitializeShm: Boolean;
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
    function Wait(ATimeoutMs: Cardinal = High(Cardinal)): Boolean;
    function TryWait: Boolean;
    function GetCount: Cardinal;
    function IsOpen: Boolean;
    function GetName: string;
  end;

function MakeNamedLatch(const AName: string; AInitialCount: Cardinal): INamedLatch;
function MakeNamedLatch(const AName: string; AInitialCount: Cardinal;
  const AConfig: TNamedLatchConfig): INamedLatch;

implementation

uses
  fafafa.core.atomic, fafafa.core.sync.namedShm.unix;

const
  SHM_PREFIX = '/fafafa_latch_';

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
begin
  inherited Create;
  FOriginalName := AName;
  FConfig := AConfig;
  FInitialCount := AInitialCount;
  FShared := nil;
  FShmHeader := nil;
  FShmFd := -1;
  FIsCreator := False;
  FLastError := weNone;

  if not ValidateShmName(SHM_PREFIX, AName) then
  begin
    FLastError := weInvalidParameter;
    raise ELockError.CreateFmt('Invalid name for named latch: %s', [AName]);
  end;

  FShmPath := CreateSafeShmPath(SHM_PREFIX, AName);

  if not InitializeShm then
  begin
    FLastError := weSystemError;
    raise ELockError.CreateFmt('Failed to create named latch: %s', [AName]);
  end;
end;

destructor TNamedLatch.Destroy;
var
  IsLastRef: Boolean;
  Header: PNamedShmHeader;
begin
  IsLastRef := False;
  Header := PNamedShmHeader(FShmHeader);

  if Header <> nil then
    IsLastRef := ShmRelease(Header);

  UnmapAndCloseShm(Header, SizeOf(TNamedLatchShared),
    FShmFd, FShmPath, IsLastRef);

  FShmHeader := nil;
  FShared := nil;
  FShmFd := -1;

  inherited Destroy;
end;

function TNamedLatch.InitializeShm: Boolean;
var
  Header: PNamedShmHeader;
begin
  Result := False;

  FShmFd := OpenOrCreateShm(FShmPath, SizeOf(TNamedLatchShared),
    FIsCreator, DEFAULT_INIT_TIMEOUT_MS);

  if FShmFd < 0 then
    Exit;

  FShared := MapShm(FShmFd, SizeOf(TNamedLatchShared), Header);
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
    Header^.DataSize := SizeOf(TNamedLatchShared);
    FShared^.Count := Int32(FInitialCount);
    FShared^.InitialCount := Int32(FInitialCount);
    ShmMarkInitialized(Header);
  end
  else
  begin
    if not ShmWaitInitialized(Header, DEFAULT_INIT_TIMEOUT_MS) then
    begin
      Fpmunmap(Header, SizeOf(TNamedShmHeader) + SizeOf(TNamedLatchShared));
      FpClose(FShmFd);
      FShmHeader := nil;
      FShared := nil;
      FShmFd := -1;
      Exit;
    end;
    // ★ 检查 ShmAddRef 是否成功
    if not ShmAddRef(Header) then
    begin
      Fpmunmap(Header, SizeOf(TNamedShmHeader) + SizeOf(TNamedLatchShared));
      FpClose(FShmFd);
      FShmHeader := nil;
      FShared := nil;
      FShmFd := -1;
      Exit;
    end;
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
      FLastError := weNone;  // 已经归零，静默退出
      Exit;
    end;

    if Int32(ACount) >= OldCount then
      NewCount := 0
    else
      NewCount := OldCount - Int32(ACount);
  until atomic_compare_exchange_strong(FShared^.Count, OldCount, NewCount);

  // 如果归零，唤醒所有等待者
  if NewCount = 0 then
    FutexWakeAll(@FShared^.Count);

  FLastError := weNone;
end;

function TNamedLatch.Wait(ATimeoutMs: Cardinal): Boolean;
var
  StartTime, Elapsed: QWord;
  CurrentCount: Int32;
  RemainingMs: Cardinal;
begin
  Result := False;  // 默认值，实际上所有路径都通过 Exit() 返回
  if FShared = nil then
  begin
    FLastError := weInvalidState;
    Exit(False);
  end;

  // 快速路径：已经归零
  if atomic_load(FShared^.Count) <= 0 then
  begin
    FLastError := weNone;
    Exit(True);
  end;

  StartTime := GetTickCount64;

  while True do
  begin
    CurrentCount := atomic_load(FShared^.Count);
    if CurrentCount <= 0 then
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

    // 计算剩余超时时间
    if ATimeoutMs = High(Cardinal) then
      RemainingMs := 100
    else
    begin
      RemainingMs := ATimeoutMs - Cardinal(Elapsed);
      if RemainingMs > 100 then
        RemainingMs := 100;
    end;

    FutexWait(@FShared^.Count, CurrentCount, RemainingMs);
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
    Result := atomic_load(FShared^.Count) <= 0;
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
    C := atomic_load(FShared^.Count);
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
    Result := atomic_load(FShared^.Count) <= 0;
  end;
end;

function TNamedLatch.GetName: string;
begin
  Result := FOriginalName;
end;

end.
