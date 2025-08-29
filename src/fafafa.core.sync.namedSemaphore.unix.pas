unit fafafa.core.sync.namedSemaphore.unix;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}
{$LINKLIB pthread}

interface

uses
  SysUtils, BaseUnix, Unix, UnixType,
  fafafa.core.base, fafafa.core.sync.base, fafafa.core.sync.namedSemaphore.base;

type
  // POSIX 信号量类型
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
  end;

  TNamedSemaphore = class(TInterfacedObject, INamedSemaphore)
  private
    FSemaphore: PSem;           // POSIX 信号量句柄
    FSemName: AnsiString;       // POSIX 信号量名称（使用 AnsiString 减少转换开销）
    FOriginalName: string;      // 保存用户提供的原始名称
    FIsCreator: Boolean;        // 是否为创建者
    FMaxCount: Integer;         // 最大计数值
    
    function ValidateName(const AName: string): string;
    function CreateSemName(const AName: string): string;
    function ValidateCount(AInitialCount, AMaxCount: Integer): Boolean;
    function TimeoutToTimespec(ATimeoutMs: Cardinal): TTimeSpec;
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

// POSIX 信号量函数声明
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
begin
  if not FReleased and (FSemaphore <> SEM_FAILED) and (FSemaphore <> nil) then
  begin
    // 检查信号量是否仍然有效，避免访问已关闭的信号量
    if sem_post(FSemaphore) <> 0 then
    begin
      // 如果释放失败，可能是信号量已经被关闭，忽略错误
      // 这是正常的，因为信号量对象可能先于守卫对象析构
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

{ TNamedSemaphore }

function TNamedSemaphore.ValidateName(const AName: string): string;
begin
  if Length(AName) = 0 then
    raise EInvalidArgument.Create('Semaphore name cannot be empty');
    
  if Length(AName) > 255 then  // NAME_MAX
    raise EInvalidArgument.CreateFmt('Semaphore name too long: %d characters (max 255)', [Length(AName)]);
    
  // POSIX 信号量名称不能包含额外的 '/' 字符（除了前缀）
  if Pos('/', AName) > 0 then
    raise EInvalidArgument.CreateFmt('Invalid character in semaphore name: %s', [AName]);
  
  Result := AName;
end;

function TNamedSemaphore.CreateSemName(const AName: string): string;
begin
  // POSIX 信号量名称必须以 '/' 开头
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
begin
  inherited Create;
  
  LName := ValidateName(AName);
  ValidateCount(AInitialCount, AMaxCount);
  
  FOriginalName := LName;
  FMaxCount := AMaxCount;
  LSemName := CreateSemName(LName);
  FSemName := AnsiString(LSemName);
  
  // 尝试创建新的信号量
  FSemaphore := sem_open(PAnsiChar(FSemName), O_CREAT or O_EXCL, $644, AInitialCount);
  
  if FSemaphore = SEM_FAILED then
  begin
    // 如果创建失败，尝试打开现有的
    FSemaphore := sem_open(PAnsiChar(FSemName), 0);
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
end;

destructor TNamedSemaphore.Destroy;
begin
  // 关闭信号量
  if FSemaphore <> SEM_FAILED then
  begin
    sem_close(FSemaphore);
    
    // 如果是创建者，删除信号量
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
  // 清除之前的错误码
  fpSetErrno(0);

  LResult := sem_trywait(FSemaphore);
  if LResult = 0 then
    Result := TNamedSemaphoreGuard.Create(FSemaphore, FOriginalName)
  else
  begin
    LErrno := fpGetErrno;
    // 对于 sem_trywait，如果信号量不可用，通常返回 EAGAIN
    // 但在某些系统上可能返回其他错误码，我们采用更宽松的处理
    if (LResult = -1) and (LErrno = 0) then
    begin
      // 如果返回 -1 但 errno 为 0，假设是资源不可用
      Result := nil;
    end
    else if (LErrno = ESysEAGAIN) or (LErrno = ESysEWOULDBLOCK) then
      Result := nil
    else
      raise ELockError.CreateFmt('Failed to try wait for named semaphore "%s": %s (errno: %d)',
        [FOriginalName, SysErrorMessage(LErrno), LErrno]);
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
begin
  if ACount <= 0 then
    raise EInvalidArgument.CreateFmt('Release count must be positive: %d', [ACount]);

  // 检查是否会超过最大计数（模拟 Windows 行为）
  LCurrentCount := GetCurrentCount;
  if (LCurrentCount >= 0) and (LCurrentCount + ACount > FMaxCount) then
    raise ELockError.CreateFmt('Releasing %d would exceed max count %d (current: %d)',
      [ACount, FMaxCount, LCurrentCount]);

  // POSIX 信号量一次只能释放一个计数，需要循环调用
  for I := 1 to ACount do
  begin
    if sem_post(FSemaphore) <> 0 then
      raise ELockError.CreateFmt('Failed to release named semaphore "%s": %s',
        [FOriginalName, SysErrorMessage(fpGetErrno)]);
  end;
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
  // 注意：这里会立即释放信号量，因为 LGuard 会在方法结束时析构
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

end.
