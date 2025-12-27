unit fafafa.core.sync.namedOnce.windows;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, Windows,
  fafafa.core.sync.base, fafafa.core.sync.namedOnce.base;

type
  TNamedOnce = class(TSynchronizable, INamedOnce)
  private
    FMutex: THandle;
    FEvent: THandle;
    FMapping: THandle;
    FShared: PInt32;
    FOriginalName: string;
    FIsCreator: Boolean;
    FConfig: TNamedOnceConfig;
    FLastError: TWaitError;

    function CreateNames(const AName: string; out AMutexName, AEventName, AMapName: string): Boolean;
  public
    constructor Create(const AName: string); overload;
    constructor Create(const AName: string; const AConfig: TNamedOnceConfig); overload;
    destructor Destroy; override;

    // ISynchronizable
    function GetLastError: TWaitError;

    // INamedOnce
    procedure Execute(ACallback: TOnceCallback);
    procedure ExecuteMethod(ACallback: TOnceCallbackMethod);
    procedure ExecuteForce(ACallback: TOnceCallback);
    function Wait(ATimeoutMs: Cardinal = INFINITE): Boolean;
    function GetState: TNamedOnceState;
    function IsDone: Boolean;
    function IsPoisoned: Boolean;
    function GetName: string;
    procedure Reset;
  end;

function MakeNamedOnce(const AName: string): INamedOnce;
function MakeNamedOnce(const AName: string; const AConfig: TNamedOnceConfig): INamedOnce;

implementation

const
  PREFIX_MUTEX = 'Global\fafafa_once_m_';
  PREFIX_EVENT = 'Global\fafafa_once_e_';
  PREFIX_MAP = 'Global\fafafa_once_s_';

function MakeNamedOnce(const AName: string): INamedOnce;
begin
  Result := TNamedOnce.Create(AName);
end;

function MakeNamedOnce(const AName: string; const AConfig: TNamedOnceConfig): INamedOnce;
begin
  Result := TNamedOnce.Create(AName, AConfig);
end;

{ TNamedOnce }

constructor TNamedOnce.Create(const AName: string);
begin
  Create(AName, DefaultNamedOnceConfig);
end;

constructor TNamedOnce.Create(const AName: string; const AConfig: TNamedOnceConfig);
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
    raise ELockError.CreateFmt('Invalid name for named once: %s', [AName]);

  // 创建或打开互斥锁
  FMutex := CreateMutexW(nil, False, PWideChar(UnicodeString(MutexName)));
  if FMutex = 0 then
    raise ELockError.CreateFmt('Failed to create mutex for named once: %s', [AName]);

  FIsCreator := GetLastError <> ERROR_ALREADY_EXISTS;

  // 创建或打开事件
  FEvent := CreateEventW(nil, True, False, PWideChar(UnicodeString(EventName)));
  if FEvent = 0 then
  begin
    CloseHandle(FMutex);
    raise ELockError.CreateFmt('Failed to create event for named once: %s', [AName]);
  end;

  // 创建或打开共享内存
  FMapping := CreateFileMappingW(INVALID_HANDLE_VALUE, nil, PAGE_READWRITE,
    0, SizeOf(Int32) * 4, PWideChar(UnicodeString(MapName)));
  if FMapping = 0 then
  begin
    CloseHandle(FEvent);
    CloseHandle(FMutex);
    raise ELockError.CreateFmt('Failed to create mapping for named once: %s', [AName]);
  end;

  FShared := MapViewOfFile(FMapping, FILE_MAP_ALL_ACCESS, 0, 0, 0);
  if FShared = nil then
  begin
    CloseHandle(FMapping);
    CloseHandle(FEvent);
    CloseHandle(FMutex);
    raise ELockError.CreateFmt('Failed to map view for named once: %s', [AName]);
  end;

  // 初始化状态（如果是创建者）
  if FIsCreator then
  begin
    FShared^ := Ord(nosNotStarted);
  end;
end;

destructor TNamedOnce.Destroy;
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

