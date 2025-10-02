unit fafafa.core.sync.namedMutex.windows;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  Windows, SysUtils,
  fafafa.core.base, fafafa.core.sync.base, fafafa.core.sync.namedMutex.base;

type
  // RAII 瀹堝崼锛氬湪鏋愭瀯鏃惰嚜鍔ㄩ噴鏀句簰鏂ラ攣
  TNamedMutexGuard = class(TInterfacedObject, INamedMutexGuard)
  private
    FHandle: THandle;
    FName: string;
    FReleased: Boolean;
  public
    constructor Create(AHandle: THandle; const AName: string);
    destructor Destroy; override;
    function GetName: string;
  end;

  TNamedMutex = class(TSynchronizable, INamedMutex)
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
    
    // ISynchronizable 鎺ュ彛
    function GetLastError: TWaitError;

    // ILock 鎺ュ彛
    procedure Acquire;
    procedure Release;
    function LockGuard: ILockGuard;
    function TryAcquire: Boolean;
    function GetHandle: Pointer;
    
    // INamedMutex 鎺ュ彛锛堢幇浠ｅ寲锛?
    function Lock: INamedMutexGuard;
    function TryLock: INamedMutexGuard;
    function TryLockFor(ATimeoutMs: Cardinal): INamedMutexGuard;
    function GetName: string;
    function IsCreator: Boolean;
    function IsAbandoned: Boolean;
    // 鍏煎鎬ф柟娉?
    function TryAcquire(ATimeoutMs: Cardinal): Boolean; overload;
    procedure Acquire(ATimeoutMs: Cardinal); overload;
  end;

implementation

{ TNamedMutexGuard }

constructor TNamedMutexGuard.Create(AHandle: THandle; const AName: string);
begin
  inherited Create;
  FHandle := AHandle;
  FName := AName;
  FReleased := False;
end;

destructor TNamedMutexGuard.Destroy;
begin
  if (FHandle <> 0) and (not FReleased) then
  begin
    ReleaseMutex(FHandle);
    FReleased := True;
  end;
  inherited Destroy;
end;

function TNamedMutexGuard.GetName: string;
begin
  Result := FName;
end;

{ TNamedMutex }

