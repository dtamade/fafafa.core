unit fafafa.core.sync.namedRWLock.windows;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses`n  Windows, SysUtils,`n  fafafa.core.base, fafafa.core.sync.base, fafafa.core.atomic, fafafa.core.sync.namedRWLock.base;

type
  // ===== RAII 璇婚攣瀹堝崼 =====
  TNamedRWLockReadGuard = class(TInterfacedObject, INamedRWLockReadGuard)
  private
    FRWLock: Pointer;  // 鎸囧悜 TNamedRWLock
    FName: string;
    FReleased: Boolean;
  public
    constructor Create(ARWLock: Pointer; const AName: string);
    destructor Destroy; override;
    function GetName: string;
  end;

  // ===== RAII 鍐欓攣瀹堝崼 =====
  TNamedRWLockWriteGuard = class(TInterfacedObject, INamedRWLockWriteGuard)
  private
    FRWLock: Pointer;  // 鎸囧悜 TNamedRWLock
    FName: string;
    FReleased: Boolean;
  public
    constructor Create(ARWLock: Pointer; const AName: string);
    destructor Destroy; override;
    function GetName: string;
  end;

  // ===== Windows 鍛藉悕璇诲啓閿侊紙璺ㄨ繘绋嬶級=====
  // 瀹炵幇鍩轰簬锛?  // - 鍏变韩鍐呭瓨涓殑鐘舵€侊紙娲诲姩璇昏€?绛夊緟鍐欒€?鍐欒€呮爣蹇楋級
  // - 鍛藉悕浜掓枼閲忥紙淇濇姢鍏变韩鐘舵€侊級
  // - 鍛藉悕浜嬩欢锛?  //   * ReaderEvent锛堟墜鍔ㄩ噸缃級锛氬厑璁?闃诲鏂扮殑璇昏€?  //   * WriterEvent锛堣嚜鍔ㄩ噸缃級锛氬敜閱掍竴涓瓑寰呯殑鍐欒€?  // 娉ㄦ剰锛氫笉浣跨敤 SRWLOCK/CONDITION_VARIABLE锛堝畠浠粎杩涚▼鍐呮湁鏁堬級
  TNamedRWLock = class(TSynchronizable, INamedRWLock)
  private
    FMutex: THandle;          // 淇濇姢鍏变韩鐘舵€?    FReaderEvent: THandle;    // 鍏佽璇昏€呰繘鍏ワ紙鎵嬪姩閲嶇疆锛岄粯璁ゆ湁淇″彿锛?    FWriterEvent: THandle;    // 鍏佽鍐欒€呰繘鍏ワ紙鑷姩閲嶇疆锛?    FFileMapping: THandle;    // 鍏变韩鍐呭瓨
    FSharedData: Pointer;     // 鎸囧悜鍏变韩鐘舵€?    FName: string;
    FIsCreator: Boolean;
    FLastError: TWaitError;

    type
      PSharedRWLockData = ^TSharedRWLockData;
      TSharedRWLockData = record
        ActiveReaders: LongInt;   // 褰撳墠娲昏穬璇昏€呮暟
        WaitingWriters: LongInt;  // 绛夊緟鍐欒€呮暟
        WriterActive: LongInt;    // 鏄惁鏈夊啓鑰呮寔鏈夛紙0/1锛?        MaxReaders: LongInt;      // 鍏煎瀛楁锛堟湭寮哄埗浣跨敤锛?        Initialized: LongBool;    // 鏄惁宸插垵濮嬪寲
      end;

    function ValidateName(const AName: string): string;
    function CreateSharedMemory(const AName: string): Boolean;
    function CreateKernelObjects(const AName: string): Boolean;
    function BuildKernelObjectName(const APrefix, AName: string): string;
    function GetSharedData: PSharedRWLockData;
    procedure InitializeSharedData;

    // 鍐呴儴杈呭姪
    function AcquireMutexWithTimeout(ATimeoutMs: Cardinal): Boolean;
    function RemainingTimeout(const AStart: QWord; ATimeoutMs: Cardinal): Cardinal;

    // 閿佸疄鐜?    procedure InternalAcquireRead;
    procedure InternalReleaseRead;
    procedure InternalAcquireWrite;
    procedure InternalReleaseWrite;
    function InternalTryAcquireRead(ATimeoutMs: Cardinal): Boolean;
    function InternalTryAcquireWrite(ATimeoutMs: Cardinal): Boolean;
  public
    constructor Create(const AName: string); overload;
    constructor Create(const AName: string; AInitialOwner: Boolean); overload;
    destructor Destroy; override;

    // ISynchronizable
    function GetLastError: TWaitError;

    // 鐜颁唬鍖?API锛堣繑鍥炲畧鍗級
    function ReadLock: INamedRWLockReadGuard;
    function WriteLock: INamedRWLockWriteGuard;
    function TryReadLock: INamedRWLockReadGuard;
    function TryWriteLock: INamedRWLockWriteGuard;
    function TryReadLockFor(ATimeoutMs: Cardinal): INamedRWLockReadGuard;
    function TryWriteLockFor(ATimeoutMs: Cardinal): INamedRWLockWriteGuard;

    // 鏌ヨ
    function GetName: string;
    function GetHandle: Pointer; // 璋冭瘯鐢?    function GetReaderCount: Integer;
    function IsWriteLocked: Boolean;
  end;