function TNamedOnce.CreateNames(const AName: string; out AMutexName, AEventName, AMapName: string): Boolean;
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
    AMutexName := 'Local\fafafa_once_m_' + SafeName;
    AEventName := 'Local\fafafa_once_e_' + SafeName;
    AMapName := 'Local\fafafa_once_s_' + SafeName;
  end;
  Result := True;
end;

function TNamedOnce.GetLastError: TWaitError;
begin
  Result := FLastError;
end;

procedure TNamedOnce.Execute(ACallback: TOnceCallback);
var
  WaitResult: DWORD;
  CurrentState: Int32;
begin
  if FShared = nil then
  begin
    FLastError := weInvalidState;
    Exit;
  end;

  // 快速路径：已完成
  CurrentState := InterlockedCompareExchange(FShared^, 0, 0);
  if CurrentState = Ord(nosCompleted) then
  begin
    FLastError := weNone;
    Exit;
  end;

  if FConfig.EnablePoisoning and (CurrentState = Ord(nosPoisoned)) then
  begin
    FLastError := weInvalidState;
    raise ELockError.Create('Named once is poisoned');
  end;

  // 获取互斥锁
  WaitResult := WaitForSingleObject(FMutex, FConfig.TimeoutMs);
  if WaitResult <> WAIT_OBJECT_0 then
  begin
    FLastError := weTimeout;
    raise ELockError.Create('Timeout waiting for named once mutex');
  end;

  try
    // 再次检查状态
    CurrentState := InterlockedCompareExchange(FShared^, 0, 0);
    if CurrentState = Ord(nosCompleted) then
    begin
      FLastError := weNone;
      Exit;
    end;

    if FConfig.EnablePoisoning and (CurrentState = Ord(nosPoisoned)) then
    begin
      FLastError := weInvalidState;
      raise ELockError.Create('Named once is poisoned');
    end;

    // 尝试成为执行者
    if InterlockedCompareExchange(FShared^, Ord(nosInProgress), Ord(nosNotStarted)) = Ord(nosNotStarted) then
    begin
      try
        ACallback();
        InterlockedExchange(FShared^, Ord(nosCompleted));
        SetEvent(FEvent);
        FLastError := weNone;
      except
        if FConfig.EnablePoisoning then
          InterlockedExchange(FShared^, Ord(nosPoisoned))
        else
          InterlockedExchange(FShared^, Ord(nosNotStarted));
        SetEvent(FEvent);
        FLastError := weInvalidState;
        raise;
      end;
    end;
  finally
    ReleaseMutex(FMutex);
  end;

  // 等待完成
  while InterlockedCompareExchange(FShared^, 0, 0) = Ord(nosInProgress) do
    WaitForSingleObject(FEvent, 100);

  FLastError := weNone;
end;

procedure TNamedOnce.ExecuteMethod(ACallback: TOnceCallbackMethod);
var
  WaitResult: DWORD;
  CurrentState: Int32;
begin
  if FShared = nil then
  begin
    FLastError := weInvalidState;
    Exit;
  end;

  // 快速路径：已完成
  CurrentState := InterlockedCompareExchange(FShared^, 0, 0);
  if CurrentState = Ord(nosCompleted) then
  begin
    FLastError := weNone;
    Exit;
  end;

  if FConfig.EnablePoisoning and (CurrentState = Ord(nosPoisoned)) then
  begin
    FLastError := weInvalidState;
    raise ELockError.Create('Named once is poisoned');
  end;

  WaitResult := WaitForSingleObject(FMutex, FConfig.TimeoutMs);
  if WaitResult <> WAIT_OBJECT_0 then
  begin
    FLastError := weTimeout;
    raise ELockError.Create('Timeout waiting for named once mutex');
  end;

  try
    CurrentState := InterlockedCompareExchange(FShared^, 0, 0);
    if CurrentState = Ord(nosCompleted) then
    begin
      FLastError := weNone;
      Exit;
    end;

    if FConfig.EnablePoisoning and (CurrentState = Ord(nosPoisoned)) then
    begin
      FLastError := weInvalidState;
      raise ELockError.Create('Named once is poisoned');
    end;

    if InterlockedCompareExchange(FShared^, Ord(nosInProgress), Ord(nosNotStarted)) = Ord(nosNotStarted) then
    begin
      try
        ACallback();
        InterlockedExchange(FShared^, Ord(nosCompleted));
        SetEvent(FEvent);
        FLastError := weNone;
      except
        if FConfig.EnablePoisoning then
          InterlockedExchange(FShared^, Ord(nosPoisoned))
        else
          InterlockedExchange(FShared^, Ord(nosNotStarted));
        SetEvent(FEvent);
        FLastError := weInvalidState;
        raise;
      end;
    end;
  finally
    ReleaseMutex(FMutex);
  end;

  // 等待完成
  while InterlockedCompareExchange(FShared^, 0, 0) = Ord(nosInProgress) do
    WaitForSingleObject(FEvent, 100);

  FLastError := weNone;