function TNamedMutex.ValidateName(const AName: string): string;
begin
  if AName = '' then
    raise EInvalidArgument.Create('Named mutex name cannot be empty');
  
  // Windows 鍛藉悕瀵硅薄鍚嶇О瑙勫垯锛?
  // - 涓嶈兘鍖呭惈鍙嶆枩鏉?(\)
  // - 闀垮害闄愬埗涓?MAX_PATH (260) 瀛楃
  // - 鍙互鍖呭惈 Global\ 鎴?Local\ 鍓嶇紑
  Result := AName;
  if Length(Result) > MAX_PATH then
    raise EInvalidArgument.Create('Named mutex name too long (max 260 characters)');
  
  if Pos('\', Result) > 0 then
  begin
    // 鍙厑璁?Global\ 鎴?Local\ 鍓嶇紑
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
  
  // 鍒涘缓鎴栨墦寮€鍛藉悕浜掓枼閿?
  FHandle := CreateMutexW(nil, AInitialOwner, PWideChar(UnicodeString(LName)));
  
  if FHandle = 0 then
    raise ELockError.CreateFmt('Failed to create named mutex "%s": %s', 
      [LName, SysErrorMessage(Windows.GetLastError)]);
  
  LLastError := Windows.GetLastError;
  FIsCreator := (LLastError <> ERROR_ALREADY_EXISTS);
  
  // 妫€鏌ユ槸鍚︿负閬楀純鐘舵€?
  if AInitialOwner and (LLastError = ERROR_ALREADY_EXISTS) then
  begin
    // 灏濊瘯绔嬪嵆鑾峰彇浠ユ鏌ラ仐寮冪姸鎬?
    case WaitForSingleObject(FHandle, 0) of
      WAIT_ABANDONED:
        FIsAbandoned := True;
      WAIT_OBJECT_0:
        ReleaseMutex(FHandle); // 绔嬪嵆閲婃斁锛屽洜涓鸿繖鍙槸妫€鏌?
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
      FIsAbandoned := True; // 鎴愬姛鑾峰彇锛屼絾涔嬪墠鐨勬嫢鏈夎€呭紓甯搁€€鍑?
    WAIT_FAILED:
      raise ELockError.CreateFmt('Failed to acquire named mutex "%s": %s',
        [FName, SysErrorMessage(Windows.GetLastError)]);
  else
    raise ELockError.CreateFmt('Unexpected result from WaitForSingleObject: %d', [LResult]);
  end;
end;

procedure TNamedMutex.Release;
begin
  if not ReleaseMutex(FHandle) then
    raise ELockError.CreateFmt('Failed to release named mutex "%s": %s', 
      [FName, SysErrorMessage(Windows.GetLastError)]);
end;

function TNamedMutex.TryAcquire: Boolean;
begin
  Result := TryAcquire(0);
end;

function TNamedMutex.LockGuard: ILockGuard;
begin
  Result := MakeLockGuard(Self as ILock);
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
      Result := True; // 鎴愬姛鑾峰彇锛屼絾涔嬪墠鐨勬嫢鏈夎€呭紓甯搁€€鍑?
    end;
    WAIT_TIMEOUT:
      Result := False;
    WAIT_FAILED:
      raise ELockError.CreateFmt('Failed to try acquire named mutex "%s": %s', 
        [FName, SysErrorMessage(Windows.GetLastError)]);
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

// 鐜颁唬鍖?INamedMutex 鏂规硶瀹炵幇
function TNamedMutex.Lock: INamedMutexGuard;
var
  LResult: DWORD;
begin
  LResult := WaitForSingleObject(FHandle, INFINITE);
  case LResult of
    WAIT_OBJECT_0:
      begin
        FIsAbandoned := False;
        FLastError := weNone;
        Result := TNamedMutexGuard.Create(FHandle, FName);
      end;
    WAIT_ABANDONED:
      begin
        FIsAbandoned := True;
        FLastError := weNone;
        Result := TNamedMutexGuard.Create(FHandle, FName);
      end;
    WAIT_FAILED:
      begin
        FLastError := weSystemError;
        raise ELockError.CreateFmt('Failed to lock named mutex "%s": %s',
          [FName, SysErrorMessage(Windows.GetLastError)]);
      end;
  else
    FLastError := weSystemError;
    raise ELockError.CreateFmt('Unexpected result from WaitForSingleObject: %d', [LResult]);
  end;
end;

function TNamedMutex.TryLock: INamedMutexGuard;
begin
  Result := TryLockFor(0);
end;

function TNamedMutex.TryLockFor(ATimeoutMs: Cardinal): INamedMutexGuard;
var
  LResult: DWORD;
begin
  LResult := WaitForSingleObject(FHandle, ATimeoutMs);
  case LResult of
    WAIT_OBJECT_0:
      begin
        FIsAbandoned := False;
        FLastError := weNone;
        Result := TNamedMutexGuard.Create(FHandle, FName);
      end;
    WAIT_ABANDONED:
      begin
        FIsAbandoned := True;
        FLastError := weNone;
        Result := TNamedMutexGuard.Create(FHandle, FName);
      end;
    WAIT_TIMEOUT:
      Result := nil;
    WAIT_FAILED:
      begin
        FLastError := weSystemError;
        raise ELockError.CreateFmt('Failed to try-lock named mutex "%s": %s',
          [FName, SysErrorMessage(Windows.GetLastError)]);
      end;
  else
    FLastError := weSystemError;
    raise ELockError.CreateFmt('Unexpected result from WaitForSingleObject: %d', [LResult]);
  end;
end;

end.


