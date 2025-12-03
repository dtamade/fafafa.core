unit fafafa.core.sync.namedSemaphore.unix;

{$mode objfpc}
{$I fafafa.core.settings.inc}
{$LINKLIB pthread}

interface

uses
  SysUtils, ctypes, BaseUnix, Unix, UnixType,
  fafafa.core.base, fafafa.core.sync.base, fafafa.core.sync.namedSemaphore.base;

type
  // POSIX 信号量类�?
  PSem = Pointer;

  // RAII 守卫实现
  TNamedSemaphoreGuard = class(TInterfacedObject, INamedSemaphoreGuard)
  private
    FSemaphore: PSem;
    FName: string;
    FReleased: Boolean;
  public
    constructor Create(ASemaphore: PSem; const AName: string);
    destructor Destroy; override;
    function GetName: string;
    function GetCount: Integer;
    function IsReleased: Boolean;
    procedure Release;
  end;

  TNamedSemaphore = class(TSynchronizable, INamedSemaphore)
  private
    FSemaphore: PSem;           // POSIX 信号量句�?
    FSemName: AnsiString;       // POSIX 信号量名称（使用 AnsiString 减少转换开销�?
    FOriginalName: string;      // 保存用户提供的原始名�?
    FIsCreator: Boolean;        // 是否为创建�?
    FMaxCount: Integer;         // 最大计数�?

    // 性能监控字段
    FEnablePerformanceMonitoring: Boolean;
    FWaitCount: Int64;
    FReleaseCount: Int64;
    FTotalWaitTime: Double;

    function ValidateName(const AName: string): string;
    function CreateSemName(const AName: string): string;
    function ValidateCount(AInitialCount, AMaxCount: Integer): Boolean;
    function TimeoutToTimespec(ATimeoutMs: Cardinal): TTimeSpec;
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

    // 兼容性方法（已弃用）
    procedure Acquire; deprecated;
    function TryAcquire: Boolean; deprecated;
    function TryAcquire(ATimeoutMs: Cardinal): Boolean; overload; deprecated;
    procedure Acquire(ATimeoutMs: Cardinal); overload; deprecated;
    function GetHandle: Pointer; deprecated;
    function IsCreator: Boolean; deprecated;
  end;

// POSIX 信号量函数声�?
function sem_open(name: PAnsiChar; oflag: cint): PSem; cdecl; varargs; external 'c';
function sem_close(sem: PSem): cint; cdecl; external 'c';
function sem_unlink(name: PAnsiChar): cint; cdecl; external 'c';
function sem_wait(sem: PSem): cint; cdecl; external 'c';
function sem_trywait(sem: PSem): cint; cdecl; external 'c';
function sem_timedwait(sem: PSem; abs_timeout: PTimeSpec): cint; cdecl; external 'c';
function sem_post(sem: PSem): cint; cdecl; external 'c';
function sem_getvalue(sem: PSem; sval: pcint): cint; cdecl; external 'c';

// 时间函数声明
function clock_gettime(clk_id: cint; tp: PTimeSpec): cint; cdecl; external 'c';

const
  O_CREAT = $40;
  O_EXCL = $80;
  SEM_FAILED = PSem(-1);
  CLOCK_REALTIME = 0;

implementation

{ TNamedSemaphoreGuard }

constructor TNamedSemaphoreGuard.Create(ASemaphore: PSem; const AName: string);
begin
  inherited Create;
  FSemaphore := ASemaphore;
  FName := AName;
  FReleased := False;
end;

destructor TNamedSemaphoreGuard.Destroy;
var
  LErrno: cint;
begin
  if not FReleased and (FSemaphore <> SEM_FAILED) and (FSemaphore <> nil) then
  begin
    // 尝试释放信号�?
    if sem_post(FSemaphore) <> 0 then
    begin
      LErrno := fpGetErrno;
      // 只在特定错误情况下忽略，其他情况记录错误
      case LErrno of
        ESysEINVAL: ; // 信号量无效，可能已被关闭
        ESysEOVERFLOW: ; // 计数溢出，可能是重复释放
      else
        // 其他错误情况下，我们无法抛出异常（在析构函数中）
        // 但可以通过其他方式记录错误，比如写入日�?
        // 这里暂时忽略，但在生产环境中应该记录
      end;
    end;
    FReleased := True;
  end;
  inherited Destroy;
end;

function TNamedSemaphoreGuard.GetName: string;
begin
  Result := FName;
