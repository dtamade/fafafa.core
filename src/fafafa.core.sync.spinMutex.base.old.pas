unit fafafa.core.sync.spinMutex.base;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.base, fafafa.core.sync.base, fafafa.core.sync.spin.base;

type
  // ===== 复用 spin 模块的类型定义 =====
  TSpinBackoffStrategy = fafafa.core.sync.spin.base.TSpinBackoffStrategy;
  TSpinMutexStats = fafafa.core.sync.spin.base.TSpinLockStats;
  TSpinMutexPolicy = fafafa.core.sync.spin.base.TSpinLockPolicy;

  // ===== 简化的配置结构 =====
  TSpinMutexConfig = record
    // 基础配置（映射到 TSpinLockPolicy）
    MaxSpinCount: Cardinal;               // 最大自旋次数（默认：64）
    BackoffStrategy: TSpinBackoffStrategy; // 退避策略（默认：自适应）
    MaxBackoffMs: Cardinal;               // 最大退避时间毫秒（默认：16）

    // SpinMutex 特有配置
    DefaultTimeoutMs: Cardinal;           // 默认超时时间（毫秒，默认：5000）
    EnableStats: Boolean;                 // 是否启用统计信息收集（默认：False）
    EnableErrorTracking: Boolean;         // 启用错误跟踪（默认：True）
  end;

  // ===== 复用 spin 模块的接口 =====
  ISpinMutex = interface(ISpinLock)
    ['{6F53E4F1-6B7B-4B4F-925F-0E0C7D8E1A2B}']
    // 继承 ISpinLock 的所有方法：Acquire, Release, TryAcquire, GetLastError 等

    // ===== SpinMutex 特有的扩展接口 =====
    function GetName: string;                     // 获取互斥锁名称
    function GetConfig: TSpinMutexConfig;         // 获取配置
    procedure UpdateConfig(const AConfig: TSpinMutexConfig); // 更新配置
  end;

  // ===== 类型别名，复用 spin 模块的守卫 =====
  ISpinMutexGuard = ISpinLockGuard;





// ===== 配置辅助函数 =====
function DefaultSpinMutexConfig: TSpinMutexConfig;
function SpinMutexConfigWithTimeout(ATimeoutMs: Cardinal): TSpinMutexConfig;
function GlobalSpinMutexConfig: TSpinMutexConfig;
function HighPerformanceSpinMutexConfig: TSpinMutexConfig;
function LowLatencySpinMutexConfig: TSpinMutexConfig;

// ===== 统计辅助函数 =====
function EmptySpinMutexStats: TSpinMutexStats;
procedure ClearSpinMutexStats(var AStats: TSpinMutexStats);
function FormatSpinMutexStats(const AStats: TSpinMutexStats): string;

// ===== 前向声明 =====
type
  ISpinMutex = interface; // 前向声明

// ===== 工厂函数声明 =====
function MakeSpinMutex(const AName: string): ISpinMutex; overload;
function MakeSpinMutex(const AName: string; const AConfig: TSpinMutexConfig): ISpinMutex; overload;





type
  // 前向声明
  ISpinMutexGuard = interface;

  // ===== RAII 自旋互斥锁守卫接口 =====
  ISpinMutexGuard = interface
    ['{A8B9C0D1-E2F3-4567-8901-234567890ABC}']
    // 守卫信息
    function GetName: string;
    function GetHoldTimeUs: UInt64;
    function IsValid: Boolean;

    // 手动释放（可选，析构时自动释放）
    procedure Release;
  end;

  // ===== 现代化的自旋互斥锁接口 =====
  ISpinMutex = interface(ILock)
    ['{6F53E4F1-6B7B-4B4F-925F-0E0C7D8E1A2B}']
    // 继承自 ILock：Acquire, Release, TryAcquire, TryAcquire(timeout), GetLastError

    // ===== 配置管理 =====
    function GetConfig: TSpinMutexConfig;
    procedure UpdateConfig(const AConfig: TSpinMutexConfig);

    // ===== 现代化 RAII 接口 =====
    function Lock: ISpinMutexGuard; overload;
    function Lock(const AName: string): ISpinMutexGuard; overload;
    function TryLock: ISpinMutexGuard; overload;
    function TryLock(const AName: string): ISpinMutexGuard; overload;
    function TryLockFor(ATimeoutMs: Cardinal): ISpinMutexGuard; overload;
    function TryLockFor(ATimeoutMs: Cardinal; const AName: string): ISpinMutexGuard; overload;

    // ===== 自旋专用接口 =====
    function SpinLock: ISpinMutexGuard; overload;                    // 纯自旋，不回退到阻塞
    function SpinLock(const AName: string): ISpinMutexGuard; overload;
    function TrySpinLock(AMaxSpins: Cardinal): ISpinMutexGuard; overload;
    function TrySpinLock(AMaxSpins: Cardinal; const AName: string): ISpinMutexGuard; overload;

    // ===== 统计和监控 =====
    function GetStats: TSpinMutexStats;
    procedure ResetStats;
    function GetSpinEfficiency: Double;

    // ===== 标识和调试 =====
    function GetName: string;
    function GetOwnerThreadId: TThreadID;
    function IsLocked: Boolean;
  end;

