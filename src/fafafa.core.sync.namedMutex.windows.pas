unit fafafa.core.sync.namedMutex.windows;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  Windows, SysUtils,
  fafafa.core.base, fafafa.core.sync.base, fafafa.core.sync.namedMutex.base;

type
  TNamedMutex = class(TInterfacedObject, INamedMutex)
  private
    FHandle: THandle;
    FName: string;
    FIsCreator: Boolean;
    FIsAbandoned: Boolean;
    FLastError: TWaitError;
    
    function ValidateName(const AName: string): string;
  public
    constructor Create(const AName: string); overload;
    constructor Create(const AName: string; AInitialOwner: Boolean); overload;
    destructor Destroy; override;
    
    // ISynchronizable 接口
    function GetLastError: TWaitError;

    // IMutex 接口
    procedure Acquire;
    procedure Release;
    function TryAcquire: Boolean;
    function GetHandle: Pointer;
    
    // INamedMutex 接口
    function GetName: string;
    function IsCreator: Boolean;
    function IsAbandoned: Boolean;
    function TryAcquire(ATimeoutMs: Cardinal): Boolean; overload;
    procedure Acquire(ATimeoutMs: Cardinal); overload;
  end;

implementation

{ TNamedMutex }

function TNamedMutex.ValidateName(const AName: string): string;
begin
  if AName = '' then
    raise EInvalidArgument.Create('Named mutex name cannot be empty');
  
  // Windows 命名对象名称规则：
  // - 不能包含反斜杠 (\)
  // - 长度限制为 MAX_PATH (260) 字符
  // - 可以包含 Global\ 或 Local\ 前缀
  Result := AName;
  if Length(Result) > MAX_PATH then
    raise EInvalidArgument.Create('Named mutex name too long (max 260 characters)');
  
  if Pos('\', Result) > 0 then
  begin
    // 只允许 Global\ 或 Local\ 前缀
    if not ((Pos('Global\', Result) = 1) or (Pos('Local\', Result) = 1)) then
      raise EInvalidArgument.Create('Invalid characters in mutex name');
  end;
end;

constructor TNamedMutex.Create(const AName: string);
begin
  Create(AName, False);
end;

constructor TNamedMutex.Create(const AName: string; AInitialOwner: Boolean);
var
  LName: string;
  LLastError: DWORD;
begin
  inherited Create;
  
  LName := ValidateName(AName);
  FName := LName;
  FIsAbandoned := False;
  FLastError := weNone;
  
  // 创建或打开命名互斥锁
  FHandle := CreateMutexA(nil, AInitialOwner, PAnsiChar(AnsiString(LName)));
  
  if FHandle = 0 then
    raise ELockError.CreateFmt('Failed to create named mutex "%s": %s', 
      [LName, SysErrorMessage(GetLastError)]);
  
  LLastError := GetLastError;
  FIsCreator := (LLastError <> ERROR_ALREADY_EXISTS);
  
  // 检查是否为遗弃状态
  if AInitialOwner and (LLastError = ERROR_ALREADY_EXISTS) then
  begin
    // 尝试立即获取以检查遗弃状态
    case WaitForSingleObject(FHandle, 0) of
      WAIT_ABANDONED:
        FIsAbandoned := True;
      WAIT_OBJECT_0:
        ReleaseMutex(FHandle); // 立即释放，因为这只是检查
    end;
  end;
end;

destructor TNamedMutex.Destroy;
begin
  if FHandle <> 0 then
  begin
    CloseHandle(FHandle);
    FHandle := 0;
  end;
  inherited Destroy;
end;

procedure TNamedMutex.Acquire;
var
  LResult: DWORD;
begin
  LResult := WaitForSingleObject(FHandle, INFINITE);
  case LResult of
    WAIT_OBJECT_0:
      FIsAbandoned := False;
    WAIT_ABANDONED:
      FIsAbandoned := True; // 成功获取，但之前的拥有者异常退出
    WAIT_FAILED:
      raise ELockError.CreateFmt('Failed to acquire named mutex "%s": %s',
        [FName, SysErrorMessage(GetLastError)]);
  else
    raise ELockError.CreateFmt('Unexpected result from WaitForSingleObject: %d', [LResult]);
  end;
end;

procedure TNamedMutex.Release;
begin
  if not ReleaseMutex(FHandle) then
    raise ELockError.CreateFmt('Failed to release named mutex "%s": %s', 
      [FName, SysErrorMessage(GetLastError)]);
end;

function TNamedMutex.TryAcquire: Boolean;
begin
  Result := TryAcquire(0);
end;

function TNamedMutex.TryAcquire(ATimeoutMs: Cardinal): Boolean;
var
  LResult: DWORD;
begin
  LResult := WaitForSingleObject(FHandle, ATimeoutMs);
  case LResult of
    WAIT_OBJECT_0:
    begin
      FIsAbandoned := False;
      Result := True;
    end;
    WAIT_ABANDONED:
    begin
      FIsAbandoned := True;
      Result := True; // 成功获取，但之前的拥有者异常退出
    end;
    WAIT_TIMEOUT:
      Result := False;
    WAIT_FAILED:
      raise ELockError.CreateFmt('Failed to try acquire named mutex "%s": %s', 
        [FName, SysErrorMessage(GetLastError)]);
  else
    raise ELockError.CreateFmt('Unexpected result from WaitForSingleObject: %d', [LResult]);
  end;
end;

function TNamedMutex.GetHandle: Pointer;
begin
  Result := Pointer(FHandle);
end;

function TNamedMutex.GetLastError: TWaitError;
begin
  Result := FLastError;
end;

procedure TNamedMutex.Acquire(ATimeoutMs: Cardinal);
begin
  if not TryAcquire(ATimeoutMs) then
    raise ETimeoutError.CreateFmt('Timeout waiting for named mutex "%s"', [FName]);
end;

function TNamedMutex.GetName: string;
begin
  Result := FName;
end;

function TNamedMutex.IsCreator: Boolean;
begin
  Result := FIsCreator;
end;

function TNamedMutex.IsAbandoned: Boolean;
begin
  Result := FIsAbandoned;
end;

end.
