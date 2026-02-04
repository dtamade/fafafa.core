unit fafafa.core.sync.namedOnce.unix;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, BaseUnix, Unix, UnixType,
  fafafa.core.sync.base, fafafa.core.sync.namedOnce.base;

type
  // 共享内存结构
  PNamedOnceShared = ^TNamedOnceShared;
  TNamedOnceShared = record
    State: Int32;           // TNamedOnceState
    ExecutorPid: Int32;     // 执行者进程 ID
    Version: Int32;         // 版本号（用于 Reset）
    Padding: Int32;         // 对齐填充
  end;

  TNamedOnce = class(TSynchronizable, INamedOnce)
  private
    FShared: PNamedOnceShared;
    FShmHeader: Pointer;  // PNamedShmHeader
    FShmFd: cint;
    FShmPath: AnsiString;
    FOriginalName: string;
    FIsCreator: Boolean;
    FConfig: TNamedOnceConfig;
    FLastError: TWaitError;

    function InitializeShm: Boolean;
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
    function Wait(ATimeoutMs: Cardinal = High(Cardinal)): Boolean;
    function GetState: TNamedOnceState;
    function IsDone: Boolean;
    function IsPoisoned: Boolean;
    function GetName: string;
    procedure Reset;
  end;

function MakeNamedOnce(const AName: string): INamedOnce;
function MakeNamedOnce(const AName: string; const AConfig: TNamedOnceConfig): INamedOnce;

implementation

uses
  fafafa.core.atomic, fafafa.core.sync.namedShm.unix;

const
  SHM_PREFIX = '/fafafa_once_';
  // 进程存活检查间隔（毫秒）
  PROCESS_CHECK_INTERVAL_MS = 500;

// ★ 检测进程是否存活
// 使用 kill(pid, 0) - 不发送信号，只检查进程是否存在
function IsProcessAlive(APid: Int32): Boolean;
begin
  if APid <= 0 then
    Exit(False);
  // kill 返回 0 表示进程存在；返回 -1 且 errno=ESRCH 表示进程不存在
  Result := (FpKill(APid, 0) = 0) or (fpGetErrno <> ESysESRCH);
end;

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
    raise ELockError.CreateFmt('Invalid name for named once: %s', [AName]);
  end;

  FShmPath := CreateSafeShmPath(SHM_PREFIX, AName);

  if not InitializeShm then
  begin
    FLastError := weSystemError;
    raise ELockError.CreateFmt('Failed to create named once: %s', [AName]);
  end;
end;

destructor TNamedOnce.Destroy;
var
  IsLastRef: Boolean;
  Header: PNamedShmHeader;
begin
  IsLastRef := False;
  Header := PNamedShmHeader(FShmHeader);

  if Header <> nil then
    IsLastRef := ShmRelease(Header);

  UnmapAndCloseShm(Header, SizeOf(TNamedOnceShared),
    FShmFd, FShmPath, IsLastRef);

  FShmHeader := nil;
  FShared := nil;
  FShmFd := -1;

  inherited Destroy;
end;

function TNamedOnce.InitializeShm: Boolean;
var
  Header: PNamedShmHeader;
begin
  Result := False;

  FShmFd := OpenOrCreateShm(FShmPath, SizeOf(TNamedOnceShared),
    FIsCreator, DEFAULT_INIT_TIMEOUT_MS);

  if FShmFd < 0 then
    Exit;

  FShared := MapShm(FShmFd, SizeOf(TNamedOnceShared), Header);
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
    // 这样即使后续初始化过程崩溃也能被其他进程检测到
    ShmInitCreatorHeader(Header);
    Header^.RefCount := 1;
    Header^.DataSize := SizeOf(TNamedOnceShared);
    FShared^.State := Ord(nosNotStarted);
    FShared^.ExecutorPid := 0;
    FShared^.Version := 0;
    ShmMarkInitialized(Header);
  end
  else
  begin
    if not ShmWaitInitialized(Header, DEFAULT_INIT_TIMEOUT_MS) then
    begin
      Fpmunmap(Header, SizeOf(TNamedShmHeader) + SizeOf(TNamedOnceShared));
      FpClose(FShmFd);
      FShmHeader := nil;
      FShared := nil;
      FShmFd := -1;
      Exit;
    end;
    // ★ 检查 ShmAddRef 是否成功
    // 如果失败，说明共享内存正在被清理，需要放弃
    if not ShmAddRef(Header) then
    begin
      Fpmunmap(Header, SizeOf(TNamedShmHeader) + SizeOf(TNamedOnceShared));
      FpClose(FShmFd);
      FShmHeader := nil;
      FShared := nil;
      FShmFd := -1;
      Exit;
    end;
  end;

  Result := True;
end;

function TNamedOnce.GetLastError: TWaitError;
begin
  Result := FLastError;
end;

procedure TNamedOnce.Execute(ACallback: TOnceCallback);
var
  Expected: Int32;
  CurrentPid: Int32;
  CurrentState: TNamedOnceState;
