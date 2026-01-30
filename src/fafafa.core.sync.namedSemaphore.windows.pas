unit fafafa.core.sync.namedSemaphore.windows;

{$mode objfpc}
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
    function IsReleased: Boolean;
    procedure Release;
  end;

  TNamedSemaphore = class(TSynchronizable, INamedSemaphore)
  private
    FHandle: THandle;
    FName: string;
    FIsCreator: Boolean;
    FMaxCount: Integer;
    FLastError: TWaitError;

    // 性能监控字段
    FEnablePerformanceMonitoring: Boolean;
    FWaitCount: Int64;
    FReleaseCount: Int64;
    FTotalWaitTime: Double;

    function ValidateName(const AName: string): string;
    function ValidateCount(AInitialCount, AMaxCount: Integer): Boolean;
  public
    constructor Create(const AName: string; AInitialCount, AMaxCount: Integer); overload;
    constructor Create(const AName: string; const AConfig: TNamedSemaphoreConfig); overload;
    destructor Destroy; override;

    // 类方法：尝试打开现有信号量（不创建新的）
    class function TryOpen(const AName: string): INamedSemaphore; static;
    
    // ISynchronizable 接口
    function GetLastError: TWaitError;

    // INamedSemaphore 接口
    function Wait: INamedSemaphoreGuard;
    function TryWait: INamedSemaphoreGuard;
    function TryWaitFor(ATimeoutMs: Cardinal): INamedSemaphoreGuard;

    // 现代化错误处理方�?
    function WaitSafe: TNamedSemaphoreGuardResult;
    function TryWaitSafe: TNamedSemaphoreGuardResult;
    function TryWaitForSafe(ATimeoutMs: Cardinal): TNamedSemaphoreGuardResult;
    procedure Release; overload;
    procedure Release(ACount: Integer); overload;
    function GetName: string;
    function GetCurrentCount: Integer;
    function GetMaxCount: Integer;

    // 性能监控方法
    function GetWaitCount: Int64;
    function GetReleaseCount: Int64;
    function GetAverageWaitTime: Double;

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
  // 返回 -1 表示不支�?
  Result := -1;
end;

function TNamedSemaphoreGuard.IsReleased: Boolean;
begin
  Result := FReleased;
end;

procedure TNamedSemaphoreGuard.Release;
begin
  if not FReleased and (FSemaphore <> 0) then
  begin
    if ReleaseSemaphore(FSemaphore, 1, nil) then
      FReleased := True
    else
      raise ELockError.CreateFmt('Failed to release semaphore guard "%s": %s',
        [FName, SysErrorMessage(Windows.GetLastError)]);
  end;
end;

{ TNamedSemaphore }

function TNamedSemaphore.ValidateName(const AName: string): string;
begin
  if Length(AName) = 0 then
    raise EInvalidArgument.Create('Semaphore name cannot be empty');
    
  if Length(AName) > 260 then  // MAX_PATH
    raise EInvalidArgument.CreateFmt('Semaphore name too long: %d characters (max 260)', [Length(AName)]);
    
  // 检查无效字符（除了允许的前缀�?
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

  // 初始化性能监控字段
  FEnablePerformanceMonitoring := False; // 默认关闭
  FWaitCount := 0;
  FReleaseCount := 0;
  FTotalWaitTime := 0.0;
  
  // 创建或打开命名信号�?
  FHandle := CreateSemaphoreW(nil, AInitialCount, AMaxCount, PWideChar(UnicodeString(LName)));
  
  if FHandle = 0 then
    raise ELockError.CreateFmt('Failed to create named semaphore "%s": %s', 
      [LName, SysErrorMessage(Windows.GetLastError)]);
      
  // 检查是否为创建�?
  LLastError := Windows.GetLastError;
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

  // 设置性能监控选项
  FEnablePerformanceMonitoring := AConfig.EnablePerformanceMonitoring;
end;

class function TNamedSemaphore.TryOpen(const AName: string): INamedSemaphore;
var
  LName: string;
  LHandle: THandle;
  LInstance: TNamedSemaphore;