end;

function TNamedSemaphoreGuard.GetCount: Integer;
var
  LValue: cint;
begin
  if sem_getvalue(FSemaphore, @LValue) = 0 then
    Result := LValue
  else
    Result := -1; // 获取失败
end;

function TNamedSemaphoreGuard.IsReleased: Boolean;
begin
  Result := FReleased;
end;

procedure TNamedSemaphoreGuard.Release;
begin
  if not FReleased and (FSemaphore <> SEM_FAILED) and (FSemaphore <> nil) then
  begin
    if sem_post(FSemaphore) = 0 then
      FReleased := True
    else
      raise ELockError.CreateFmt('Failed to release semaphore guard "%s": %s',
        [FName, SysErrorMessage(fpGetErrno)]);
  end;
end;

{ TNamedSemaphore }

function TNamedSemaphore.ValidateName(const AName: string): string;
begin
  if Length(AName) = 0 then
    raise EInvalidArgument.Create('Semaphore name cannot be empty');
    
  if Length(AName) > 255 then  // NAME_MAX
    raise EInvalidArgument.CreateFmt('Semaphore name too long: %d characters (max 255)', [Length(AName)]);
    
  // POSIX 信号量名称不能包含额外的 '/' 字符（除了前缀�?
  if Pos('/', AName) > 0 then
    raise EInvalidArgument.CreateFmt('Invalid character in semaphore name: %s', [AName]);
  
  Result := AName;
end;

function TNamedSemaphore.CreateSemName(const AName: string): string;
begin
  // POSIX 信号量名称必须以 '/' 开�?
  if AName[1] <> '/' then
    Result := '/' + AName
  else
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

function TNamedSemaphore.TimeoutToTimespec(ATimeoutMs: Cardinal): TTimeSpec;
var
  LCurrentTime: TTimeSpec;
  LNanoSeconds: Int64;
begin
  // 获取当前时间
  if clock_gettime(CLOCK_REALTIME, @LCurrentTime) <> 0 then
    raise ELockError.Create('Failed to get current time');
    
  // 计算绝对超时时间
  LNanoSeconds := Int64(LCurrentTime.tv_nsec) + Int64(ATimeoutMs) * 1000000;
  Result.tv_sec := LCurrentTime.tv_sec + (LNanoSeconds div 1000000000);
  Result.tv_nsec := LNanoSeconds mod 1000000000;
end;

constructor TNamedSemaphore.Create(const AName: string; AInitialCount, AMaxCount: Integer);
var
  LName: string;
  LSemName: string;
  LSemNameAnsi: AnsiString;
begin
  inherited Create;

  LName := ValidateName(AName);
  ValidateCount(AInitialCount, AMaxCount);

  FOriginalName := LName;
  FMaxCount := AMaxCount;

  // 初始化性能监控字段
  FEnablePerformanceMonitoring := False; // 默认关闭
  FWaitCount := 0;
  FReleaseCount := 0;
  FTotalWaitTime := 0.0;

  // 优化字符串转换：一次性完成所有转�?
  LSemName := CreateSemName(LName);
  LSemNameAnsi := AnsiString(LSemName);
  FSemName := LSemNameAnsi; // 避免重复转换

  // 尝试创建新的信号�?
  FSemaphore := sem_open(PAnsiChar(LSemNameAnsi), O_CREAT or O_EXCL, $644, AInitialCount);

  if FSemaphore = SEM_FAILED then
  begin
    // 如果创建失败，尝试打开现有�?
    FSemaphore := sem_open(PAnsiChar(LSemNameAnsi), 0);
    FIsCreator := False;

    if FSemaphore = SEM_FAILED then
      raise ELockError.CreateFmt('Failed to create or open named semaphore "%s": %s',
        [LName, SysErrorMessage(fpGetErrno)]);
  end
  else
    FIsCreator := True;
end;

constructor TNamedSemaphore.Create(const AName: string; const AConfig: TNamedSemaphoreConfig);
begin
  // Unix 平台：命名信号量默认就是全局的，无需特殊处理
  Create(AName, AConfig.InitialCount, AConfig.MaxCount);

  // 设置性能监控选项
  FEnablePerformanceMonitoring := AConfig.EnablePerformanceMonitoring;
end;

class function TNamedSemaphore.TryOpen(const AName: string): INamedSemaphore;
var
  LName: string;
  LSemName: string;
  LSemaphore: PSem;
  LInstance: TNamedSemaphore;
