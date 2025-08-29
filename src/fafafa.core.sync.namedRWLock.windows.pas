unit fafafa.core.sync.namedRWLock.windows;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  Windows, SysUtils,
  fafafa.core.base, fafafa.core.sync.base, fafafa.core.sync.namedRWLock.base;

// Windows 条件变量 API 声明
type
  CONDITION_VARIABLE = record
    Ptr: Pointer;
  end;
  PCONDITION_VARIABLE = ^CONDITION_VARIABLE;

// Windows API 函数声明
procedure InitializeConditionVariable(ConditionVariable: PCONDITION_VARIABLE); stdcall; external kernel32;
function SleepConditionVariableSRW(ConditionVariable: PCONDITION_VARIABLE;
  SRWLock: Pointer; dwMilliseconds: DWORD; Flags: ULONG): BOOL; stdcall; external kernel32;
procedure WakeConditionVariable(ConditionVariable: PCONDITION_VARIABLE); stdcall; external kernel32;
procedure WakeAllConditionVariable(ConditionVariable: PCONDITION_VARIABLE); stdcall; external kernel32;

const
  CONDITION_VARIABLE_LOCKMODE_SHARED = $1;

type
  // RAII 读锁守卫实现
  TNamedRWLockReadGuard = class(TInterfacedObject, INamedRWLockReadGuard)
  private
    FRWLock: Pointer;  // 指向 TNamedRWLock
    FName: string;
    FReleased: Boolean;
  public
    constructor Create(ARWLock: Pointer; const AName: string);
    destructor Destroy; override;
    function GetName: string;
  end;

  // RAII 写锁守卫实现
  TNamedRWLockWriteGuard = class(TInterfacedObject, INamedRWLockWriteGuard)
  private
    FRWLock: Pointer;  // 指向 TNamedRWLock
    FName: string;
    FReleased: Boolean;
  public
    constructor Create(ARWLock: Pointer; const AName: string);
    destructor Destroy; override;
    function GetName: string;
  end;

  TNamedRWLock = class(TInterfacedObject, INamedRWLock)
  private
    FFileMapping: THandle;      // 文件映射句柄
    FSharedData: Pointer;       // 共享数据指针
    FName: string;
    FIsCreator: Boolean;
    FLastError: TWaitError;
    
    // 共享数据结构
    type
      PSharedRWLockData = ^TSharedRWLockData;
      TSharedRWLockData = record
        SRWLock: SRWLOCK;         // Windows 原生读写锁
        ReaderCount: Integer;     // 读者计数
        WriterThread: DWORD;      // 写者线程ID
        MaxReaders: Integer;      // 最大读者数量
        Initialized: Boolean;     // 初始化标志
        // 条件变量用于高效的超时等待
        ReaderCV: CONDITION_VARIABLE;  // 读者条件变量
        WriterCV: CONDITION_VARIABLE;  // 写者条件变量
      end;
    
    function ValidateName(const AName: string): string;
    function CreateSharedMemory(const AName: string; AInitialOwner: Boolean): Boolean;
    function GetSharedData: PSharedRWLockData;
    procedure InitializeSharedData;
  public
    constructor Create(const AName: string); overload;
    constructor Create(const AName: string; AInitialOwner: Boolean); overload;
    destructor Destroy; override;
    
    // ISynchronizable 接口
    function GetLastError: TWaitError;

    // 现代化 API
    function ReadLock: INamedRWLockReadGuard;
    function WriteLock: INamedRWLockWriteGuard;
    function TryReadLock: INamedRWLockReadGuard;
    function TryWriteLock: INamedRWLockWriteGuard;
    function TryReadLockFor(ATimeoutMs: Cardinal): INamedRWLockReadGuard;
    function TryWriteLockFor(ATimeoutMs: Cardinal): INamedRWLockWriteGuard;

    // 查询操作
    function GetName: string;

    // 状态查询方法
    function GetHandle: Pointer;
    function GetReaderCount: Integer;
    function IsWriteLocked: Boolean;
    
    // 内部方法
    procedure InternalAcquireRead;
    procedure InternalReleaseRead;
    procedure InternalAcquireWrite;
    procedure InternalReleaseWrite;
    function InternalTryAcquireRead(ATimeoutMs: Cardinal): Boolean;
    function InternalTryAcquireWrite(ATimeoutMs: Cardinal): Boolean;
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
begin
  if AName = '' then
    raise EInvalidArgument.Create('Named RWLock name cannot be empty');
  
  // Windows 命名对象名称规则：
  // - 不能包含反斜杠 (\)
  // - 长度限制为 MAX_PATH (260) 字符
  // - 可以包含 Global\ 或 Local\ 前缀
  Result := AName;
  if Length(Result) > MAX_PATH then
    raise EInvalidArgument.Create('Named RWLock name too long (max 260 characters)');
  
  if Pos('\', Result) > 0 then
  begin
    // 只允许 Global\ 或 Local\ 前缀
    if not ((Pos('Global\', Result) = 1) or (Pos('Local\', Result) = 1)) then
      raise EInvalidArgument.Create('Invalid characters in RWLock name');
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
  
  LName := ValidateName(AName);
  FName := LName;
  FLastError := weNone;
  
  if not CreateSharedMemory(LName, AInitialOwner) then
    raise ELockError.CreateFmt('Failed to create named RWLock "%s": %s', 
      [LName, SysErrorMessage(GetLastError)]);
end;

destructor TNamedRWLock.Destroy;
begin
  if Assigned(FSharedData) then
    UnmapViewOfFile(FSharedData);
  
  if FFileMapping <> 0 then
    CloseHandle(FFileMapping);
  
  inherited Destroy;
end;

function TNamedRWLock.CreateSharedMemory(const AName: string; AInitialOwner: Boolean): Boolean;
var
  LMappingName: string;
  LLastError: DWORD;
begin
  Result := False;
  
  // 创建文件映射名称
  LMappingName := 'Global\RWLock_' + AName;
  
  // 创建或打开文件映射
  FFileMapping := CreateFileMappingA(INVALID_HANDLE_VALUE, nil, PAGE_READWRITE, 0, 
    SizeOf(TSharedRWLockData), PAnsiChar(AnsiString(LMappingName)));
  
  if FFileMapping = 0 then
    Exit;
  
  LLastError := GetLastError;
  FIsCreator := (LLastError <> ERROR_ALREADY_EXISTS);
  
  // 映射视图
  FSharedData := MapViewOfFile(FFileMapping, FILE_MAP_ALL_ACCESS, 0, 0, 0);
  if not Assigned(FSharedData) then
  begin
    CloseHandle(FFileMapping);
    FFileMapping := 0;
    Exit;
  end;
  
  // 初始化共享数据
  if FIsCreator then
    InitializeSharedData;
  
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
  if Assigned(LData) then
  begin
    InitializeSRWLock(@LData^.SRWLock);
    InitializeConditionVariable(@LData^.ReaderCV);
    InitializeConditionVariable(@LData^.WriterCV);
    LData^.ReaderCount := 0;
    LData^.WriterThread := 0;
    LData^.MaxReaders := 1024;
    LData^.Initialized := True;
  end;
end;

function TNamedRWLock.GetLastError: TWaitError;
begin
  Result := FLastError;
end;

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

// 状态查询方法实现

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
    Result := LData^.ReaderCount
  else
    Result := 0;
end;

function TNamedRWLock.IsWriteLocked: Boolean;
var
  LData: PSharedRWLockData;
begin
  LData := GetSharedData;
  if Assigned(LData) then
    Result := (LData^.WriterThread <> 0)
  else
    Result := False;
end;

// 内部实现方法
procedure TNamedRWLock.InternalAcquireRead;
var
  LData: PSharedRWLockData;
begin
  LData := GetSharedData;
  if not Assigned(LData) then
    raise ELockError.Create('Shared data not available');

  AcquireSRWLockShared(@LData^.SRWLock);
  InterlockedIncrement(LData^.ReaderCount);
end;

procedure TNamedRWLock.InternalReleaseRead;
var
  LData: PSharedRWLockData;
  LReaderCount: Integer;
begin
  LData := GetSharedData;
  if not Assigned(LData) then
    raise ELockError.Create('Shared data not available');

  LReaderCount := InterlockedDecrement(LData^.ReaderCount);
  ReleaseSRWLockShared(@LData^.SRWLock);

  // 如果是最后一个读者，唤醒等待的写者
  if LReaderCount = 0 then
    WakeConditionVariable(@LData^.WriterCV);
end;

procedure TNamedRWLock.InternalAcquireWrite;
var
  LData: PSharedRWLockData;
begin
  LData := GetSharedData;
  if not Assigned(LData) then
    raise ELockError.Create('Shared data not available');

  AcquireSRWLockExclusive(@LData^.SRWLock);
  LData^.WriterThread := GetCurrentThreadId;
end;

procedure TNamedRWLock.InternalReleaseWrite;
var
  LData: PSharedRWLockData;
begin
  LData := GetSharedData;
  if not Assigned(LData) then
    raise ELockError.Create('Shared data not available');

  LData^.WriterThread := 0;
  ReleaseSRWLockExclusive(@LData^.SRWLock);

  // 写锁释放后，唤醒所有等待的读者和写者
  WakeAllConditionVariable(@LData^.ReaderCV);
  WakeConditionVariable(@LData^.WriterCV);
end;

function TNamedRWLock.InternalTryAcquireRead(ATimeoutMs: Cardinal): Boolean;
var
  LData: PSharedRWLockData;
  LStartTime: DWORD;
  LWaitTime: DWORD;
begin
  LData := GetSharedData;
  if not Assigned(LData) then
    raise ELockError.Create('Shared data not available');

  if ATimeoutMs = 0 then
  begin
    // 非阻塞尝试
    Result := TryAcquireSRWLockShared(@LData^.SRWLock);
    if Result then
      InterlockedIncrement(LData^.ReaderCount);
  end
  else
  begin
    // 使用条件变量的高效超时实现
    LStartTime := GetTickCount;
    repeat
      // 尝试获取读锁
      if TryAcquireSRWLockShared(@LData^.SRWLock) then
      begin
        InterlockedIncrement(LData^.ReaderCount);
        Result := True;
        Break;
      end;

      // 如果无法获取，使用条件变量等待一小段时间
      AcquireSRWLockShared(@LData^.SRWLock);
      if LData^.WriterThread = 0 then
      begin
        // 写者已释放，可以获取读锁
        InterlockedIncrement(LData^.ReaderCount);
        ReleaseSRWLockShared(@LData^.SRWLock);
        Result := True;
        Break;
      end
      else
      begin
        // 等待写者释放
        LWaitTime := ATimeoutMs - (GetTickCount - LStartTime);
        if LWaitTime > 100 then LWaitTime := 100;
        Result := SleepConditionVariableSRW(@LData^.ReaderCV, @LData^.SRWLock,
          LWaitTime, CONDITION_VARIABLE_LOCKMODE_SHARED);
        ReleaseSRWLockShared(@LData^.SRWLock);
        if not Result then
          Break; // 超时
      end;
    until (GetTickCount - LStartTime) >= ATimeoutMs;
  end;
end;

function TNamedRWLock.InternalTryAcquireWrite(ATimeoutMs: Cardinal): Boolean;
var
  LData: PSharedRWLockData;
  LStartTime: DWORD;
  LWaitTime: DWORD;
begin
  LData := GetSharedData;
  if not Assigned(LData) then
    raise ELockError.Create('Shared data not available');

  if ATimeoutMs = 0 then
  begin
    // 非阻塞尝试
    Result := TryAcquireSRWLockExclusive(@LData^.SRWLock);
    if Result then
      LData^.WriterThread := GetCurrentThreadId;
  end
  else
  begin
    // 使用条件变量的高效超时实现
    LStartTime := GetTickCount;
    repeat
      // 尝试获取写锁
      if TryAcquireSRWLockExclusive(@LData^.SRWLock) then
      begin
        LData^.WriterThread := GetCurrentThreadId;
        Result := True;
        Break;
      end;

      // 如果无法获取，使用条件变量等待一小段时间
      AcquireSRWLockExclusive(@LData^.SRWLock);
      if (LData^.WriterThread = 0) and (LData^.ReaderCount = 0) then
      begin
        // 可以获取写锁
        LData^.WriterThread := GetCurrentThreadId;
        ReleaseSRWLockExclusive(@LData^.SRWLock);
        Result := True;
        Break;
      end
      else
      begin
        // 等待读者/写者释放
        LWaitTime := ATimeoutMs - (GetTickCount - LStartTime);
        if LWaitTime > 100 then LWaitTime := 100;
        Result := SleepConditionVariableSRW(@LData^.WriterCV, @LData^.SRWLock,
          LWaitTime, 0);
        ReleaseSRWLockExclusive(@LData^.SRWLock);
        if not Result then
          Break; // 超时
      end;
    until (GetTickCount - LStartTime) >= ATimeoutMs;
  end;
end;

end.