begin
  Result := nil;

  // 验证名称 - 应该抛出异常而不是静默退出
  if Length(AName) = 0 then
    raise EInvalidArgument.Create('Semaphore name cannot be empty');

  try
    LName := AName;
    if Length(LName) > 260 then  // MAX_PATH
      raise EInvalidArgument.CreateFmt('Semaphore name too long: %d characters (max 260)', [Length(LName)]);

    // 尝试打开现有信号量（不创建新的）
    LHandle := OpenSemaphoreW(SEMAPHORE_ALL_ACCESS, False, PWideChar(UnicodeString(LName)));

    if LHandle = 0 then
      Exit; // 信号量不存在或无法打开，返回 nil 是正确的语义

    // 创建包装实例
    LInstance := TNamedSemaphore.Create;
    LInstance.FHandle := LHandle;
    LInstance.FName := LName;
    LInstance.FIsCreator := False;
    LInstance.FMaxCount := -1; // 无法确定最大计数
    LInstance.FLastError := weNone;

    Result := LInstance;
  except
    on E: EInvalidArgument do
      raise; // 参数错误直接向上传播
    on E: Exception do
      // 其他异常（如系统错误）暂时按旧习惯可能返回 nil，
      // 但理想情况也应传播。这里先只放行 EInvalidArgument。
      Result := nil;
  end;
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
  LStartTime, LEndTime: TDateTime;
begin
  // 检查句柄有效�?
  if FHandle = 0 then
    raise ELockError.CreateFmt('Named semaphore "%s" handle is invalid', [FName]);

  // 性能监控：记录开始时�?
  if FEnablePerformanceMonitoring then
    LStartTime := Now;

  LResult := WaitForSingleObject(FHandle, INFINITE);

  // 性能监控：记录结束时间和统计
  if FEnablePerformanceMonitoring then
  begin
    LEndTime := Now;
    Inc(FWaitCount);
    FTotalWaitTime := FTotalWaitTime + ((LEndTime - LStartTime) * 24 * 60 * 60 * 1000); // 转换为毫�?
  end;

  case LResult of
    WAIT_OBJECT_0:
      Result := TNamedSemaphoreGuard.Create(FHandle, FName);
    WAIT_FAILED:
      raise ELockError.CreateFmt('Failed to wait for named semaphore "%s": %s',
        [FName, SysErrorMessage(Windows.GetLastError)]);
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
  // 检查句柄有效�?
  if FHandle = 0 then
    raise ELockError.CreateFmt('Named semaphore "%s" handle is invalid', [FName]);

  LResult := WaitForSingleObject(FHandle, ATimeoutMs);
  case LResult of
    WAIT_OBJECT_0:
      Result := TNamedSemaphoreGuard.Create(FHandle, FName);
    WAIT_TIMEOUT:
      Result := nil;
    WAIT_FAILED:
      raise ELockError.CreateFmt('Failed to try wait for named semaphore "%s": %s',
        [FName, SysErrorMessage(Windows.GetLastError)]);
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

  // 检查句柄有效�?
  if FHandle = 0 then
    raise ELockError.CreateFmt('Named semaphore "%s" handle is invalid', [FName]);

  if not ReleaseSemaphore(FHandle, ACount, nil) then
    raise ELockError.CreateFmt('Failed to release named semaphore "%s": %s',
      [FName, SysErrorMessage(Windows.GetLastError)]);

  // 性能监控：记录释放次�?
  if FEnablePerformanceMonitoring then
    Inc(FReleaseCount, ACount);
end;

function TNamedSemaphore.GetName: string;
begin
  Result := FName;
end;

function TNamedSemaphore.GetCurrentCount: Integer;
var
  LResult: DWORD;
  LCount: Integer;
  LPreviousCount: LONG;
  I: Integer;
begin
  // 检查句柄有效�?
  if FHandle = 0 then
    Exit(-1);

  // Windows 不直接支持查询信号量当前计数
  // 使用技巧：尝试非阻塞等待来探测可用计数
  LCount := 0;

  // 连续尝试非阻塞等待，直到失败
  while True do
  begin
    LResult := WaitForSingleObject(FHandle, 0);
    if LResult = WAIT_OBJECT_0 then
      Inc(LCount)
    else
      Break;
  end;

  // 恢复所有获取的计数
  if LCount > 0 then
  begin
    if not ReleaseSemaphore(FHandle, LCount, @LPreviousCount) then
    begin
      // 如果恢复失败，尝试逐个恢复
      for I := 1 to LCount do
        ReleaseSemaphore(FHandle, 1, nil);
    end;
  end;

  Result := LCount;
