unit fafafa.core.sync.spin.base;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.base, fafafa.core.sync.base;

type
  // ===== 自旋锁策略配置 =====
  TSpinBackoffStrategy = (
    sbsLinear,      // 线性退避
    sbsExponential, // 指数退避
    sbsAdaptive     // 自适应退避（默认）
  );

  // 注意：自旋锁错误类型现在统一使用 TWaitError (在 fafafa.core.sync.base 中定义)

  // ===== 前向声明 =====
  ISpinLock = interface;

  // ===== RAII 自旋锁守卫接口 =====
  ISpinLockGuard = interface
    ['{E1F2A3B4-C5D6-7E8F-9A0B-1C2D3E4F5A6B}']
    function IsValid: Boolean;           // 守卫是否有效（成功获取到锁）
    function GetSpinLock: ISpinLock;     // 获取关联的自旋锁对象
    procedure Release;                   // 手动释放守卫（可选，析构时自动释放）
  end;

  // ===== 自旋锁统计信息 =====
  TSpinLockStats = record
    AcquireCount: QWord;                  // 总获取次数
    ContentionCount: QWord;               // 竞争次数（需要自旋的次数）
    TotalSpinCount: QWord;                // 总自旋次数
    MaxSpinsPerAcquire: Integer;          // 单次获取最大自旋次数
    AvgSpinsPerAcquire: Double;           // 平均每次获取的自旋次数
    TotalWaitTimeUs: QWord;               // 总等待时间（微秒）
    MaxWaitTimeUs: QWord;                 // 最大等待时间（微秒）
    AvgWaitTimeUs: Double;                // 平均等待时间（微秒）
  end;

  TSpinLockPolicy = record
    MaxSpins: Integer;                    // 最大自旋次数（默认：64）
    BackoffStrategy: TSpinBackoffStrategy; // 退避策略（默认：自适应）
    MaxBackoffMs: Integer;                // 最大退避时间毫秒（默认：16）
    EnableStats: Boolean;                 // 启用统计功能（默认：False）
    EnableErrorTracking: Boolean;         // 启用错误跟踪（默认：True）
    EnableDeadlockDetection: Boolean;     // 启用死锁检测（默认：False）
    DeadlockTimeoutMs: Cardinal;          // 死锁检测超时（默认：5000）
  end;

  // ===== 简化的自旋锁接口 =====
  ISpinLock = interface(ILock)
    ['{C7D8E9F0-1A2B-4C5D-8E9F-0A1B2C3D4E5F}']

    function TryAcquire(ATimeoutMs: Cardinal): Boolean; overload;

    // 自旋锁特有方法
    function GetMaxSpins: Integer;
    procedure SetMaxSpins(ASpins: Integer);

    // 状态查询（线程安全版本）
    function IsCurrentThreadOwner: Boolean;  // 替代有问题的 IsHeld
    function GetLockState: Integer;          // 0=未锁定, 1=已锁定, -1=未知

    // 错误处理 (继承自 ISynchronizable.GetLastError)
    function GetErrorMessage(AError: TWaitError): string;
    procedure ClearLastError;

    // RAII 支持
    function Lock: ISpinLockGuard;                    // 创建 RAII 守护对象，自动管理锁的生命周期
    function TryLock: ISpinLockGuard;                 // 尝试创建 RAII 守护对象，失败时返回无效守卫
    function TryLock(ATimeoutMs: Cardinal): ISpinLockGuard; // 带超时的 RAII 守护对象

    {$IFDEF DEBUG}
    // Debug 功能（仅 Debug 模式）
    function GetOwnerThread: TThreadID;
    function GetHoldDurationMs: Cardinal;
    function IsDeadlockDetectionEnabled: Boolean;
    {$ENDIF}
  end;

  // ===== 统计功能接口 =====
  ISpinLockWithStats = interface(ISpinLock)
    ['{F1E2D3C4-B5A6-9788-1234-567890ABCDEF}']

    // 获取统计信息
    function GetStats: TSpinLockStats;

    // 计算性能指标
    function GetContentionRate: Double;        // 竞争率 (0.0-100.0)
    function GetSpinEfficiency: Double;        // 自旋效率 (0.0-100.0)
    function GetAverageWaitTime: Double;       // 平均等待时间（微秒）

    // 重置统计
    procedure ResetStats;

    // 启用/禁用统计
    procedure EnableStats(AEnable: Boolean);
    function IsStatsEnabled: Boolean;
  end;

  // ===== 调试功能接口 =====
  ISpinLockDebug = interface(ISpinLock)
    ['{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}']

    // 调试信息
    function GetDebugInfo: string;
    function GetCurrentSpins: Integer;         // 当前自旋次数
    function GetHoldCount: Integer;            // 持有计数（重入检测）

    // 性能分析
    function GetLastAcquireSpins: Integer;     // 上次获取的自旋次数
    function GetLastAcquireTimeUs: QWord;      // 上次获取耗时（微秒）

    // 死锁检测
    function CheckPotentialDeadlock: Boolean;
    function GetDeadlockInfo: string;
  end;



// ===== 策略工厂函数 =====
function DefaultSpinLockPolicy: TSpinLockPolicy;

// ===== 错误处理辅助函数 =====
function SpinLockErrorToString(AError: TWaitError): string;

implementation

// ===== 错误处理辅助函数 =====
function SpinLockErrorToString(AError: TWaitError): string;
begin
  case AError of
    weNone: Result := 'No error';
    weTimeout: Result := 'Operation timed out';
    weInvalidState: Result := 'Invalid lock state';
    weReentrancy: Result := 'Reentrancy detected';
    weNotOwner: Result := 'Lock not owned by current thread';
    weAlreadyReleased: Result := 'Lock already released';
    weSystemError: Result := 'System error occurred';
    weDeadlock: Result := 'Potential deadlock detected';
    weInvalidHandle: Result := 'Invalid handle';
    weResourceExhausted: Result := 'Resource exhausted';
    weAccessDenied: Result := 'Access denied';
    weNotSupported: Result := 'Operation not supported';
  else
    Result := 'Unknown error';
  end;
end;

function DefaultSpinLockPolicy: TSpinLockPolicy;
begin
  Result.MaxSpins := 64;
  Result.BackoffStrategy := sbsAdaptive;
  Result.MaxBackoffMs := 16;
  Result.EnableStats := False;
  Result.EnableErrorTracking := True;
  Result.EnableDeadlockDetection := False;
  Result.DeadlockTimeoutMs := 5000;
end;



end.
