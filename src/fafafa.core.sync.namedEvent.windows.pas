unit fafafa.core.sync.namedEvent.windows;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  Windows, SysUtils,
  fafafa.core.base, fafafa.core.sync.base, fafafa.core.sync.namedEvent.base;

type
  // RAII 守卫实现
  TNamedEventGuard = class(TInterfacedObject, INamedEventGuard)
  private
    FName: string;
    FSignaled: Boolean;
  public
    constructor Create(const AName: string; ASignaled: Boolean);
    function GetName: string;
    function IsSignaled: Boolean;
  end;

  TNamedEvent = class(TInterfacedObject, INamedEvent)
  private
    FHandle: THandle;
    FName: string;
    FIsCreator: Boolean;
    FManualReset: Boolean;
    FLastError: TWaitError;
    
    function ValidateName(const AName: string): string;
  public
    constructor Create(const AName: string); overload;
    constructor Create(const AName: string; const AConfig: TNamedEventConfig); overload;
    destructor Destroy; override;
    
    // ISynchronizable 接口
    function GetLastError: TWaitError;

    // INamedEvent 接口 - 现代化方法
    function Wait: INamedEventGuard;
    function TryWait: INamedEventGuard;
    function TryWaitFor(ATimeoutMs: Cardinal): INamedEventGuard;

    procedure Signal;
    procedure Reset;
    procedure Pulse;

    function GetName: string;
    function IsManualReset: Boolean;
    function IsSignaled: Boolean;
  end;

implementation

{ TNamedEventGuard }

constructor TNamedEventGuard.Create(const AName: string; ASignaled: Boolean);
begin
  inherited Create;
  FName := AName;
  FSignaled := ASignaled;
end;

function TNamedEventGuard.GetName: string;
begin
  Result := FName;
end;

function TNamedEventGuard.IsSignaled: Boolean;
begin
  Result := FSignaled;
end;

{ TNamedEvent }

constructor TNamedEvent.Create(const AName: string);
var
  LConfig: TNamedEventConfig;
begin
  LConfig := DefaultNamedEventConfig;
  Create(AName, LConfig);
end;

constructor TNamedEvent.Create(const AName: string; const AConfig: TNamedEventConfig);
var
  LValidatedName: string;
  LSecurityAttributes: PSecurityAttributes;
begin
  inherited Create;
  FLastError := weNone;
  FManualReset := AConfig.ManualReset;
  
  LValidatedName := ValidateName(AName);
  FName := LValidatedName;
  
  // 创建安全属性（允许跨进程访问）
  LSecurityAttributes := nil;
  
  // 创建命名事件
  FHandle := CreateEventW(
    LSecurityAttributes,
    FManualReset,           // bManualReset
    AConfig.InitialState,   // bInitialState
    PWideChar(UnicodeString(LValidatedName))
  );
  
  if FHandle = 0 then
  begin
    FLastError := weSystemError;
    raise ELockError.CreateFmt('Failed to create named event "%s": %s',
      [AName, SysErrorMessage(GetLastError)]);
  end;
  
  // 检查是否为创建者
  FIsCreator := GetLastError <> ERROR_ALREADY_EXISTS;
end;

destructor TNamedEvent.Destroy;
begin
  if FHandle <> 0 then
    CloseHandle(FHandle);
  inherited Destroy;
end;