implementation

function DefaultSpinMutexConfig: TSpinMutexConfig;
begin
  Result.MaxSpinCount := 1000;              // 1000次自旋
  Result.BackoffStrategy := sbsAdaptive;    // 自适应退避
  Result.MaxBackoffMs := 16;                // 最大16毫秒退避
  Result.DefaultTimeoutMs := 5000;          // 5秒默认超时
  Result.RetryIntervalMs := 10;             // 10毫秒重试间隔
  Result.MaxRetries := 100;                 // 最多重试100次
  Result.UseGlobalNamespace := False;       // 不使用全局命名空间
  Result.InitialOwner := False;             // 不初始拥有锁
  Result.EnableStats := False;              // 不启用统计
  Result.CacheLineAlign := True;            // 启用缓存行对齐
end;

function SpinMutexConfigWithTimeout(ATimeoutMs: Cardinal): TSpinMutexConfig;
begin
  Result := DefaultSpinMutexConfig;
  Result.DefaultTimeoutMs := ATimeoutMs;
end;

function GlobalSpinMutexConfig: TSpinMutexConfig;
begin
  Result := DefaultSpinMutexConfig;
  Result.UseGlobalNamespace := True;        // 使用全局命名空间
end;

function HighPerformanceSpinMutexConfig: TSpinMutexConfig;
begin
  Result := DefaultSpinMutexConfig;
  Result.MaxSpinCount := 2000;              // 更多自旋次数
  Result.BackoffStrategy := sbsExponential; // 指数退避
  Result.MaxBackoffMs := 8;                 // 更短退避时间
  Result.EnableStats := True;               // 启用统计以便优化
end;

function LowLatencySpinMutexConfig: TSpinMutexConfig;
begin
  Result := DefaultSpinMutexConfig;
  Result.MaxSpinCount := 500;               // 较少自旋次数
  Result.BackoffStrategy := sbsLinear;      // 线性退避
  Result.MaxBackoffMs := 4;                 // 极短退避时间
  Result.DefaultTimeoutMs := 1000;          // 更短超时
end;

// ===== 统计辅助函数实现 =====

function EmptySpinMutexStats: TSpinMutexStats;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.AvgSpinsPerAcquire := 0.0;
  Result.SpinEfficiency := 0.0;
  Result.AvgHoldTimeUs := 0.0;
  Result.MaxHoldTimeUs := 0;
  Result.ContentionRate := 0.0;
  Result.AvgBackoffTimeUs := 0.0;
end;

procedure ClearSpinMutexStats(var AStats: TSpinMutexStats);
begin
  AStats := EmptySpinMutexStats;
end;

function FormatSpinMutexStats(const AStats: TSpinMutexStats): string;
begin
  // 简化实现，避免依赖 SysUtils
  Result := 'SpinMutex Stats: [formatted output not available in base unit]';
end;

// ===== 工厂函数实现 =====

function MakeSpinMutex(const AName: string): ISpinMutex;
begin
  Result := MakeSpinMutex(AName, DefaultSpinMutexConfig);
end;

function MakeSpinMutex(const AName: string; const AConfig: TSpinMutexConfig): ISpinMutex;
begin
  // 这个函数在 fafafa.core.sync.spinMutex 主模块中实现
  // 这里只是声明，实际实现会调用平台特定的构造函数
  Result := nil;
  // 注意：这个函数不应该被直接调用，应该通过主模块的工厂函数调用
end;

end.

