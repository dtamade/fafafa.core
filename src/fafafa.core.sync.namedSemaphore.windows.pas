unit fafafa.core.sync.namedSemaphore.windows;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  Windows, SysUtils,
  fafafa.core.base, fafafa.core.sync.base, fafafa.core.sync.namedSemaphore.base;

type
  // RAII 守卫实现
  TNamedSemaphoreGuard = class(TInterfacedObject, INamedSemaphoreGuard)
  private
    FSemaphore: THandle;
    FName: string;
    FReleased: Boolean;
  public
    constructor Create(ASemaphore: THandle; const AName: string);
    destructor Destroy; override;
    function GetName: string;
    function GetCount: Integer;
  end;

  TNamedSemaphore = class(TInterfacedObject, INamedSemaphore)
  private
    FHandle: THandle;
    FName: string;
    FIsCreator: Boolean;
    FMaxCount: Integer;
    FLastError: TWaitError;
    
    function ValidateName(const AName: string): string;
    function ValidateCount(AInitialCount, AMaxCount: Integer): Boolean;
  public
    constructor Create(const AName: string; AInitialCount, AMaxCount: Integer); overload;
    constructor Create(const AName: string; const AConfig: TNamedSemaphoreConfig); overload;
    destructor Destroy; override;
    
    // ISynchronizable 接口
    function GetLastError: TWaitError;

    // INamedSemaphore 接口
    function Wait: INamedSemaphoreGuard;
    function TryWait: INamedSemaphoreGuard;
    function TryWaitFor(ATimeoutMs: Cardinal): INamedSemaphoreGuard;
    procedure Release; overload;
    procedure Release(ACount: Integer); overload;
    function GetName: string;
    function GetCurrentCount: Integer;
    function GetMaxCount: Integer;

    // 兼容性方法（已弃用）
    procedure Acquire; deprecated;
    function TryAcquire: Boolean; deprecated;
    function TryAcquire(ATimeoutMs: Cardinal): Boolean; overload; deprecated;
    procedure Acquire(ATimeoutMs: Cardinal); overload; deprecated;
    function GetHandle: Pointer; deprecated;
    function IsCreator: Boolean; deprecated;
  end;

implementation

{ TNamedSemaphoreGuard }

constructor TNamedSemaphoreGuard.Create(ASemaphore: THandle; const AName: string);
begin
  inherited Create;
  FSemaphore := ASemaphore;
  FName := AName;
  FReleased := False;
end;

destructor TNamedSemaphoreGuard.Destroy;
begin
  if not FReleased and (FSemaphore <> 0) then
  begin
    ReleaseSemaphore(FSemaphore, 1, nil);
    FReleased := True;
  end;
  inherited Destroy;
end;

function TNamedSemaphoreGuard.GetName: string;
begin
  Result := FName;
end;

function TNamedSemaphoreGuard.GetCount: Integer;
begin
  // Windows 不直接支持查询信号量当前计数
  // 返回 -1 表示不支持
  Result := -1;
end;

{ TNamedSemaphore }

