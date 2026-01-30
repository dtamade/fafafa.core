unit fafafa.core.sync.namedRWLock.windows;

{$mode objfpc}
{$I fafafa.core.settings.inc}

interface

uses
  Windows, SysUtils,
  fafafa.core.base, fafafa.core.sync.base, fafafa.core.atomic, fafafa.core.sync.namedRWLock.base;

type
  // ===== RAII Read Lock Guard =====
  TNamedRWLockReadGuard = class(TInterfacedObject, INamedRWLockReadGuard)
  private
    FRWLock: Pointer;  // Points to TNamedRWLock
    FName: string;
    FReleased: Boolean;
  public
    constructor Create(ARWLock: Pointer; const AName: string);
    destructor Destroy; override;
    function GetName: string;
  end;

  // ===== RAII Write Lock Guard =====
  TNamedRWLockWriteGuard = class(TInterfacedObject, INamedRWLockWriteGuard)
  private
    FRWLock: Pointer;  // Points to TNamedRWLock
    FName: string;
    FReleased: Boolean;
  public
    constructor Create(ARWLock: Pointer; const AName: string);
    destructor Destroy; override;
    function GetName: string;
  end;

  // ===== Windows Named RWLock (Cross-Process) =====
  // Implementation based on:
  // - Shared memory state (active readers, waiting writers, writer flag)
  // - Named mutex (protects shared state)
  // - Named events:
  //   * ReaderEvent (manual reset): allows/blocks new readers
  //   * WriterEvent (auto reset): wakes one waiting writer
  // Note: Not using SRWLOCK/CONDITION_VARIABLE (process-local only)
  TNamedRWLock = class(TSynchronizable, INamedRWLock)
  private
    FMutex: THandle;          // Protects shared state
    FReaderEvent: THandle;    // Allows readers to enter (manual reset, default signaled)
    FWriterEvent: THandle;    // Allows writer to enter (auto reset)
    FFileMapping: THandle;    // Shared memory
    FSharedData: Pointer;     // Points to shared state
    FName: string;
    FIsCreator: Boolean;
    FLastError: TWaitError;

    type
      PSharedRWLockData = ^TSharedRWLockData;
      TSharedRWLockData = record
        ActiveReaders: LongInt;   // Current active reader count
        WaitingWriters: LongInt;  // Waiting writer count
        WriterActive: LongInt;    // Writer holds lock (0/1)
        MaxReaders: LongInt;      // Compatibility field (not enforced)
        Initialized: LongBool;    // Is initialized
      end;

    function ValidateName(const AName: string): string;
    function CreateSharedMemory(const AName: string): Boolean;
    function CreateKernelObjects(const AName: string): Boolean;
    function BuildKernelObjectName(const APrefix, AName: string): string;
    function GetSharedData: PSharedRWLockData;
    procedure InitializeSharedData;

    // Internal helpers
    function AcquireMutexWithTimeout(ATimeoutMs: Cardinal): Boolean;
    function RemainingTimeout(const AStart: QWord; ATimeoutMs: Cardinal): Cardinal;

    // Lock implementation
    procedure InternalAcquireRead;
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

    // Modern API (returns guards)
    function ReadLock: INamedRWLockReadGuard;
    function WriteLock: INamedRWLockWriteGuard;
    function TryReadLock: INamedRWLockReadGuard;
    function TryWriteLock: INamedRWLockWriteGuard;
    function TryReadLockFor(ATimeoutMs: Cardinal): INamedRWLockReadGuard;
    function TryWriteLockFor(ATimeoutMs: Cardinal): INamedRWLockWriteGuard;

    // Query
    function GetName: string;
    function GetHandle: Pointer; // For debugging
    function GetReaderCount: Integer;
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

  // Windows object name illegal character check (allowing Global\ / Local\ prefix)
  for i := 1 to Length(Result) do
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
    if (Pos('Global\', LName) = 1) and (Windows.GetLastError = ERROR_ACCESS_DENIED) then
    begin
      // Fall back to Local\ namespace when lacking global permission
      LName := 'Local\' + Copy(LName, Length('Global\') + 1, MaxInt);
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
    // Try to fall back to Local\ namespace when lacking global permission
    if (Pos('Global\', FName) = 1) and (Windows.GetLastError = ERROR_ACCESS_DENIED) then
    begin
      LName := 'Local\' + Copy(FName, Length('Global\') + 1, MaxInt);
      if CreateSharedMemory(LName) and CreateKernelObjects(LName) then
        ;
    end
    else
      raise ELockError.CreateFmt('Failed to create kernel objects for named RWLock "%s": %s',
        [AName, SysErrorMessage(Windows.GetLastError)]);
  end;

  // Initial owner for write lock: not auto-acquired to avoid complex timing
  // Caller can call WriteLock immediately after receiving the interface
end;

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

  // Mutex (not initially owned)
  FMutex := CreateMutexW(nil, False, PWideChar(UnicodeString(LMutexName)));
  if FMutex = 0 then Exit;

  // Reader event: manual reset, default allows readers (signaled for new)
  FReaderEvent := CreateEventW(nil, True, True, PWideChar(UnicodeString(LReaderEvtName)));
  if FReaderEvent = 0 then Exit;
  // If already exists, keep current state; if new, initialize as signaled (allow readers)
  LExisted := (Windows.GetLastError = ERROR_ALREADY_EXISTS);
  if not LExisted then
    Windows.SetEvent(FReaderEvent);

  // Writer event: auto reset, initially non-signaled
  FWriterEvent := CreateEventW(nil, False, False, PWideChar(UnicodeString(LWriterEvtName)));
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

// ===== Public API =====

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

// ===== Internal helpers =====

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

// ===== Read lock implementation =====

procedure TNamedRWLock.InternalAcquireRead;
var
  LData: PSharedRWLockData;
begin
  LData := GetSharedData;
  if not Assigned(LData) then
    raise ELockError.Create('Shared data not available');

  // Block until allowed to read (no timeout)
  if not AcquireMutexWithTimeout(INFINITE) then
    raise ELockError.Create('Failed to enter mutex for read lock');
  try
    while (LData^.WriterActive <> 0) or (LData^.WaitingWriters > 0) do
    begin
      ReleaseMutex(FMutex);
      // Wait for reader event until no writer demand
      WaitForSingleObject(FReaderEvent, INFINITE);
      if not AcquireMutexWithTimeout(INFINITE) then
        raise ELockError.Create('Failed to re-enter mutex for read lock');
    end;

    atomic_increment(PInt32(@LData^.ActiveReaders)^);
    // Allow subsequent readers to enter
    Windows.SetEvent(FReaderEvent);
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
      // Prioritize waking writer
      Windows.SetEvent(FWriterEvent);
      // Block new readers
      Windows.ResetEvent(FReaderEvent);
    end;
  finally
    ReleaseMutex(FMutex);
  end;
end;

// ===== Write lock implementation =====

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
      // Wake next writer
      Windows.SetEvent(FWriterEvent);
      // Continue blocking new readers so writer gets priority
      Windows.ResetEvent(FReaderEvent);
    end
    else
    begin
      // No writers waiting, allow readers to enter
      Windows.SetEvent(FReaderEvent);
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
    // Increment waiting writer count, block new readers when going from 0->1
    FirstWriter := (LData^.WaitingWriters = 0);
    atomic_increment(PInt32(@LData^.WaitingWriters)^);
    if FirstWriter then
      Windows.ResetEvent(FReaderEvent);

    // Wait until no active readers and no other writer
    while (LData^.ActiveReaders > 0) or (LData^.WriterActive <> 0) do
    begin
      ReleaseMutex(FMutex);
      TimeLeft := RemainingTimeout(StartTick, ATimeoutMs);
      if TimeLeft = 0 then
      begin
        // Timeout: decrement waiting writers
        if AcquireMutexWithTimeout(0) then
        begin
          if atomic_decrement(PInt32(@LData^.WaitingWriters)^) = 0 then
            Windows.SetEvent(FReaderEvent);
          ReleaseMutex(FMutex);
        end;
        FLastError := weTimeout;
        Exit(False);
      end;
      WaitRes := WaitForSingleObject(FWriterEvent, TimeLeft);
      if WaitRes <> WAIT_OBJECT_0 then
      begin
        // Failed to acquire: decrement waiting writers
        if AcquireMutexWithTimeout(0) then
        begin
          if atomic_decrement(PInt32(@LData^.WaitingWriters)^) = 0 then
            Windows.SetEvent(FReaderEvent);
          ReleaseMutex(FMutex);
        end;
        if WaitRes = WAIT_TIMEOUT then FLastError := weTimeout
        else FLastError := weSystemError;
        Exit(False);
      end;
      TimeLeft := RemainingTimeout(StartTick, ATimeoutMs);
      if not AcquireMutexWithTimeout(TimeLeft) then
      begin
        // Timeout: decrement waiting writers
        if AcquireMutexWithTimeout(0) then
        begin
          if atomic_decrement(PInt32(@LData^.WaitingWriters)^) = 0 then
            Windows.SetEvent(FReaderEvent);
          ReleaseMutex(FMutex);
        end;
        Exit(False);
      end;
    end;

    // Acquired write lock
    atomic_decrement(PInt32(@LData^.WaitingWriters)^);
    LData^.WriterActive := 1;
    Result := True;
  finally
    ReleaseMutex(FMutex);
  end;
end;

end.
