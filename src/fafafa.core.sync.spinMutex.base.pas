unit fafafa.core.sync.spinMutex.base;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.base, fafafa.core.sync.base;

type
  // ===== 自旋退避策略 =====
  TSpinBackoffStrategy = (
    sbsNone,        // 无退避，纯自旋
    sbsLinear,      // 线性退避
    sbsExponential, // 指数退避
    sbsAdaptive     // 自适应退避（默认）
  );

  // ===== 自旋互斥锁配置结构 =====
  TSpinMutexConfig = record
    // 自旋策略配置
    MaxSpinCount: Cardinal;               // 最大自旋次数（默认：1000）
    BackoffStrategy: TSpinBackoffStrategy; // 退避策略（默认：自适应）
    MaxBackoffMs: Cardinal;               // 最大退避时间毫秒（默认：16）

    // 超时和重试配置
    DefaultTimeoutMs: Cardinal;           // 默认超时时间（毫秒，默认：5000）
    RetryIntervalMs: Cardinal;            // 重试间隔（毫秒，默认：10）
    MaxRetries: Integer;                  // 最大重试次数（默认：100）




  end;





// 配置辅助函数
function DefaultSpinMutexConfig: TSpinMutexConfig;
function SpinMutexConfigWithTimeout(ATimeoutMs: Cardinal): TSpinMutexConfig;
function GlobalSpinMutexConfig: TSpinMutexConfig;
function HighPerformanceSpinMutexConfig: TSpinMutexConfig;
function LowLatencySpinMutexConfig: TSpinMutexConfig;





type


  // ===== 现代化的命名自旋互斥锁接口 =====
  ISpinMutex = interface(ILock)
    ['{6F53E4F1-6B7B-4B4F-925F-0E0C7D8E1A2B}']
    // 继承自 ILock：Acquire, Release, TryAcquire, TryAcquire(timeout), GetLastError
    // 自旋互斥锁：先自旋尝试，失败后阻塞等待
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

end;

function SpinMutexConfigWithTimeout(ATimeoutMs: Cardinal): TSpinMutexConfig;
begin
  Result := DefaultSpinMutexConfig;
  Result.DefaultTimeoutMs := ATimeoutMs;
end;

function GlobalSpinMutexConfig: TSpinMutexConfig;
begin
  Result := DefaultSpinMutexConfig;

end;

function HighPerformanceSpinMutexConfig: TSpinMutexConfig;
begin
  Result := DefaultSpinMutexConfig;
  Result.MaxSpinCount := 2000;              // 更多自旋次数
  Result.BackoffStrategy := sbsExponential; // 指数退避
  Result.MaxBackoffMs := 8;                 // 更短退避时间
end;

function LowLatencySpinMutexConfig: TSpinMutexConfig;
begin
  Result := DefaultSpinMutexConfig;
  Result.MaxSpinCount := 500;               // 较少自旋次数
  Result.BackoffStrategy := sbsLinear;      // 线性退避
  Result.MaxBackoffMs := 4;                 // 极短退避时间
  Result.DefaultTimeoutMs := 1000;          // 更短超时

end;



end.