implementation

{ TNamedRWLockReadGuard }

constructor TNamedRWLockReadGuard.Create(ARWLock: Pointer; const AName: string);
begin
  inherited Create;
  FRWLock := ARWLock;
  FName := AName;
  FReleased := False;
end;

destructor TNamedRWLockReadGuard.Destroy;
begin
  if not FReleased and Assigned(FRWLock) then
  begin
    TNamedRWLock(FRWLock).InternalReleaseRead;
    FReleased := True;
  end;
  inherited Destroy;
end;

function TNamedRWLockReadGuard.GetName: string;
begin
  Result := FName;
end;

{ TNamedRWLockWriteGuard }

constructor TNamedRWLockWriteGuard.Create(ARWLock: Pointer; const AName: string);
begin
  inherited Create;
  FRWLock := ARWLock;
  FName := AName;
  FReleased := False;
end;

destructor TNamedRWLockWriteGuard.Destroy;
begin
  if not FReleased and Assigned(FRWLock) then
  begin
    TNamedRWLock(FRWLock).InternalReleaseWrite;
    FReleased := True;
  end;
  inherited Destroy;
end;

function TNamedRWLockWriteGuard.GetName: string;
begin
  Result := FName;
end;

{ TNamedRWLock }

function TNamedRWLock.ValidateName(const AName: string): string;
var
  i: Integer;
begin
  if AName = '' then
    raise EInvalidArgument.Create('Named RWLock name cannot be empty');

  Result := AName;
  if Length(Result) > 260 then
    raise EInvalidArgument.Create('Named RWLock name too long (max 260 characters)');

  // Windows 瀵硅薄鍚嶇О闈炴硶瀛楃妫€鏌ワ紙鍏佽 Global\ / Local\ 鍓嶇紑锛?  for i := 1 to Length(Result) do
  begin
    if Result[i] in ['/', ':', '*', '?', '"', '<', '>', '|'] then
      raise EInvalidArgument.Create('Named RWLock name contains invalid characters');
  end;
end;

constructor TNamedRWLock.Create(const AName: string);
begin
  Create(AName, False);
end;

constructor TNamedRWLock.Create(const AName: string; AInitialOwner: Boolean);
var
  LName: string;
