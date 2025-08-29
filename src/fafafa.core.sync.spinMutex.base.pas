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
function HighPerformanceSpinMutexConfig: TSpinMutexConfig;
function LowLatencySpinMutexConfig: TSpinMutexConfig;

// ===== 配置转换函数 =====
function SpinMutexConfigToSpinLockPolicy(const AConfig: TSpinMutexConfig): TSpinMutexPolicy;

// ===== 工厂函数声明 =====
function MakeSpinMutex(const AName: string): ISpinMutex; overload;
function MakeSpinMutex(const AName: string; const AConfig: TSpinMutexConfig): ISpinMutex; overload;

implementation

// ===== 配置辅助函数实现 =====

function DefaultSpinMutexConfig: TSpinMutexConfig;
begin
  Result.MaxSpinCount := 64;                    // 默认64次自旋
  Result.BackoffStrategy := sbsAdaptive;        // 自适应退避
  Result.MaxBackoffMs := 16;                    // 最大16毫秒退避
  Result.DefaultTimeoutMs := 5000;              // 5秒默认超时
  Result.EnableStats := False;                  // 默认不启用统计
  Result.EnableErrorTracking := True;           // 默认启用错误跟踪
end;

function HighPerformanceSpinMutexConfig: TSpinMutexConfig;
begin
  Result := DefaultSpinMutexConfig;
  Result.MaxSpinCount := 128;                   // 更多自旋次数
  Result.BackoffStrategy := sbsExponential;     // 指数退避
  Result.MaxBackoffMs := 8;                     // 更短退避时间
  Result.EnableStats := True;                   // 启用统计以便优化
end;

function LowLatencySpinMutexConfig: TSpinMutexConfig;
begin
  Result := DefaultSpinMutexConfig;
  Result.MaxSpinCount := 32;                    // 较少自旋次数
  Result.BackoffStrategy := sbsLinear;          // 线性退避
  Result.MaxBackoffMs := 4;                     // 极短退避时间
  Result.DefaultTimeoutMs := 1000;              // 更短超时
end;

// ===== 配置转换函数实现 =====

function SpinMutexConfigToSpinLockPolicy(const AConfig: TSpinMutexConfig): TSpinMutexPolicy;
begin
  // 将 TSpinMutexConfig 转换为 TSpinLockPolicy
  Result.MaxSpins := AConfig.MaxSpinCount;
  Result.BackoffStrategy := AConfig.BackoffStrategy;
  Result.MaxBackoffMs := AConfig.MaxBackoffMs;
  Result.EnableStats := AConfig.EnableStats;
  Result.EnableErrorTracking := AConfig.EnableErrorTracking;

  // 设置其他默认值
  Result.EnableDeadlockDetection := False;              // 默认不启用死锁检测
  Result.DeadlockTimeoutMs := AConfig.DefaultTimeoutMs; // 使用默认超时
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
