unit fafafa.core.sync.namedSemaphore.base;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.base, fafafa.core.sync.base;

type
  // ===== 错误处理结构 =====
  TNamedSemaphoreErrorKind = (
    sekNone,              // 无错误
    sekInvalidArgument,   // 无效参数
    sekTimeout,           // 超时
    sekAccessDenied,      // 访问被拒绝
    sekResourceExhausted, // 资源耗尽
    sekNotFound,          // 信号量不存在
    sekAlreadyExists,     // 信号量已存在
    sekSystemError,       // 系统错误
    sekUnknown            // 未知错误
  );

  TNamedSemaphoreError = record
    Kind: TNamedSemaphoreErrorKind;
    Message: string;
    SystemErrorCode: Integer;

    class function None: TNamedSemaphoreError; static;
    class function InvalidArgument(const AMessage: string): TNamedSemaphoreError; static;
    class function Timeout(const AMessage: string): TNamedSemaphoreError; static;
    class function AccessDenied(const AMessage: string): TNamedSemaphoreError; static;
    class function ResourceExhausted(const AMessage: string): TNamedSemaphoreError; static;
    class function NotFound(const AMessage: string): TNamedSemaphoreError; static;
    class function AlreadyExists(const AMessage: string): TNamedSemaphoreError; static;
    class function SystemError(const AMessage: string; ASystemErrorCode: Integer): TNamedSemaphoreError; static;
    class function Unknown(const AMessage: string): TNamedSemaphoreError; static;

    function IsError: Boolean;
    function ToString: string;
  end;

  // Result<T> 风格的错误处理
  TNamedSemaphoreGuardResult = record
    Guard: INamedSemaphoreGuard;
    Error: TNamedSemaphoreError;

    class function Success(const AGuard: INamedSemaphoreGuard): TNamedSemaphoreGuardResult; static;
    class function Failure(const AError: TNamedSemaphoreError): TNamedSemaphoreGuardResult; static;

    function IsSuccess: Boolean;
    function IsFailure: Boolean;
    function GetGuard: INamedSemaphoreGuard;  // 抛出异常版本
    function TryGetGuard(out AGuard: INamedSemaphoreGuard): Boolean; // 安全版本
  end;

  // ===== 配置结构 =====
  TNamedSemaphoreConfig = record
    UseGlobalNamespace: Boolean;   // 是否使用全局命名空间
    InitialCount: Integer;         // 初始计数值
    MaxCount: Integer;             // 最大计数值
    EnablePerformanceMonitoring: Boolean; // 是否启用性能监控
  end;

// 配置辅助函数
function DefaultNamedSemaphoreConfig: TNamedSemaphoreConfig;
function GlobalNamedSemaphoreConfig: TNamedSemaphoreConfig;
function NamedSemaphoreConfigWithCount(AInitialCount, AMaxCount: Integer): TNamedSemaphoreConfig;

type
  // ===== RAII 模式的信号量守卫 =====
  INamedSemaphoreGuard = interface
    ['{B2C3D4E5-6F7A-8901-BCDE-F23456789012}']
    function GetName: string;           // 获取信号量名称
    function GetCount: Integer;         // 获取当前计数值（如果支持）
    function IsReleased: Boolean;       // 检查是否已释放
    procedure Release;                  // 手动释放（支持提前释放场景）
    // 析构时自动释放信号量（如果尚未手动释放）
  end;

  // ===== 现代化的命名信号量接口 =====
  INamedSemaphore = interface
    ['{C3D4E5F6-7A8B-9CDE-F012-345678901234}']
    // 核心信号量操作 - 返回 RAII 守卫（异常版本）
    function Wait: INamedSemaphoreGuard;                              // 阻塞等待
    function TryWait: INamedSemaphoreGuard;                          // 非阻塞尝试
    function TryWaitFor(ATimeoutMs: Cardinal): INamedSemaphoreGuard; // 带超时等待

    // 现代化错误处理 - Result<T> 风格（noexcept 版本）
    function WaitSafe: TNamedSemaphoreGuardResult;                              // 阻塞等待
    function TryWaitSafe: TNamedSemaphoreGuardResult;                          // 非阻塞尝试
    function TryWaitForSafe(ATimeoutMs: Cardinal): TNamedSemaphoreGuardResult; // 带超时等待
    
    // 释放操作（不返回守卫，因为释放不需要 RAII）
    procedure Release; overload;                                      // 释放一个计数
    procedure Release(ACount: Integer); overload;                    // 释放多个计数

    // 查询操作
    function GetName: string;           // 获取信号量名称
    function GetCurrentCount: Integer;  // 获取当前可用计数（如果支持）
    function GetMaxCount: Integer;      // 获取最大计数值

    // 性能监控（可选功能）
    function GetWaitCount: Int64;       // 获取等待操作总次数
    function GetReleaseCount: Int64;    // 获取释放操作总次数
    function GetAverageWaitTime: Double; // 获取平均等待时间（毫秒）

    // 兼容性方法（向后兼容，但不推荐使用）
    procedure Acquire; deprecated 'Use Wait() instead';
    function TryAcquire: Boolean; deprecated 'Use TryWait() instead';
    function TryAcquire(ATimeoutMs: Cardinal): Boolean; overload; deprecated 'Use TryWaitFor() instead';
    procedure Acquire(ATimeoutMs: Cardinal); overload; deprecated 'Use TryWaitFor() instead';
    function GetHandle: Pointer; deprecated 'Implementation detail';
    function IsCreator: Boolean; deprecated 'Implementation detail';
  end;

