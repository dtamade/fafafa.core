unit fafafa.core.sync.namedBarrier.base;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.base, fafafa.core.sync.base, fafafa.core.result;

type
  // Forward declarations
  INamedBarrier = interface;
  INamedBarrierGuard = interface;

  // Error type for namedBarrier operations
  TNamedBarrierError = (
    nbeNone,
    nbeInvalidArgument,
    nbeTimeout,
    nbeSystemError,
    nbeNotFound,
    nbeInvalidState,
    nbeUnknownError
  );

  // Specialized Result types using fafafa.core.result
  TNamedBarrierResult = specialize TResult<INamedBarrier, TNamedBarrierError>;
  TNamedBarrierGuardResult = specialize TResult<INamedBarrierGuard, TNamedBarrierError>;
  TNamedBarrierBoolResult = specialize TResult<Boolean, TNamedBarrierError>;
  TNamedBarrierCardinalResult = specialize TResult<Cardinal, TNamedBarrierError>;
  TNamedBarrierVoidResult = specialize TResult<Boolean, TNamedBarrierError>; // 使用 Boolean 作为 void 的替代

type
  // ===== 配置结构 =====
  TNamedBarrierConfig = record
    TimeoutMs: Cardinal;           // 默认超时时间（毫秒）
    RetryIntervalMs: Cardinal;     // 重试间隔（毫秒）
    MaxRetries: Integer;           // 最大重试次数
    UseGlobalNamespace: Boolean;   // 是否使用全局命名空间
    ParticipantCount: Cardinal;    // 参与者数量
    AutoReset: Boolean;            // 是否自动重置
  end;

// 配置辅助函数
function DefaultNamedBarrierConfig: TNamedBarrierConfig;
function NamedBarrierConfigWithTimeout(ATimeoutMs: Cardinal): TNamedBarrierConfig;
function NamedBarrierConfigWithParticipants(AParticipantCount: Cardinal): TNamedBarrierConfig;
function GlobalNamedBarrierConfig: TNamedBarrierConfig;

type
  // ===== RAII 模式的屏障守卫 =====
  INamedBarrierGuard = interface
    ['{B2C3D4E5-6F78-9012-CDEF-123456789ABC}']
    function GetName: string;           // 获取屏障名称
    function GetParticipantCount: Cardinal; // 获取参与者数量
    function GetWaitingCount: Cardinal; // 获取当前等待者数量
    function IsLastParticipant: Boolean; // 是否为最后一个参与者
    // 析构时自动处理屏障状态，无需手动调用
  end;

  // ===== 现代化的命名屏障接口 =====
  INamedBarrier = interface
    ['{C3D4E5F6-7890-1234-ABCD-EF123456789D}']
    // 核心屏障操作 - 返回 RAII 守卫
    function Wait: INamedBarrierGuard;                              // 阻塞等待
    function TryWait: INamedBarrierGuard;                          // 非阻塞尝试
    function TryWaitFor(ATimeoutMs: Cardinal): INamedBarrierGuard; // 带超时等待

    // 查询操作
    function GetName: string;                    // 获取屏障名称
    function GetParticipantCount: Cardinal;      // 获取参与者数量
    function GetWaitingCount: Cardinal;          // 获取当前等待者数量
    function IsSignaled: Boolean;                // 屏障是否已触发

    // 控制操作
    procedure Reset;                             // 重置屏障
    procedure Signal;                            // 手动触发屏障（紧急情况）

    // ===== 增量接口：基于 TResult 的现代化错误处理 =====
    // Modern error handling with TResult (incremental interface)

    // 核心屏障操作 - 返回 TResult 包装的守卫
    function WaitResult: TNamedBarrierGuardResult;                              // 阻塞等待
    function TryWaitResult: TNamedBarrierGuardResult;                          // 非阻塞尝试
    function TryWaitForResult(ATimeoutMs: Cardinal): TNamedBarrierGuardResult; // 带超时等待

    // 查询操作 - 返回 TResult 包装的值
    function GetWaitingCountResult: TNamedBarrierCardinalResult;     // 获取当前等待者数量
    function IsSignaledResult: TNamedBarrierBoolResult;              // 屏障是否已触发

    // 控制操作 - 返回操作结果
    function ResetResult: TNamedBarrierVoidResult;                   // 重置屏障
    function SignalResult: TNamedBarrierVoidResult;                  // 手动触发屏障

    // 兼容性方法（向后兼容，但不推荐使用）
    procedure Arrive; deprecated 'Use Wait() instead';
    function TryArrive: Boolean; deprecated 'Use TryWait() instead';
    function TryArrive(ATimeoutMs: Cardinal): Boolean; overload; deprecated 'Use TryWaitFor() instead';
    procedure Arrive(ATimeoutMs: Cardinal); overload; deprecated 'Use TryWaitFor() instead';
    function GetHandle: Pointer; deprecated 'Implementation detail';
    function IsCreator: Boolean; deprecated 'Implementation detail';
  end;

implementation

function DefaultNamedBarrierConfig: TNamedBarrierConfig;
begin
  Result.TimeoutMs := 30000;          // 30秒默认超时（屏障通常需要更长时间）
  Result.RetryIntervalMs := 10;       // 10毫秒重试间隔
  Result.MaxRetries := 100;           // 最多重试100次
  Result.UseGlobalNamespace := False; // 默认不使用全局命名空间
  Result.ParticipantCount := 2;       // 默认2个参与者
  Result.AutoReset := True;           // 默认自动重置
end;

function NamedBarrierConfigWithTimeout(ATimeoutMs: Cardinal): TNamedBarrierConfig;
begin
  Result := DefaultNamedBarrierConfig;
  Result.TimeoutMs := ATimeoutMs;
end;

function NamedBarrierConfigWithParticipants(AParticipantCount: Cardinal): TNamedBarrierConfig;
begin
  Result := DefaultNamedBarrierConfig;
  Result.ParticipantCount := AParticipantCount;
end;

function GlobalNamedBarrierConfig: TNamedBarrierConfig;
begin
  Result := DefaultNamedBarrierConfig;
  Result.UseGlobalNamespace := True;
end;

end.