begin
  inherited Create;

  FLastError := weNone;
  LName := ValidateName(AName);
  FName := LName;
  FMutex := 0;
  FReaderEvent := 0;
  FWriterEvent := 0;
  FFileMapping := 0;
  FSharedData := nil;
  FIsCreator := False;

  if not CreateSharedMemory(LName) then
  begin
    if (Pos('Global\\', LName) = 1) and (Windows.GetLastError = ERROR_ACCESS_DENIED) then
    begin
      // 鏃犲叏灞€鍛藉悕鏉冮檺鏃堕€€鍥炲埌 Local\ 鍛藉悕绌洪棿锛屼絾瀵瑰鍚嶇О淇濇寔涓嶅彉
      LName := 'Local\\' + Copy(LName, Length('Global\\') + 1, MaxInt);
      if not CreateSharedMemory(LName) then
        raise ELockError.CreateFmt('Failed to create shared memory for named RWLock "%s": %s',
          [AName, SysErrorMessage(Windows.GetLastError)]);
    end
    else
      raise ELockError.CreateFmt('Failed to create shared memory for named RWLock "%s": %s',
        [AName, SysErrorMessage(Windows.GetLastError)]);
  end;

  if not CreateKernelObjects(LName) then
  begin
    if Assigned(FSharedData) then UnmapViewOfFile(FSharedData);
    if FFileMapping <> 0 then CloseHandle(FFileMapping);
    // 灏濊瘯鍦ㄧ己灏戝叏灞€鏉冮檺鏃堕€€鍥?Local\ 鍛藉悕绌洪棿
    if (Pos('Global\\', FName) = 1) and (Windows.GetLastError = ERROR_ACCESS_DENIED) then
    begin
      LName := 'Local\\' + Copy(FName, Length('Global\\') + 1, MaxInt);
      if CreateSharedMemory(LName) and CreateKernelObjects(LName) then
        ;
    end
    else
      raise ELockError.CreateFmt('Failed to create kernel objects for named RWLock "%s": %s',
        [AName, SysErrorMessage(Windows.GetLastError)]);
  end;

  // 鍒濆鎷ユ湁鍐欓攣锛氳繖閲屾寜闇€瀹炵幇锛涘綋鍓嶄笉鑷姩鍗犵敤锛堥伩鍏嶅鏉傛椂搴忥級
  // 璋冪敤鏂瑰彲鍦ㄦ敹鍒版帴鍙ｅ悗绔嬪埢璋冪敤 WriteLock 浠ヨ幏寰楀啓閿?end;

destructor TNamedRWLock.Destroy;
begin
  if Assigned(FSharedData) then
    UnmapViewOfFile(FSharedData);

  if FFileMapping <> 0 then
    CloseHandle(FFileMapping);

  if FReaderEvent <> 0 then
    CloseHandle(FReaderEvent);

  if FWriterEvent <> 0 then
    CloseHandle(FWriterEvent);

  if FMutex <> 0 then
    CloseHandle(FMutex);

  inherited Destroy;
end;

function TNamedRWLock.BuildKernelObjectName(const APrefix, AName: string): string;
const
  GLOBAL_PREFIX = 'Global\';
  LOCAL_PREFIX  = 'Local\';
begin
  if Pos(GLOBAL_PREFIX, AName) = 1 then
    Result := GLOBAL_PREFIX + APrefix + Copy(AName, Length(GLOBAL_PREFIX) + 1, MaxInt)
  else if Pos(LOCAL_PREFIX, AName) = 1 then
    Result := LOCAL_PREFIX + APrefix + Copy(AName, Length(LOCAL_PREFIX) + 1, MaxInt)
  else
    Result := APrefix + AName;
end;

function TNamedRWLock.CreateSharedMemory(const AName: string): Boolean;
var
  LMappingName: string;
  LSize: Cardinal;
begin
  Result := False;
  LMappingName := BuildKernelObjectName('fafafa_rwlock_', AName);
  LSize := SizeOf(TSharedRWLockData);

  FFileMapping := CreateFileMappingW(INVALID_HANDLE_VALUE, nil, PAGE_READWRITE, 0, LSize,
    PWideChar(UnicodeString(LMappingName)));
  if FFileMapping = 0 then Exit;

  FIsCreator := (Windows.GetLastError <> ERROR_ALREADY_EXISTS);

  FSharedData := MapViewOfFile(FFileMapping, FILE_MAP_ALL_ACCESS, 0, 0, LSize);
  if FSharedData = nil then
  begin
    CloseHandle(FFileMapping);
    FFileMapping := 0;
    Exit;
  end;

  if FIsCreator then
    InitializeSharedData;

  Result := True;
end;

function TNamedRWLock.CreateKernelObjects(const AName: string): Boolean;
var
  LMutexName, LReaderEvtName, LWriterEvtName: string;
  LExisted: Boolean;
