unit fafafa.core.sync.namedRWLock.base;

{$mode objfpc}
{$I fafafa.core.settings.inc}

interface

type
  // ===== 配置结构 =====
  TNamedRWLockConfig = record
    TimeoutMs: Cardinal;           // 默认超时时间（毫秒）
    RetryIntervalMs: Cardinal;     // 重试间隔（毫秒）
    MaxRetries: Integer;           // 最大重试次�?
    UseGlobalNamespace: Boolean;   // 是否使用全局命名空间
    InitialOwner: Boolean;         // 是否初始拥有（写锁）
    MaxReaders: Integer;           // 最大读者数量限�?
  end;

// 配置辅助函数
function DefaultNamedRWLockConfig: TNamedRWLockConfig;
function NamedRWLockConfigWithTimeout(ATimeoutMs: Cardinal): TNamedRWLockConfig;
function GlobalNamedRWLockConfig: TNamedRWLockConfig;

type
  // ===== RAII 模式的读锁守�?=====
  INamedRWLockReadGuard = interface
    ['{A1B2C3D4-5E6F-7890-ABCD-EF1234567890}']
    function GetName: string;           // 获取读写锁名�?
    // 析构时自动释放读锁，无需手动调用 Release
  end;

  // ===== RAII 模式的写锁守�?=====
  INamedRWLockWriteGuard = interface
    ['{B2C3D4E5-6F70-8901-BCDE-F12345678901}']
    function GetName: string;           // 获取读写锁名�?
    // 析构时自动释放写锁，无需手动调用 Release
  end;

  // ===== 现代化的命名读写锁接�?=====
  INamedRWLock = interface
    ['{F2A8B4C6-3D7E-4F9A-8B1C-5E6D9A2F4B8C}']
    // 核心锁操�?- 返回 RAII 守卫
    function ReadLock: INamedRWLockReadGuard;                              // 阻塞获取读锁
    function WriteLock: INamedRWLockWriteGuard;                           // 阻塞获取写锁
    function TryReadLock: INamedRWLockReadGuard;                          // 非阻塞尝试读�?
    function TryWriteLock: INamedRWLockWriteGuard;                        // 非阻塞尝试写�?
    function TryReadLockFor(ATimeoutMs: Cardinal): INamedRWLockReadGuard;  // 带超时获取读�?
    function TryWriteLockFor(ATimeoutMs: Cardinal): INamedRWLockWriteGuard; // 带超时获取写�?

    // 查询操作
    function GetName: string;           // 获取读写锁名�?

    // 状态查询方�?
    function GetReaderCount: Integer;   // 获取当前读者数�?
    function IsWriteLocked: Boolean;    // 检查是否被写锁�?
    function GetHandle: Pointer;        // 获取底层句柄（调试用�?
  end;

implementation

function DefaultNamedRWLockConfig: TNamedRWLockConfig;
begin
  Result.TimeoutMs := 5000;           // 5秒默认超�?
  Result.RetryIntervalMs := 10;       // 10毫秒重试间隔
  Result.MaxRetries := 100;           // 最多重�?00�?
  Result.UseGlobalNamespace := False; // 默认不使用全局命名空间
  Result.InitialOwner := False;       // 默认不初始拥�?
  Result.MaxReaders := 1024;          // 默认最�?024个读�?
end;

function NamedRWLockConfigWithTimeout(ATimeoutMs: Cardinal): TNamedRWLockConfig;
begin
  Result := DefaultNamedRWLockConfig;
  Result.TimeoutMs := ATimeoutMs;
end;

function GlobalNamedRWLockConfig: TNamedRWLockConfig;
begin
  Result := DefaultNamedRWLockConfig;
  Result.UseGlobalNamespace := True;
end;

end.
