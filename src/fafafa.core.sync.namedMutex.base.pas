unit fafafa.core.sync.namedMutex.base;

{$mode objfpc}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.sync.base;

type
  // ===== 配置结构 =====
  TNamedMutexConfig = record
    TimeoutMs: Cardinal;           // 默认超时时间（毫秒）
    RetryIntervalMs: Cardinal;     // 重试间隔（毫秒）
    MaxRetries: Integer;           // 最大重试次�?
    UseGlobalNamespace: Boolean;   // 是否使用全局命名空间
    InitialOwner: Boolean;         // 是否初始拥有
  end;

// 配置辅助函数
function DefaultNamedMutexConfig: TNamedMutexConfig;
function NamedMutexConfigWithTimeout(ATimeoutMs: Cardinal): TNamedMutexConfig;
function GlobalNamedMutexConfig: TNamedMutexConfig;

type
  // ===== RAII 模式的互斥锁守卫 =====
  INamedMutexGuard = interface(ILockGuard)
    ['{A1B2C3D4-5E6F-7890-ABCD-EF1234567890}']
    function GetName: string;           // 获取互斥锁名称
    // 析构时自动释放锁，无需手动调用 Release
  end;

  // ===== 现代化的命名互斥锁接口 =====
  // 注意：使用 LockNamed/TryLockNamed 避免与父接口 ILock 的方法签名冲突
  INamedMutex = interface(ILock)
    ['{F2A8B4C6-3D7E-4F9A-8B1C-5E6D9A2F4B8C}']
    // 核心锁操作 - 返回 RAII 守卫（带名称信息）
    function LockNamed: INamedMutexGuard;                              // 阻塞获取
    function TryLockNamed: INamedMutexGuard;                          // 非阻塞尝试
    function TryLockForNamed(ATimeoutMs: Cardinal): INamedMutexGuard; // 带超时获取

    // 查询操作
    function GetName: string;           // 获取互斥锁名称
    function GetHandle: Pointer;        // 获取底层互斥锁句柄（供 NamedCondVar 使用）
  end;

implementation

function DefaultNamedMutexConfig: TNamedMutexConfig;
begin
  Result.TimeoutMs := 5000;           // 5秒默认超�?
  Result.RetryIntervalMs := 10;       // 10毫秒重试间隔
  Result.MaxRetries := 100;           // 最多重�?00�?
  Result.UseGlobalNamespace := False; // 默认不使用全局命名空间
  Result.InitialOwner := False;       // 默认不初始拥�?
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