begin
  if FShared = nil then
  begin
    FLastError := weInvalidState;
    Exit;
  end;

  CurrentPid := FpGetpid;

  // 快速路径：已完成
  if atomic_load(FShared^.State) = Ord(nosCompleted) then
  begin
    FLastError := weNone;
    Exit;
  end;

  // 检查中毒状态
  if FConfig.EnablePoisoning and (atomic_load(FShared^.State) = Ord(nosPoisoned)) then
  begin
    FLastError := weInvalidState;
    raise ELockError.Create('Named once is poisoned');
  end;

  // 尝试成为执行者
  Expected := Ord(nosNotStarted);
  if atomic_compare_exchange_strong(FShared^.State, Expected, Ord(nosInProgress)) then
  begin
    // 成功成为执行者
    atomic_store(FShared^.ExecutorPid, CurrentPid);
    try
      ACallback();
      // 标记完成
      atomic_store(FShared^.State, Ord(nosCompleted));
      FLastError := weNone;
    except
      // 异常时标记中毒
      if FConfig.EnablePoisoning then
        atomic_store(FShared^.State, Ord(nosPoisoned))
      else
        atomic_store(FShared^.State, Ord(nosNotStarted));
      FutexWakeAll(@FShared^.State);
      FLastError := weInvalidState;
      raise;
    end;
    FutexWakeAll(@FShared^.State);
  end
  else
  begin
    // 其他进程正在执行，等待完成
    while True do
    begin
      CurrentState := TNamedOnceState(atomic_load(FShared^.State));
      case CurrentState of
        nosCompleted:
          begin
            FLastError := weNone;
            Exit;
          end;
        nosPoisoned:
          begin
            if FConfig.EnablePoisoning then
            begin
              FLastError := weInvalidState;
              raise ELockError.Create('Named once is poisoned');
            end
            else
            begin
              FLastError := weNone;
              Exit;
            end;
          end;
        nosInProgress:
          begin
            // ★ 关键修复：检测执行者进程是否存活
            // 如果执行者进程已崩溃，尝试接管执行
            if not IsProcessAlive(atomic_load(FShared^.ExecutorPid)) then
            begin
              // 执行者已死，尝试将状态重置为 NotStarted
              Expected := Ord(nosInProgress);
              if atomic_compare_exchange_strong(FShared^.State, Expected, Ord(nosNotStarted)) then
              begin
                // 成功重置状态，唤醒所有等待者让他们重新竞争
                FutexWakeAll(@FShared^.State);
              end;
              // 继续循环，尝试成为新的执行者
              Continue;
            end;
            FutexWait(@FShared^.State, Ord(nosInProgress), PROCESS_CHECK_INTERVAL_MS);
          end;
        nosNotStarted:
          begin
            // 执行者失败后重置，重新尝试
            Expected := Ord(nosNotStarted);
            if atomic_compare_exchange_strong(FShared^.State, Expected, Ord(nosInProgress)) then
            begin
              atomic_store(FShared^.ExecutorPid, CurrentPid);
              try
                ACallback();
                atomic_store(FShared^.State, Ord(nosCompleted));
                FLastError := weNone;
              except
                if FConfig.EnablePoisoning then
                  atomic_store(FShared^.State, Ord(nosPoisoned))
                else
                  atomic_store(FShared^.State, Ord(nosNotStarted));
                FutexWakeAll(@FShared^.State);
                FLastError := weInvalidState;
                raise;
              end;
              FutexWakeAll(@FShared^.State);
              Exit;
            end;
          end;
      end;
    end;
  end;
end;

procedure TNamedOnce.ExecuteMethod(ACallback: TOnceCallbackMethod);
var
  Expected: Int32;
  CurrentPid: Int32;
  CurrentState: TNamedOnceState;