end;

procedure TNamedOnce.ExecuteForce(ACallback: TOnceCallback);
begin
  if FShared = nil then
  begin
    FLastError := weInvalidState;
    Exit;
  end;

  if not FIsCreator then
  begin
    FLastError := weInvalidState;
    raise ELockError.Create('Only creator can force execute named once');
  end;

  InterlockedExchange(FShared^, Ord(nosNotStarted));
  ResetEvent(FEvent);
  Execute(ACallback);
end;

function TNamedOnce.Wait(ATimeoutMs: Cardinal): Boolean;
var
  StartTime, Elapsed: QWord;
  CurrentState: Int32;
begin
  if FShared = nil then
  begin
    FLastError := weInvalidState;
    Exit(False);
  end;

  StartTime := GetTickCount64;

  while True do
  begin
    CurrentState := InterlockedCompareExchange(FShared^, 0, 0);
    case TNamedOnceState(CurrentState) of
      nosCompleted:
        begin
          FLastError := weNone;
          Exit(True);
        end;
      nosPoisoned:
        begin
          FLastError := weInvalidState;
          Exit(False);
        end;
      nosInProgress, nosNotStarted:
        begin
          Elapsed := GetTickCount64 - StartTime;
          if (ATimeoutMs <> INFINITE) and (Elapsed >= ATimeoutMs) then
          begin
            FLastError := weTimeout;
            Exit(False);
          end;
          WaitForSingleObject(FEvent, 100);
        end;
    end;
  end;
end;

function TNamedOnce.GetState: TNamedOnceState;
begin
  if FShared = nil then
  begin
    FLastError := weInvalidState;
    Result := nosNotStarted;
  end
  else
  begin
    FLastError := weNone;
    Result := TNamedOnceState(InterlockedCompareExchange(FShared^, 0, 0));
  end;
end;

function TNamedOnce.IsDone: Boolean;
begin
  if FShared = nil then
  begin
    FLastError := weInvalidState;
    Result := False;
  end
  else
  begin
    FLastError := weNone;
    Result := InterlockedCompareExchange(FShared^, 0, 0) = Ord(nosCompleted);
  end;
end;

function TNamedOnce.IsPoisoned: Boolean;
begin
  if FShared = nil then
  begin
    FLastError := weInvalidState;
    Result := False;
  end
  else
  begin
    FLastError := weNone;
    Result := InterlockedCompareExchange(FShared^, 0, 0) = Ord(nosPoisoned);
  end;
end;

function TNamedOnce.GetName: string;
begin
  Result := FOriginalName;
end;

procedure TNamedOnce.Reset;
begin
  if FShared = nil then
  begin
    FLastError := weInvalidState;
    raise ELockError.Create('Named once not properly initialized');
  end;

  if not FIsCreator then
  begin
    FLastError := weInvalidState;
    raise ELockError.Create('Only creator can reset named once');
  end;

  InterlockedExchange(FShared^, Ord(nosNotStarted));
  ResetEvent(FEvent);
  FLastError := weNone;
end;

end.
