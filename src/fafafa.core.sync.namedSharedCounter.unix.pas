unit fafafa.core.sync.namedSharedCounter.unix;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, BaseUnix, Unix, UnixType,
  fafafa.core.sync.base, fafafa.core.sync.namedSharedCounter.base;

type
  // 共享内存结构
  PNamedSharedCounterData = ^TNamedSharedCounterData;
  TNamedSharedCounterData = record
    Value: Int64;
    Padding: array[0..6] of Int64;  // 缓存行填充，避免伪共享
  end;

  TNamedSharedCounter = class(TSynchronizable, INamedSharedCounter)
  private
    FShared: PNamedSharedCounterData;
    FShmHeader: Pointer;  // PNamedShmHeader - 共享内存头部
    FShmFd: cint;
    FShmPath: AnsiString;
    FOriginalName: string;
    FIsCreator: Boolean;
    FConfig: TNamedSharedCounterConfig;
    FLastError: TWaitError;

    function InitializeShm: Boolean;
  public
    constructor Create(const AName: string); overload;
    constructor Create(const AName: string; const AConfig: TNamedSharedCounterConfig); overload;
    destructor Destroy; override;

    // ISynchronizable
    function GetLastError: TWaitError;

    // INamedSharedCounter
    function Increment: Int64;
    function Decrement: Int64;
    function Add(AValue: Int64): Int64;
    function Sub(AValue: Int64): Int64;
    function CompareExchange(AExpected, ANew: Int64): Int64;
    function Exchange(ANew: Int64): Int64;
    function GetValue: Int64;
    procedure SetValue(AValue: Int64);
    function GetName: string;
  end;

function MakeNamedSharedCounter(const AName: string): INamedSharedCounter;
function MakeNamedSharedCounter(const AName: string;
  const AConfig: TNamedSharedCounterConfig): INamedSharedCounter;

implementation

uses
  fafafa.core.atomic, fafafa.core.sync.namedShm.unix;

const
  SHM_PREFIX = '/fafafa_cnt_';

function MakeNamedSharedCounter(const AName: string): INamedSharedCounter;
begin
  Result := TNamedSharedCounter.Create(AName);
end;

function MakeNamedSharedCounter(const AName: string;
  const AConfig: TNamedSharedCounterConfig): INamedSharedCounter;
begin
  Result := TNamedSharedCounter.Create(AName, AConfig);
end;

{ TNamedSharedCounter }

constructor TNamedSharedCounter.Create(const AName: string);
begin
  Create(AName, DefaultNamedSharedCounterConfig);
end;

constructor TNamedSharedCounter.Create(const AName: string;
  const AConfig: TNamedSharedCounterConfig);
begin
  inherited Create;
  FOriginalName := AName;
  FConfig := AConfig;
  FShared := nil;
  FShmHeader := nil;
  FShmFd := -1;
  FIsCreator := False;
  FLastError := weNone;

  // 验证名称
  if not ValidateShmName(SHM_PREFIX, AName) then
  begin
    FLastError := weInvalidParameter;
    raise ELockError.CreateFmt('Invalid name for named shared counter: %s', [AName]);
  end;

  FShmPath := CreateSafeShmPath(SHM_PREFIX, AName);

  if not InitializeShm then
  begin
    FLastError := weSystemError;
    raise ELockError.CreateFmt('Failed to create named shared counter: %s', [AName]);
  end;
end;

destructor TNamedSharedCounter.Destroy;
var
  IsLastRef: Boolean;
  Header: PNamedShmHeader;
begin
  IsLastRef := False;
  Header := PNamedShmHeader(FShmHeader);

  if Header <> nil then
    IsLastRef := ShmRelease(Header);

  UnmapAndCloseShm(Header, SizeOf(TNamedSharedCounterData),
    FShmFd, FShmPath, IsLastRef);

  FShmHeader := nil;
  FShared := nil;
  FShmFd := -1;

  inherited Destroy;