begin
  Result := nil;

  // 验证名称
  if Length(AName) = 0 then
    Exit;

  try
    LName := AName;
    if Length(LName) > 255 then  // NAME_MAX
      Exit;

    // 创建 POSIX 信号量名称并优化字符串转�?
    if LName[1] <> '/' then
      LSemName := '/' + LName
    else
      LSemName := LName;

    // 尝试打开现有信号量（不创建新的）- 优化字符串转�?
    LSemaphore := sem_open(PAnsiChar(AnsiString(LSemName)), 0);

    if LSemaphore = SEM_FAILED then
      Exit; // 信号量不存在或无法打开

    // 创建包装实例
    LInstance := TNamedSemaphore.Create;
    LInstance.FSemaphore := LSemaphore;
    LInstance.FSemName := AnsiString(LSemName);
    LInstance.FOriginalName := LName;
    LInstance.FIsCreator := False;
    LInstance.FMaxCount := -1; // 无法确定最大计�?

    Result := LInstance;
  except
    // 忽略所有异常，返回 nil
  end;
end;

destructor TNamedSemaphore.Destroy;
begin
  // 关闭信号�?
  if FSemaphore <> SEM_FAILED then
  begin
    sem_close(FSemaphore);
    
    // 如果是创建者，删除信号�?
    if FIsCreator then
      sem_unlink(PAnsiChar(FSemName));
      
    FSemaphore := SEM_FAILED;
  end;
  
  inherited Destroy;
end;

function TNamedSemaphore.GetLastError: TWaitError;
begin
  // 简化的错误映射
  case fpGetErrno of
    ESysETIMEDOUT: Result := weTimeout;
    ESysEACCES: Result := weAccessDenied;
    ESysEINVAL: Result := weInvalidHandle;
    ESysENOMEM: Result := weResourceExhausted;
    else Result := weSystemError;
  end;
end;

function TNamedSemaphore.Wait: INamedSemaphoreGuard;
begin
  if sem_wait(FSemaphore) <> 0 then
    raise ELockError.CreateFmt('Failed to wait for named semaphore "%s": %s',
      [FOriginalName, SysErrorMessage(fpGetErrno)]);

  Result := TNamedSemaphoreGuard.Create(FSemaphore, FOriginalName);
end;

function TNamedSemaphore.TryWait: INamedSemaphoreGuard;
var
  LErrno: cint;
  LResult: cint;
begin
  // 检查信号量有效�?
  if FSemaphore = SEM_FAILED then
    raise ELockError.CreateFmt('Named semaphore "%s" is invalid', [FOriginalName]);

  LResult := sem_trywait(FSemaphore);
  if LResult = 0 then
    Result := TNamedSemaphoreGuard.Create(FSemaphore, FOriginalName)
  else
  begin
    LErrno := fpGetErrno;
    // 严格处理错误码，只接受明确的"资源不可�?错误
    case LErrno of
      ESysEAGAIN:
        Result := nil; // 信号量不可用，这是正常情�?
      ESysEINVAL:
        raise ELockError.CreateFmt('Invalid semaphore "%s"', [FOriginalName]);
      ESysEINTR:
        raise ELockError.CreateFmt('Operation interrupted for semaphore "%s"', [FOriginalName]);
    else
      // 检查是否是 EWOULDBLOCK（可能与 EAGAIN 相同�?
      if LErrno = ESysEWOULDBLOCK then
        Result := nil
      else
        raise ELockError.CreateFmt('Failed to try wait for named semaphore "%s": %s (errno: %d)',
          [FOriginalName, SysErrorMessage(LErrno), LErrno]);
    end;
  end;
end;

function TNamedSemaphore.TryWaitFor(ATimeoutMs: Cardinal): INamedSemaphoreGuard;
var
  LTimespec: TTimeSpec;
  LResult: cint;
  LErrno: cint;
begin
  if ATimeoutMs = 0 then
    Exit(TryWait);

  if ATimeoutMs = Cardinal(-1) then
    Exit(Wait);

  // 清除之前的错误码
  fpSetErrno(0);

  // 使用 sem_timedwait
  LTimespec := TimeoutToTimespec(ATimeoutMs);
  LResult := sem_timedwait(FSemaphore, @LTimespec);

  if LResult = 0 then
    Result := TNamedSemaphoreGuard.Create(FSemaphore, FOriginalName)
  else
  begin
    LErrno := fpGetErrno;
    if (LErrno = ESysETIMEDOUT) or ((LResult = -1) and (LErrno = 0)) then
      Result := nil
    else
      raise ELockError.CreateFmt('Failed to wait for named semaphore "%s" with timeout: %s (errno: %d)',
        [FOriginalName, SysErrorMessage(LErrno), LErrno]);
  end;