begin
  Result := False;

  LMutexName := BuildKernelObjectName('fafafa_rwlock_mutex_', AName);
  LReaderEvtName := BuildKernelObjectName('fafafa_rwlock_reader_', AName);
  LWriterEvtName := BuildKernelObjectName('fafafa_rwlock_writer_', AName);

  // 浜掓枼閲忥紙闈炲垵濮嬫嫢鏈夛級
  FMutex := CreateMutexW(nil, False, PWideChar(UnicodeString(LMutexName)));
  if FMutex = 0 then Exit;

  // 璇讳簨浠讹細鎵嬪姩閲嶇疆锛岄粯璁ゅ厑璁歌鑰呰繘鍏ワ紙鏂板缓鏃惰涓烘湁淇″彿锛?  FReaderEvent := CreateEventW(nil, True, True, PWideChar(UnicodeString(LReaderEvtName)));
  if FReaderEvent = 0 then Exit;
  // 濡傛灉宸插瓨鍦紝淇濇寔鍏跺綋鍓嶇姸鎬侊紱濡傛灉鏄柊寤猴紝鍒濆涓烘湁淇″彿锛堝厑璁歌鑰咃級
  LExisted := (Windows.GetLastError = ERROR_ALREADY_EXISTS);
  if not LExisted then
    Windows.SetEvent(FReaderEvent);

  // 鍐欎簨浠讹細鑷姩閲嶇疆锛屽垵濮嬩负鏃犱俊鍙?  FWriterEvent := CreateEventW(nil, False, False, PWideChar(UnicodeString(LWriterEvtName)));
  if FWriterEvent = 0 then Exit;

  Result := True;
end;

function TNamedRWLock.GetSharedData: PSharedRWLockData;
begin
  Result := PSharedRWLockData(FSharedData);
end;

procedure TNamedRWLock.InitializeSharedData;
var
  LData: PSharedRWLockData;
begin
  LData := GetSharedData;
  if LData = nil then Exit;

  LData^.ActiveReaders := 0;
  LData^.WaitingWriters := 0;
  LData^.WriterActive := 0;
  LData^.MaxReaders := 1024;
  LData^.Initialized := True;
end;

function TNamedRWLock.GetLastError: TWaitError;
begin
  Result := FLastError;
end;

// ===== 鍏叡 API =====

function TNamedRWLock.ReadLock: INamedRWLockReadGuard;
begin
  InternalAcquireRead;
  Result := TNamedRWLockReadGuard.Create(Self, FName);
end;

function TNamedRWLock.WriteLock: INamedRWLockWriteGuard;
begin
  InternalAcquireWrite;
  Result := TNamedRWLockWriteGuard.Create(Self, FName);
end;

function TNamedRWLock.TryReadLock: INamedRWLockReadGuard;
begin
  if InternalTryAcquireRead(0) then
    Result := TNamedRWLockReadGuard.Create(Self, FName)
  else
    Result := nil;
end;

function TNamedRWLock.TryWriteLock: INamedRWLockWriteGuard;
begin
  if InternalTryAcquireWrite(0) then
    Result := TNamedRWLockWriteGuard.Create(Self, FName)
  else
    Result := nil;
end;

function TNamedRWLock.TryReadLockFor(ATimeoutMs: Cardinal): INamedRWLockReadGuard;
begin
  if InternalTryAcquireRead(ATimeoutMs) then
    Result := TNamedRWLockReadGuard.Create(Self, FName)
  else
    Result := nil;
end;

function TNamedRWLock.TryWriteLockFor(ATimeoutMs: Cardinal): INamedRWLockWriteGuard;
begin
  if InternalTryAcquireWrite(ATimeoutMs) then
    Result := TNamedRWLockWriteGuard.Create(Self, FName)
  else
    Result := nil;
end;

function TNamedRWLock.GetName: string;
begin
  Result := FName;
end;

function TNamedRWLock.GetHandle: Pointer;
begin
  Result := FSharedData;
end;

function TNamedRWLock.GetReaderCount: Integer;
var
  LData: PSharedRWLockData;
begin
  LData := GetSharedData;
  if Assigned(LData) then
    Result := LData^.ActiveReaders
  else
    Result := 0;
end;

function TNamedRWLock.IsWriteLocked: Boolean;
var
  LData: PSharedRWLockData;
begin
  LData := GetSharedData;
  Result := Assigned(LData) and (LData^.WriterActive <> 0);
end;

// ===== 鍐呴儴杈呭姪 =====

function TNamedRWLock.AcquireMutexWithTimeout(ATimeoutMs: Cardinal): Boolean;
var
  LRes: DWORD;