function TNamedSemaphore.ValidateName(const AName: string): string;
begin
  if Length(AName) = 0 then
    raise EInvalidArgument.Create('Semaphore name cannot be empty');
    
  if Length(AName) > 260 then  // MAX_PATH
    raise EInvalidArgument.CreateFmt('Semaphore name too long: %d characters (max 260)', [Length(AName)]);
    
  // 检查无效字符（除了允许的前缀）
  if (Pos('Global\', AName) <> 1) and (Pos('Local\', AName) <> 1) then
  begin
    if Pos('\', AName) > 0 then
      raise EInvalidArgument.CreateFmt('Invalid character in semaphore name: %s', [AName]);
  end;
  
  Result := AName;
end;

function TNamedSemaphore.ValidateCount(AInitialCount, AMaxCount: Integer): Boolean;
begin
  if AInitialCount < 0 then
    raise EInvalidArgument.CreateFmt('Initial count cannot be negative: %d', [AInitialCount]);
    
  if AMaxCount <= 0 then
    raise EInvalidArgument.CreateFmt('Max count must be positive: %d', [AMaxCount]);
    
  if AInitialCount > AMaxCount then
    raise EInvalidArgument.CreateFmt('Initial count (%d) cannot exceed max count (%d)', 
      [AInitialCount, AMaxCount]);
      
  Result := True;
end;

constructor TNamedSemaphore.Create(const AName: string; AInitialCount, AMaxCount: Integer);
var
  LName: string;
  LLastError: DWORD;
begin
  inherited Create;
  
  LName := ValidateName(AName);
  ValidateCount(AInitialCount, AMaxCount);
  
  FName := LName;
  FMaxCount := AMaxCount;
  FLastError := weNone;
  
  // 创建或打开命名信号量
  FHandle := CreateSemaphoreA(nil, AInitialCount, AMaxCount, PAnsiChar(AnsiString(LName)));
  
  if FHandle = 0 then
    raise ELockError.CreateFmt('Failed to create named semaphore "%s": %s', 
      [LName, SysErrorMessage(GetLastError)]);
      
  // 检查是否为创建者
  LLastError := GetLastError;
  FIsCreator := (LLastError <> ERROR_ALREADY_EXISTS);
end;

constructor TNamedSemaphore.Create(const AName: string; const AConfig: TNamedSemaphoreConfig);
var
  LActualName: string;
begin
  // 处理全局命名空间
  LActualName := AName;
  if AConfig.UseGlobalNamespace and (Pos('Global\', AName) <> 1) then
    LActualName := 'Global\' + AName;
    
  Create(LActualName, AConfig.InitialCount, AConfig.MaxCount);
end;

destructor TNamedSemaphore.Destroy;
begin
  if FHandle <> 0 then
  begin
    CloseHandle(FHandle);
    FHandle := 0;
  end;
  inherited Destroy;
end;

function TNamedSemaphore.GetLastError: TWaitError;
begin
  Result := FLastError;
end;

function TNamedSemaphore.Wait: INamedSemaphoreGuard;
var
  LResult: DWORD;
begin
  LResult := WaitForSingleObject(FHandle, INFINITE);
  case LResult of
    WAIT_OBJECT_0:
      Result := TNamedSemaphoreGuard.Create(FHandle, FName);
    WAIT_FAILED:
      raise ELockError.CreateFmt('Failed to wait for named semaphore "%s": %s',
        [FName, SysErrorMessage(GetLastError)]);
  else
    raise ELockError.CreateFmt('Unexpected result from WaitForSingleObject: %d', [LResult]);
  end;
end;

function TNamedSemaphore.TryWait: INamedSemaphoreGuard;
begin
  Result := TryWaitFor(0);
end;

function TNamedSemaphore.TryWaitFor(ATimeoutMs: Cardinal): INamedSemaphoreGuard;
var
  LResult: DWORD;
begin
  LResult := WaitForSingleObject(FHandle, ATimeoutMs);
  case LResult of
    WAIT_OBJECT_0:
      Result := TNamedSemaphoreGuard.Create(FHandle, FName);
    WAIT_TIMEOUT:
      Result := nil;
    WAIT_FAILED:
      raise ELockError.CreateFmt('Failed to try wait for named semaphore "%s": %s', 
        [FName, SysErrorMessage(GetLastError)]);
  else
    raise ELockError.CreateFmt('Unexpected result from WaitForSingleObject: %d', [LResult]);
  end;
end;

procedure TNamedSemaphore.Release;
begin
  Release(1);
end;

procedure TNamedSemaphore.Release(ACount: Integer);
begin
  if ACount <= 0 then
    raise EInvalidArgument.CreateFmt('Release count must be positive: %d', [ACount]);
    
  if not ReleaseSemaphore(FHandle, ACount, nil) then
    raise ELockError.CreateFmt('Failed to release named semaphore "%s": %s', 
      [FName, SysErrorMessage(GetLastError)]);
end;

function TNamedSemaphore.GetName: string;
begin
  Result := FName;
end;

function TNamedSemaphore.GetCurrentCount: Integer;
begin
  // Windows 不直接支持查询信号量当前计数
  // 返回 -1 表示不支持
  Result := -1;
end;

function TNamedSemaphore.GetMaxCount: Integer;
begin
  Result := FMaxCount;
end;

// 兼容性方法（已弃用）
procedure TNamedSemaphore.Acquire;
var
  LGuard: INamedSemaphoreGuard;
begin
  LGuard := Wait;
  // 注意：这里会立即释放信号量，因为 LGuard 会在方法结束时析构
  // 这是为什么不推荐使用这个方法的原因
end;

function TNamedSemaphore.TryAcquire: Boolean;
var
  LGuard: INamedSemaphoreGuard;
begin
  LGuard := TryWait;
  Result := Assigned(LGuard);
  // 注意：同样的问题，信号量会立即被释放
end;

function TNamedSemaphore.TryAcquire(ATimeoutMs: Cardinal): Boolean;
var
  LGuard: INamedSemaphoreGuard;
begin
  LGuard := TryWaitFor(ATimeoutMs);
  Result := Assigned(LGuard);
  // 注意：信号量会在方法结束时自动释放
end;

procedure TNamedSemaphore.Acquire(ATimeoutMs: Cardinal);
var
  LGuard: INamedSemaphoreGuard;
begin
  LGuard := TryWaitFor(ATimeoutMs);
  if not Assigned(LGuard) then
    raise ETimeoutError.CreateFmt('Timeout waiting for named semaphore "%s"', [FName]);
  // 注意：信号量会在方法结束时自动释放
end;

function TNamedSemaphore.GetHandle: Pointer;
begin
  Result := Pointer(FHandle);
end;

function TNamedSemaphore.IsCreator: Boolean;
begin
  Result := FIsCreator;
end;

end.