end;

function TNamedSharedCounter.InitializeShm: Boolean;
var
  Header: PNamedShmHeader;
begin
  Result := False;

  // 打开或创建共享内存
  FShmFd := OpenOrCreateShm(FShmPath, SizeOf(TNamedSharedCounterData),
    FIsCreator, DEFAULT_INIT_TIMEOUT_MS);

  if FShmFd < 0 then
    Exit;

  // 映射共享内存
  FShared := MapShm(FShmFd, SizeOf(TNamedSharedCounterData), Header);
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
    // 创建者初始化
    Header^.RefCount := 1;
    Header^.DataSize := SizeOf(TNamedSharedCounterData);
    FShared^.Value := FConfig.InitialValue;
    // 标记初始化完成
    ShmMarkInitialized(Header);
  end
  else
  begin
    // 等待创建者完成初始化
    if not ShmWaitInitialized(Header, DEFAULT_INIT_TIMEOUT_MS) then
    begin
      Fpmunmap(Header, SizeOf(TNamedShmHeader) + SizeOf(TNamedSharedCounterData));
      FpClose(FShmFd);
      FShmHeader := nil;
      FShared := nil;
      FShmFd := -1;
      Exit;
    end;
    // ★ 检查 ShmAddRef 是否成功
    if not ShmAddRef(Header) then
    begin
      Fpmunmap(Header, SizeOf(TNamedShmHeader) + SizeOf(TNamedSharedCounterData));
      FpClose(FShmFd);
      FShmHeader := nil;
      FShared := nil;
      FShmFd := -1;
      Exit;
    end;
  end;

  Result := True;
end;

function TNamedSharedCounter.GetLastError: TWaitError;
begin
  Result := FLastError;
end;

function TNamedSharedCounter.Increment: Int64;
begin
  Result := Add(1);
end;

function TNamedSharedCounter.Decrement: Int64;
begin
  Result := Sub(1);
end;

function TNamedSharedCounter.Add(AValue: Int64): Int64;
begin
  if FShared = nil then
  begin
    FLastError := weInvalidState;
    Exit(0);
  end;
  FLastError := weNone;
  Result := atomic_fetch_add_64(FShared^.Value, AValue) + AValue;
end;

function TNamedSharedCounter.Sub(AValue: Int64): Int64;
begin
  if FShared = nil then
  begin
    FLastError := weInvalidState;
    Exit(0);
  end;
  FLastError := weNone;
  Result := atomic_fetch_sub_64(FShared^.Value, AValue) - AValue;
end;

function TNamedSharedCounter.CompareExchange(AExpected, ANew: Int64): Int64;
var
  Exp: Int64;
begin
  if FShared = nil then
  begin
    FLastError := weInvalidState;
    Exit(0);
  end;
  FLastError := weNone;
  Exp := AExpected;
  atomic_compare_exchange_strong_64(FShared^.Value, Exp, ANew);
  Result := Exp;
end;

function TNamedSharedCounter.Exchange(ANew: Int64): Int64;
begin
  if FShared = nil then
  begin
    FLastError := weInvalidState;
    Exit(0);
  end;
  FLastError := weNone;
  Result := atomic_exchange_64(FShared^.Value, ANew);
end;

function TNamedSharedCounter.GetValue: Int64;
begin
  if FShared = nil then
  begin
    FLastError := weInvalidState;
    Result := 0;
  end
  else
  begin
    FLastError := weNone;
    Result := atomic_load_64(FShared^.Value);
  end;
end;

procedure TNamedSharedCounter.SetValue(AValue: Int64);
begin
  if FShared = nil then
    FLastError := weInvalidState
  else
  begin
    FLastError := weNone;
    atomic_store_64(FShared^.Value, AValue);
  end;
end;

function TNamedSharedCounter.GetName: string;
begin
  Result := FOriginalName;
end;

end.