begin
  if FShared = nil then
  begin
    FLastError := weInvalidState;
    Exit;
  end;

  CurrentPid := FpGetpid;

  // 快速路径：已完成
  if atomic_load(FShared^.State) = Ord(nosCompleted) then
  begin
    FLastError := weNone;
    Exit;
  end;

  // 检查中毒状态
  if FConfig.EnablePoisoning and (atomic_load(FShared^.State) = Ord(nosPoisoned)) then
  begin
    FLastError := weInvalidState;
    raise ELockError.Create('Named once is poisoned');
  end;

  // 尝试成为执行者
  Expected := Ord(nosNotStarted);
  if atomic_compare_exchange_strong(FShared^.State, Expected, Ord(nosInProgress)) then
  begin
    atomic_store(FShared^.ExecutorPid, CurrentPid);
    try
      ACallback();
      atomic_store(FShared^.State, Ord(nosCompleted));
      FLastError := weNone;
    except
      if FConfig.EnablePoisoning then
        atomic_store(FShared^.State, Ord(nosPoisoned))
      else
        atomic_store(FShared^.State, Ord(nosNotStarted));
      FutexWakeAll(@FShared^.State);
      FLastError := weInvalidState;
      raise;
    end;
    FutexWakeAll(@FShared^.State);
  end
  else
  begin
    // 等待完成（完整的重试逻辑，与 Execute 保持一致）
    while True do
    begin
      CurrentState := TNamedOnceState(atomic_load(FShared^.State));
      case CurrentState of
        nosCompleted:
          begin
            FLastError := weNone;
            Exit;
          end;
        nosPoisoned:
          begin
            if FConfig.EnablePoisoning then
            begin
              FLastError := weInvalidState;
              raise ELockError.Create('Named once is poisoned');
            end
            else
            begin
              FLastError := weNone;
              Exit;
            end;
          end;
        nosInProgress:
          begin
            // ★ 关键修复：检测执行者进程是否存活
            if not IsProcessAlive(atomic_load(FShared^.ExecutorPid)) then
            begin
              // 执行者已死，尝试将状态重置为 NotStarted
              Expected := Ord(nosInProgress);
              if atomic_compare_exchange_strong(FShared^.State, Expected, Ord(nosNotStarted)) then
                FutexWakeAll(@FShared^.State);
              Continue;
            end;
            FutexWait(@FShared^.State, Ord(nosInProgress), PROCESS_CHECK_INTERVAL_MS);
          end;
        nosNotStarted:
          begin
            // 执行者失败后重置，重新尝试
            Expected := Ord(nosNotStarted);
            if atomic_compare_exchange_strong(FShared^.State, Expected, Ord(nosInProgress)) then
            begin
              atomic_store(FShared^.ExecutorPid, CurrentPid);
              try
                ACallback();
                atomic_store(FShared^.State, Ord(nosCompleted));
                FLastError := weNone;
              except
                if FConfig.EnablePoisoning then
                  atomic_store(FShared^.State, Ord(nosPoisoned))
                else
                  atomic_store(FShared^.State, Ord(nosNotStarted));
                FutexWakeAll(@FShared^.State);
                FLastError := weInvalidState;
                raise;
              end;
              FutexWakeAll(@FShared^.State);
              Exit;
            end;
          end;
      end;
    end;
  end;
end;

procedure TNamedOnce.ExecuteForce(ACallback: TOnceCallback);
var
  OldVersion: Int32;
begin
  if FShared = nil then
  begin
    FLastError := weInvalidState;
    Exit;
  end;

  // 只有创建者可以强制执行
  if not FIsCreator then
  begin
    FLastError := weInvalidState;
    raise ELockError.Create('Only creator can force execute named once');
  end;

  // 原子地重置状态和增加版本号
  OldVersion := atomic_fetch_add(FShared^.Version, 1);
  atomic_store(FShared^.State, Ord(nosNotStarted));
  atomic_store(FShared^.ExecutorPid, 0);

  // 执行
  Execute(ACallback);
end;

function TNamedOnce.Wait(ATimeoutMs: Cardinal): Boolean;
var
  StartTime, Elapsed: QWord;
  CurrentState: TNamedOnceState;
begin
  Result := False;  // 默认值，实际上所有路径都通过 Exit() 返回
  if FShared = nil then
  begin
    FLastError := weInvalidState;
    Exit(False);
  end;

  StartTime := GetTickCount64;

  while True do
  begin
    CurrentState := TNamedOnceState(atomic_load(FShared^.State));
    case CurrentState of
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
      nosInProgress:
        begin
          // ★ 关键修复：检测执行者进程是否存活
          if not IsProcessAlive(atomic_load(FShared^.ExecutorPid)) then
          begin
            // 执行者已死，但 Wait 不负责重新执行，只记录状态
            // 等待其他进程接管或超时
            FLastError := weInvalidState;
            Exit(False);
          end;

          Elapsed := GetTickCount64 - StartTime;
          if (ATimeoutMs <> High(Cardinal)) and (Elapsed >= ATimeoutMs) then
          begin
            FLastError := weTimeout;
            Exit(False);
          end;
          FutexWait(@FShared^.State, Ord(nosInProgress), PROCESS_CHECK_INTERVAL_MS);
        end;
      nosNotStarted:
        begin
          Elapsed := GetTickCount64 - StartTime;
          if (ATimeoutMs <> High(Cardinal)) and (Elapsed >= ATimeoutMs) then
          begin
            FLastError := weTimeout;
            Exit(False);
          end;
          FutexWait(@FShared^.State, Ord(nosNotStarted), 100);
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
    Result := TNamedOnceState(atomic_load(FShared^.State));
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
    Result := atomic_load(FShared^.State) = Ord(nosCompleted);
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
    Result := atomic_load(FShared^.State) = Ord(nosPoisoned);
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
    Exit;
  end;

  // 只有创建者可以重置
  if not FIsCreator then
  begin
    FLastError := weInvalidState;
    raise ELockError.Create('Only creator can reset named once');
  end;

  // 原子地重置所有状态
  atomic_fetch_add(FShared^.Version, 1);
  atomic_store(FShared^.State, Ord(nosNotStarted));
  atomic_store(FShared^.ExecutorPid, 0);
  FutexWakeAll(@FShared^.State);

  FLastError := weNone;
end;

end.