function TNamedEvent.ValidateName(const AName: string): string;
begin
  if AName = '' then
    raise EInvalidArgument.Create('Named event name cannot be empty');
    
  if Length(AName) > 260 then
    raise EInvalidArgument.CreateFmt('Named event name too long: %d characters (max 260)', [Length(AName)]);
    
  // Windows 命名事件不能包含反斜杠（除了 Global\ 或 Local\ 前缀）
  if (Pos('\', AName) > 0) and 
     (Pos('Global\', AName) <> 1) and 
     (Pos('Local\', AName) <> 1) then
    raise EInvalidArgument.CreateFmt('Invalid character in named event name: "%s"', [AName]);
    
  Result := AName;
end;

function TNamedEvent.GetLastError: TWaitError;
begin
  Result := FLastError;
end;

function TNamedEvent.Wait: INamedEventGuard;
var
  LResult: DWORD;
begin
  LResult := WaitForSingleObject(FHandle, INFINITE);
  case LResult of
    WAIT_OBJECT_0:
      Result := TNamedEventGuard.Create(FName, True);
    WAIT_FAILED:
      begin
        FLastError := weSystemError;
        raise ELockError.CreateFmt('Failed to wait for named event "%s": %s',
          [FName, SysErrorMessage(GetLastError)]);
      end;
  else
    FLastError := weSystemError;
    raise ELockError.CreateFmt('Unexpected result from WaitForSingleObject: %d', [LResult]);
  end;
end;

function TNamedEvent.TryWait: INamedEventGuard;
begin
  Result := TryWaitFor(0);
end;

function TNamedEvent.TryWaitFor(ATimeoutMs: Cardinal): INamedEventGuard;
var
  LResult: DWORD;
begin
  LResult := WaitForSingleObject(FHandle, ATimeoutMs);
  case LResult of
    WAIT_OBJECT_0:
      Result := TNamedEventGuard.Create(FName, True);
    WAIT_TIMEOUT:
      Result := nil;
    WAIT_FAILED:
      begin
        FLastError := weSystemError;
        raise ELockError.CreateFmt('Failed to wait for named event "%s": %s',
          [FName, SysErrorMessage(GetLastError)]);
      end;
  else
    FLastError := weSystemError;
    raise ELockError.CreateFmt('Unexpected result from WaitForSingleObject: %d', [LResult]);
  end;
end;

procedure TNamedEvent.Signal;
begin
  if not Windows.SetEvent(FHandle) then
  begin
    FLastError := weSystemError;
    raise ELockError.CreateFmt('Failed to signal named event "%s": %s',
      [FName, SysErrorMessage(GetLastError)]);
  end;
end;

procedure TNamedEvent.Reset;
begin
  if not Windows.ResetEvent(FHandle) then
  begin
    FLastError := weSystemError;
    raise ELockError.CreateFmt('Failed to reset named event "%s": %s',
      [FName, SysErrorMessage(GetLastError)]);
  end;
end;

procedure TNamedEvent.Pulse;
begin
  // PulseEvent 已被 Microsoft 弃用，因为它有可靠性问题
  // 我们使用 SetEvent + ResetEvent 的组合来模拟脉冲行为
  // 注意：这不是原子操作，但比 PulseEvent 更可靠

  if not Windows.SetEvent(FHandle) then
  begin
    FLastError := weSystemError;
    raise ELockError.CreateFmt('Failed to set named event "%s" during pulse: %s',
      [FName, SysErrorMessage(GetLastError)]);
  end;

  // 对于自动重置事件，SetEvent 后会自动重置，无需手动重置
  // 对于手动重置事件，我们需要立即重置
  if FManualReset then
  begin
    // 给等待的线程一个很短的时间窗口来响应信号
    Sleep(0); // 让出时间片

    if not Windows.ResetEvent(FHandle) then
    begin
      FLastError := weSystemError;
      raise ELockError.CreateFmt('Failed to reset named event "%s" during pulse: %s',
        [FName, SysErrorMessage(GetLastError)]);
    end;
  end;
end;

function TNamedEvent.GetName: string;
begin
  Result := FName;
end;

function TNamedEvent.IsManualReset: Boolean;
begin
  Result := FManualReset;
end;

function TNamedEvent.IsSignaled: Boolean;
var
  LResult: DWORD;
begin
  if FManualReset then
  begin
    // 手动重置事件：使用非阻塞检查
    // 注意：这仍然是破坏性的，但这是 Windows Event 的固有限制
    LResult := WaitForSingleObject(FHandle, 0);
    case LResult of
      WAIT_OBJECT_0:
        begin
          Result := True;
          // 立即重新设置事件状态，减少竞态窗口
          Windows.SetEvent(FHandle);
        end;
      WAIT_TIMEOUT:
        Result := False;
      WAIT_FAILED:
        begin
          FLastError := weSystemError;
          Result := False;
        end;
    else
      Result := False;
    end;
  end
  else
  begin
    // 自动重置事件：与 Windows 标准行为一致，总是返回 False
    // 这避免了破坏性检查，符合 Windows Event 的标准语义
    Result := False;
  end;
end;



end.