end;

function TNamedSemaphore.GetMaxCount: Integer;
begin
  Result := FMaxCount;
end;
end;

// 性能监控方法实现
function TNamedSemaphore.GetWaitCount: Int64;
begin
  Result := FWaitCount;
end;

function TNamedSemaphore.GetReleaseCount: Int64;
begin
  Result := FReleaseCount;
end;

function TNamedSemaphore.GetAverageWaitTime: Double;
begin
  if FWaitCount > 0 then
    Result := FTotalWaitTime / FWaitCount
  else
    Result := 0.0;
end;

// 现代化错误处理方法实�?
function TNamedSemaphore.WaitSafe: TNamedSemaphoreGuardResult;
var
  LResult: DWORD;
  LStartTime, LEndTime: TDateTime;
begin
  try
    // 检查句柄有效�?
    if FHandle = 0 then
      Exit(TNamedSemaphoreGuardResult.Failure(
        TNamedSemaphoreError.SystemError('Named semaphore handle is invalid', 0)));

    // 性能监控：记录开始时�?
    if FEnablePerformanceMonitoring then
      LStartTime := Now;

    LResult := WaitForSingleObject(FHandle, INFINITE);

    // 性能监控：记录结束时间和统计
    if FEnablePerformanceMonitoring then
    begin
      LEndTime := Now;
      Inc(FWaitCount);
      FTotalWaitTime := FTotalWaitTime + ((LEndTime - LStartTime) * 24 * 60 * 60 * 1000);
    end;

    case LResult of
      WAIT_OBJECT_0:
        Result := TNamedSemaphoreGuardResult.Success(TNamedSemaphoreGuard.Create(FHandle, FName));
      WAIT_FAILED:
        Result := TNamedSemaphoreGuardResult.Failure(
          TNamedSemaphoreError.SystemError('Failed to wait for named semaphore', Windows.GetLastError));
    else
      Result := TNamedSemaphoreGuardResult.Failure(
        TNamedSemaphoreError.Unknown(Format('Unexpected result from WaitForSingleObject: %d', [LResult])));
    end;
  except
    on E: Exception do
      Result := TNamedSemaphoreGuardResult.Failure(
        TNamedSemaphoreError.Unknown('Exception in WaitSafe: ' + E.Message));
  end;
end;

function TNamedSemaphore.TryWaitSafe: TNamedSemaphoreGuardResult;
begin
  Result := TryWaitForSafe(0);
end;

function TNamedSemaphore.TryWaitForSafe(ATimeoutMs: Cardinal): TNamedSemaphoreGuardResult;
var
  LResult: DWORD;
begin
  try
    // 检查句柄有效�?
    if FHandle = 0 then
      Exit(TNamedSemaphoreGuardResult.Failure(
        TNamedSemaphoreError.SystemError('Named semaphore handle is invalid', 0)));

    LResult := WaitForSingleObject(FHandle, ATimeoutMs);
    case LResult of
      WAIT_OBJECT_0:
        Result := TNamedSemaphoreGuardResult.Success(TNamedSemaphoreGuard.Create(FHandle, FName));
      WAIT_TIMEOUT:
        Result := TNamedSemaphoreGuardResult.Failure(
          TNamedSemaphoreError.Timeout(Format('Timeout waiting for semaphore after %d ms', [ATimeoutMs])));
      WAIT_FAILED:
        Result := TNamedSemaphoreGuardResult.Failure(
          TNamedSemaphoreError.SystemError('Failed to try wait for named semaphore', Windows.GetLastError));
    else
      Result := TNamedSemaphoreGuardResult.Failure(
        TNamedSemaphoreError.Unknown(Format('Unexpected result from WaitForSingleObject: %d', [LResult])));
    end;
  except
    on E: Exception do
      Result := TNamedSemaphoreGuardResult.Failure(
        TNamedSemaphoreError.Unknown('Exception in TryWaitForSafe: ' + E.Message));
  end;
end;

end.