end;

procedure TNamedSemaphore.Release;
begin
  Release(1);
end;

procedure TNamedSemaphore.Release(ACount: Integer);
var
  I: Integer;
  LCurrentCount: Integer;
  LFailedAt: Integer;
  LErrno: cint;
begin
  if ACount <= 0 then
    raise EInvalidArgument.CreateFmt('Release count must be positive: %d', [ACount]);

  // 检查信号量有效�?
  if FSemaphore = SEM_FAILED then
    raise ELockError.CreateFmt('Named semaphore "%s" is invalid', [FOriginalName]);

  // 检查是否会超过最大计数（仅在已知最大计数时�?
  if FMaxCount > 0 then
  begin
    LCurrentCount := GetCurrentCount;
    if (LCurrentCount >= 0) and (LCurrentCount + ACount > FMaxCount) then
      raise ELockError.CreateFmt('Releasing %d would exceed max count %d (current: %d)',
        [ACount, FMaxCount, LCurrentCount]);
  end;

  // POSIX 信号量一次只能释放一个计数，优化循环调用
  LFailedAt := 0;
  for I := 1 to ACount do
  begin
    if sem_post(FSemaphore) <> 0 then
    begin
      LFailedAt := I;
      LErrno := fpGetErrno;
      Break;
    end;
  end;

  // 如果有失败，抛出详细错误信息
  if LFailedAt > 0 then
    raise ELockError.CreateFmt('Failed to release named semaphore "%s" at count %d/%d: %s (errno: %d)',
      [FOriginalName, LFailedAt, ACount, SysErrorMessage(LErrno), LErrno]);
end;

function TNamedSemaphore.GetName: string;
begin
  Result := FOriginalName;
end;

function TNamedSemaphore.GetCurrentCount: Integer;
var
  LValue: cint;
begin
  if sem_getvalue(FSemaphore, @LValue) = 0 then
    Result := LValue
  else
    Result := -1; // 获取失败
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
  // 注意：这里会立即释放信号量，因为 LGuard 会在方法结束时析�?
end;

function TNamedSemaphore.TryAcquire: Boolean;
var
  LGuard: INamedSemaphoreGuard;
begin
  LGuard := TryWait;
  Result := Assigned(LGuard);
end;

function TNamedSemaphore.TryAcquire(ATimeoutMs: Cardinal): Boolean;
var
  LGuard: INamedSemaphoreGuard;
begin
  LGuard := TryWaitFor(ATimeoutMs);
  Result := Assigned(LGuard);
end;

procedure TNamedSemaphore.Acquire(ATimeoutMs: Cardinal);
var
  LGuard: INamedSemaphoreGuard;
begin
  LGuard := TryWaitFor(ATimeoutMs);
  if not Assigned(LGuard) then
    raise ETimeoutError.CreateFmt('Timeout waiting for named semaphore "%s"', [FOriginalName]);
end;

function TNamedSemaphore.GetHandle: Pointer;
begin
  Result := FSemaphore;
end;

function TNamedSemaphore.IsCreator: Boolean;
begin
  Result := FIsCreator;
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
  LResult: cint;
  LStartTime, LEndTime: TDateTime;
begin
  try
    // 检查信号量有效�?
    if FSemaphore = SEM_FAILED then
      Exit(TNamedSemaphoreGuardResult.Failure(
        TNamedSemaphoreError.SystemError('Named semaphore is invalid', 0)));

    // 性能监控：记录开始时�?
    if FEnablePerformanceMonitoring then
      LStartTime := Now;

    LResult := sem_wait(FSemaphore);

    // 性能监控：记录结束时间和统计
    if FEnablePerformanceMonitoring then
    begin
      LEndTime := Now;
      Inc(FWaitCount);
      FTotalWaitTime := FTotalWaitTime + ((LEndTime - LStartTime) * 24 * 60 * 60 * 1000);
    end;

    if LResult = 0 then
      Result := TNamedSemaphoreGuardResult.Success(TNamedSemaphoreGuard.Create(FSemaphore, FOriginalName))
    else
    begin
      case fpGetErrno of
        ESysEINTR:
          Result := TNamedSemaphoreGuardResult.Failure(
            TNamedSemaphoreError.SystemError('Operation interrupted', ESysEINTR));
        ESysEINVAL:
          Result := TNamedSemaphoreGuardResult.Failure(
            TNamedSemaphoreError.InvalidArgument('Invalid semaphore'));
      else
        Result := TNamedSemaphoreGuardResult.Failure(
          TNamedSemaphoreError.SystemError('Failed to wait for named semaphore', fpGetErrno));
      end;
    end;
  except
    on E: Exception do
      Result := TNamedSemaphoreGuardResult.Failure(
        TNamedSemaphoreError.Unknown('Exception in WaitSafe: ' + E.Message));
  end;