implementation

function DefaultNamedSemaphoreConfig: TNamedSemaphoreConfig;
begin
  Result.UseGlobalNamespace := False; // 默认不使用全局命名空间
  Result.InitialCount := 1;           // 默认初始计数为1
  Result.MaxCount := 1;               // 默认最大计数为1（类似互斥锁）
  Result.EnablePerformanceMonitoring := False; // 默认不启用性能监控
end;

function GlobalNamedSemaphoreConfig: TNamedSemaphoreConfig;
begin
  Result := DefaultNamedSemaphoreConfig;
  Result.UseGlobalNamespace := True;
end;

function NamedSemaphoreConfigWithCount(AInitialCount, AMaxCount: Integer): TNamedSemaphoreConfig;
begin
  Result := DefaultNamedSemaphoreConfig;
  Result.InitialCount := AInitialCount;
  Result.MaxCount := AMaxCount;
end;

// ===== TNamedSemaphoreError 实现 =====

class function TNamedSemaphoreError.None: TNamedSemaphoreError;
begin
  Result.Kind := sekNone;
  Result.Message := '';
  Result.SystemErrorCode := 0;
end;

class function TNamedSemaphoreError.InvalidArgument(const AMessage: string): TNamedSemaphoreError;
begin
  Result.Kind := sekInvalidArgument;
  Result.Message := AMessage;
  Result.SystemErrorCode := 0;
end;

class function TNamedSemaphoreError.Timeout(const AMessage: string): TNamedSemaphoreError;
begin
  Result.Kind := sekTimeout;
  Result.Message := AMessage;
  Result.SystemErrorCode := 0;
end;

class function TNamedSemaphoreError.AccessDenied(const AMessage: string): TNamedSemaphoreError;
begin
  Result.Kind := sekAccessDenied;
  Result.Message := AMessage;
  Result.SystemErrorCode := 0;
end;

class function TNamedSemaphoreError.ResourceExhausted(const AMessage: string): TNamedSemaphoreError;
begin
  Result.Kind := sekResourceExhausted;
  Result.Message := AMessage;
  Result.SystemErrorCode := 0;
end;

class function TNamedSemaphoreError.NotFound(const AMessage: string): TNamedSemaphoreError;
begin
  Result.Kind := sekNotFound;
  Result.Message := AMessage;
  Result.SystemErrorCode := 0;
end;

class function TNamedSemaphoreError.AlreadyExists(const AMessage: string): TNamedSemaphoreError;
begin
  Result.Kind := sekAlreadyExists;
  Result.Message := AMessage;
  Result.SystemErrorCode := 0;
end;

class function TNamedSemaphoreError.SystemError(const AMessage: string; ASystemErrorCode: Integer): TNamedSemaphoreError;
begin
  Result.Kind := sekSystemError;
  Result.Message := AMessage;
  Result.SystemErrorCode := ASystemErrorCode;
end;

class function TNamedSemaphoreError.Unknown(const AMessage: string): TNamedSemaphoreError;
begin
  Result.Kind := sekUnknown;
  Result.Message := AMessage;
  Result.SystemErrorCode := 0;
end;

function TNamedSemaphoreError.IsError: Boolean;
begin
  Result := Kind <> sekNone;
end;

function TNamedSemaphoreError.ToString: string;
begin
  case Kind of
    sekNone: Result := 'No error';
    sekInvalidArgument: Result := 'Invalid argument: ' + Message;
    sekTimeout: Result := 'Timeout: ' + Message;
    sekAccessDenied: Result := 'Access denied: ' + Message;
    sekResourceExhausted: Result := 'Resource exhausted: ' + Message;
    sekNotFound: Result := 'Not found: ' + Message;
    sekAlreadyExists: Result := 'Already exists: ' + Message;
    sekSystemError: Result := Format('System error (%d): %s', [SystemErrorCode, Message]);
    sekUnknown: Result := 'Unknown error: ' + Message;
  else
    Result := 'Undefined error: ' + Message;
  end;
end;

// ===== TNamedSemaphoreGuardResult 实现 =====

class function TNamedSemaphoreGuardResult.Success(const AGuard: INamedSemaphoreGuard): TNamedSemaphoreGuardResult;
begin
  Result.Guard := AGuard;
  Result.Error := TNamedSemaphoreError.None;
end;

class function TNamedSemaphoreGuardResult.Failure(const AError: TNamedSemaphoreError): TNamedSemaphoreGuardResult;
begin
  Result.Guard := nil;
  Result.Error := AError;
end;

function TNamedSemaphoreGuardResult.IsSuccess: Boolean;
begin
  Result := not Error.IsError;
end;

function TNamedSemaphoreGuardResult.IsFailure: Boolean;
begin
  Result := Error.IsError;
end;

function TNamedSemaphoreGuardResult.GetGuard: INamedSemaphoreGuard;
begin
  if IsFailure then
    raise ELockError.Create(Error.ToString);
  Result := Guard;
end;

function TNamedSemaphoreGuardResult.TryGetGuard(out AGuard: INamedSemaphoreGuard): Boolean;
begin
  Result := IsSuccess;
  if Result then
    AGuard := Guard
  else
    AGuard := nil;
end;

end.
