unit fafafa.core.sync.namedMutex.base;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.base, fafafa.core.sync.base, fafafa.core.sync.mutex.base;

type
  // ===== 配置结构 =====
  TNamedMutexConfig = record
    TimeoutMs: Cardinal;           // 默认超时时间（毫秒）
    RetryIntervalMs: Cardinal;     // 重试间隔（毫秒）
    MaxRetries: Integer;           // 最大重试次数
    UseGlobalNamespace: Boolean;   // 是否使用全局命名空间
    InitialOwner: Boolean;         // 是否初始拥有
  end;

// 配置辅助函数
function DefaultNamedMutexConfig: TNamedMutexConfig;
function NamedMutexConfigWithTimeout(ATimeoutMs: Cardinal): TNamedMutexConfig;
function GlobalNamedMutexConfig: TNamedMutexConfig;

type
  // ===== RAII 模式的互斥锁守卫 =====
  INamedMutexGuard = interface
    ['{A1B2C3D4-5E6F-7890-ABCD-EF1234567890}']
    function GetName: string;           // 获取互斥锁名称
    // 析构时自动释放锁，无需手动调用 Release
  end;

  // ===== 现代化的命名互斥锁接口 =====
  INamedMutex = interface(ILock)
    ['{F2A8B4C6-3D7E-4F9A-8B1C-5E6D9A2F4B8C}']
    // 核心锁操作 - 返回 RAII 守卫
    function Lock: INamedMutexGuard;                              // 阻塞获取
    function TryLock: INamedMutexGuard;                          // 非阻塞尝试
    function TryLockFor(ATimeoutMs: Cardinal): INamedMutexGuard; // 带超时获取

    // 查询操作
    function GetName: string;           // 获取互斥锁名称

    // 兼容性方法（向后兼容，但不推荐使用）
    procedure Acquire; deprecated 'Use Lock() instead';
    procedure Release; deprecated 'Use RAII pattern with Lock()';
    function TryAcquire: Boolean; deprecated 'Use TryLock() instead';
    function TryAcquire(ATimeoutMs: Cardinal): Boolean; overload; deprecated 'Use TryLockFor() instead';
    procedure Acquire(ATimeoutMs: Cardinal); overload; deprecated 'Use TryLockFor() instead';
    function GetHandle: Pointer; deprecated 'Implementation detail';
    function IsCreator: Boolean; deprecated 'Implementation detail';
    function IsAbandoned: Boolean; deprecated 'Not supported on all platforms';
  end;

implementation

function DefaultNamedMutexConfig: TNamedMutexConfig;
begin
  Result.TimeoutMs := 5000;           // 5秒默认超时
  Result.RetryIntervalMs := 10;       // 10毫秒重试间隔
  Result.MaxRetries := 100;           // 最多重试100次
  Result.UseGlobalNamespace := False; // 默认不使用全局命名空间
  Result.InitialOwner := False;       // 默认不初始拥有
end;

function NamedMutexConfigWithTimeout(ATimeoutMs: Cardinal): TNamedMutexConfig;
begin
  Result := DefaultNamedMutexConfig;
  Result.TimeoutMs := ATimeoutMs;
end;

function GlobalNamedMutexConfig: TNamedMutexConfig;
begin
  Result := DefaultNamedMutexConfig;
  Result.UseGlobalNamespace := True;
end;

end.