end;

function TNamedSemaphore.TryWaitSafe: TNamedSemaphoreGuardResult;
var
  LResult: cint;
  LErrno: cint;
begin
  try
    // 检查信号量有效�?
    if FSemaphore = SEM_FAILED then
      Exit(TNamedSemaphoreGuardResult.Failure(
        TNamedSemaphoreError.SystemError('Named semaphore is invalid', 0)));

    LResult := sem_trywait(FSemaphore);
    if LResult = 0 then
      Result := TNamedSemaphoreGuardResult.Success(TNamedSemaphoreGuard.Create(FSemaphore, FOriginalName))
    else
    begin
      LErrno := fpGetErrno;
      case LErrno of
        ESysEAGAIN:
          Result := TNamedSemaphoreGuardResult.Failure(
            TNamedSemaphoreError.Timeout('Semaphore not available (would block)'));
        ESysEINVAL:
          Result := TNamedSemaphoreGuardResult.Failure(
            TNamedSemaphoreError.InvalidArgument('Invalid semaphore'));
        ESysEINTR:
          Result := TNamedSemaphoreGuardResult.Failure(
            TNamedSemaphoreError.SystemError('Operation interrupted', ESysEINTR));
      else
        if LErrno = ESysEWOULDBLOCK then
          Result := TNamedSemaphoreGuardResult.Failure(
            TNamedSemaphoreError.Timeout('Semaphore not available (would block)'))
        else
          Result := TNamedSemaphoreGuardResult.Failure(
            TNamedSemaphoreError.SystemError('Failed to try wait for named semaphore', LErrno));
      end;
    end;
  except
    on E: Exception do
      Result := TNamedSemaphoreGuardResult.Failure(
        TNamedSemaphoreError.Unknown('Exception in TryWaitSafe: ' + E.Message));
  end;
end;

function TNamedSemaphore.TryWaitForSafe(ATimeoutMs: Cardinal): TNamedSemaphoreGuardResult;
var
  LTimespec: TTimeSpec;
  LResult: cint;
  LErrno: cint;
begin
  try
    // 检查信号量有效�?
    if FSemaphore = SEM_FAILED then
      Exit(TNamedSemaphoreGuardResult.Failure(
        TNamedSemaphoreError.SystemError('Named semaphore is invalid', 0)));

    LTimespec := TimeoutToTimespec(ATimeoutMs);
    LResult := sem_timedwait(FSemaphore, @LTimespec);

    if LResult = 0 then
      Result := TNamedSemaphoreGuardResult.Success(TNamedSemaphoreGuard.Create(FSemaphore, FOriginalName))
    else
    begin
      LErrno := fpGetErrno;
      case LErrno of
        ESysETIMEDOUT:
          Result := TNamedSemaphoreGuardResult.Failure(
            TNamedSemaphoreError.Timeout(Format('Timeout waiting for semaphore after %d ms', [ATimeoutMs])));
        ESysEINVAL:
          Result := TNamedSemaphoreGuardResult.Failure(
            TNamedSemaphoreError.InvalidArgument('Invalid semaphore or timeout'));
        ESysEINTR:
          Result := TNamedSemaphoreGuardResult.Failure(
            TNamedSemaphoreError.SystemError('Operation interrupted', ESysEINTR));
      else
        Result := TNamedSemaphoreGuardResult.Failure(
          TNamedSemaphoreError.SystemError('Failed to wait for named semaphore with timeout', LErrno));
      end;
    end;
  except
    on E: Exception do
      Result := TNamedSemaphoreGuardResult.Failure(
        TNamedSemaphoreError.Unknown('Exception in TryWaitForSafe: ' + E.Message));
  end;
end;

end.