begin
  LRes := WaitForSingleObject(FMutex, ATimeoutMs);
  case LRes of
    WAIT_OBJECT_0: Result := True;
    WAIT_TIMEOUT:
      begin
        FLastError := weTimeout;
        Result := False;
      end;
  else
    FLastError := weSystemError;
    Result := False;
  end;
end;

function TNamedRWLock.RemainingTimeout(const AStart: QWord; ATimeoutMs: Cardinal): Cardinal;
var
  NowTs: QWord;
  Elapsed: QWord;
begin
  if ATimeoutMs = INFINITE then
    exit(INFINITE);
  NowTs := GetTickCount64;
  Elapsed := NowTs - AStart;
  if Elapsed >= ATimeoutMs then
    Result := 0
  else
    Result := ATimeoutMs - Elapsed;
end;

// ===== 璇婚攣瀹炵幇 =====

procedure TNamedRWLock.InternalAcquireRead;
var
  LData: PSharedRWLockData;
begin
  LData := GetSharedData;
  if not Assigned(LData) then
    raise ELockError.Create('Shared data not available');

  // 闃诲鐩磋嚦鍏佽璇伙紙鏃犺秴鏃讹級
  if not AcquireMutexWithTimeout(INFINITE) then
    raise ELockError.Create('Failed to enter mutex for read lock');
  try
    while (LData^.WriterActive <> 0) or (LData^.WaitingWriters > 0) do
    begin
      ReleaseMutex(FMutex);
      // 绛夊緟璇昏€呬簨浠讹紝鐩村埌鏃犲啓鑰呴渶姹?      WaitForSingleObject(FReaderEvent, INFINITE);
      if not AcquireMutexWithTimeout(INFINITE) then
        raise ELockError.Create('Failed to re-enter mutex for read lock');
    end;

    atomic_increment(PInt32(@LData^.ActiveReaders)^);
    // 鍏佽鍚庣画璇昏€呰繘鍏?    Windows.SetEvent(FReaderEvent);
  finally
    ReleaseMutex(FMutex);
  end;
end;

procedure TNamedRWLock.InternalReleaseRead;
var
  LData: PSharedRWLockData;
  NewCount: LongInt;
begin
  LData := GetSharedData;
  if not Assigned(LData) then
    raise ELockError.Create('Shared data not available');

  if not AcquireMutexWithTimeout(INFINITE) then
    raise ELockError.Create('Failed to enter mutex for read unlock');
  try
    NewCount := atomic_decrement(PInt32(@LData^.ActiveReaders)^);
    if (NewCount = 0) and (LData^.WaitingWriters > 0) then
    begin
      // 浼樺厛鍞ら啋鍐欒€?      Windows.SetEvent(FWriterEvent);
      // 闃绘鏂拌鑰呰繘鍏?      Windows.ResetEvent(FReaderEvent);
    end;
  finally
    ReleaseMutex(FMutex);
  end;
end;

// ===== 鍐欓攣瀹炵幇 =====

procedure TNamedRWLock.InternalAcquireWrite;
begin
  if not InternalTryAcquireWrite(INFINITE) then
    raise ELockError.Create('Failed to acquire write lock');
end;

procedure TNamedRWLock.InternalReleaseWrite;
var
  LData: PSharedRWLockData;
begin
  LData := GetSharedData;
  if not Assigned(LData) then
    raise ELockError.Create('Shared data not available');

  if not AcquireMutexWithTimeout(INFINITE) then
    raise ELockError.Create('Failed to enter mutex for write unlock');
  try
    LData^.WriterActive := 0;
    if LData^.WaitingWriters > 0 then
    begin
      // 鍞ら啋涓嬩竴涓啓鑰?      Windows.SetEvent(FWriterEvent);
      // 缁х画闃绘嫤鏂拌鑰呬互渚垮啓鑰呭厛鑾峰緱
      Windows.ResetEvent(FReaderEvent);
    end
    else
    begin
      // 娌℃湁鍐欒€呯瓑寰咃紝鍏佽璇昏€呰繘鍏?      Windows.SetEvent(FReaderEvent);
    end;
  finally
    ReleaseMutex(FMutex);
  end;
end;

function TNamedRWLock.InternalTryAcquireRead(ATimeoutMs: Cardinal): Boolean;
var
  LData: PSharedRWLockData;
  StartTick: QWord;
  TimeLeft: Cardinal;
  WaitRes: DWORD;
begin
  Result := False;
  FLastError := weNone;

  LData := GetSharedData;
  if not Assigned(LData) then
    raise ELockError.Create('Shared data not available');

  StartTick := GetTickCount64;
  TimeLeft := ATimeoutMs;

  if not AcquireMutexWithTimeout(TimeLeft) then Exit(False);
  try
    while (LData^.WriterActive <> 0) or (LData^.WaitingWriters > 0) do
    begin
      ReleaseMutex(FMutex);
      TimeLeft := RemainingTimeout(StartTick, ATimeoutMs);
      if TimeLeft = 0 then
      begin
        FLastError := weTimeout;
        Exit(False);
      end;
      WaitRes := WaitForSingleObject(FReaderEvent, TimeLeft);
      if WaitRes <> WAIT_OBJECT_0 then
      begin
        if WaitRes = WAIT_TIMEOUT then FLastError := weTimeout
        else FLastError := weSystemError;
        Exit(False);
      end;
      TimeLeft := RemainingTimeout(StartTick, ATimeoutMs);
      if not AcquireMutexWithTimeout(TimeLeft) then Exit(False);
    end;

    atomic_increment(PInt32(@LData^.ActiveReaders)^);
    Windows.SetEvent(FReaderEvent);
    Result := True;
  finally
    ReleaseMutex(FMutex);
  end;
end;

function TNamedRWLock.InternalTryAcquireWrite(ATimeoutMs: Cardinal): Boolean;
var
  LData: PSharedRWLockData;
  StartTick: QWord;
  TimeLeft: Cardinal;
  WaitRes: DWORD;
  FirstWriter: Boolean;
begin
  Result := False;
  FLastError := weNone;

  LData := GetSharedData;
  if not Assigned(LData) then
    raise ELockError.Create('Shared data not available');

  StartTick := GetTickCount64;
  TimeLeft := ATimeoutMs;

  if not AcquireMutexWithTimeout(TimeLeft) then Exit(False);
  try
    // 澧炲姞绛夊緟鍐欒€呰鏁帮紝骞跺湪浠?0->1 鏃堕樆姝㈡柊璇昏€呰繘鍏?    FirstWriter := (LData^.WaitingWriters = 0);
    atomic_increment(PInt32(@LData^.WaitingWriters)^);
    if FirstWriter then
      Windows.ResetEvent(FReaderEvent);

    while (LData^.WriterActive <> 0) or (LData^.ActiveReaders > 0) do
    begin
      ReleaseMutex(FMutex);
      TimeLeft := RemainingTimeout(StartTick, ATimeoutMs);
      if TimeLeft = 0 then
      begin
        // 瓒呮椂锛氭挙閿€绛夊緟鍐欒€呭苟鎭㈠璇昏€呬簨浠讹紙濡傛湁蹇呰锛?        if AcquireMutexWithTimeout(INFINITE) then
        try
          atomic_decrement(PInt32(@LData^.WaitingWriters)^);
          if LData^.WaitingWriters = 0 then
            Windows.SetEvent(FReaderEvent);
        finally
          ReleaseMutex(FMutex);
        end;
        FLastError := weTimeout;
        Exit(False);
      end;

      WaitRes := WaitForSingleObject(FWriterEvent, TimeLeft);
      if WaitRes <> WAIT_OBJECT_0 then
      begin
        if AcquireMutexWithTimeout(INFINITE) then
        try
          atomic_decrement(PInt32(@LData^.WaitingWriters)^);
          if LData^.WaitingWriters = 0 then
            Windows.SetEvent(FReaderEvent);
        finally
          ReleaseMutex(FMutex);
        end;
        if WaitRes = WAIT_TIMEOUT then FLastError := weTimeout
        else FLastError := weSystemError;
        Exit(False);
      end;

      // 琚敜閱掑悗缁х画寰幆锛岀洿鍒板彲浠ヨ幏寰楀啓閿?      if not AcquireMutexWithTimeout(RemainingTimeout(StartTick, ATimeoutMs)) then Exit(False);
    end;

    // 鑾峰緱鍐欓攣
    LData^.WriterActive := 1;
    atomic_decrement(PInt32(@LData^.WaitingWriters)^);
    Result := True;
  finally
    ReleaseMutex(FMutex);
  end;
end;

end.

