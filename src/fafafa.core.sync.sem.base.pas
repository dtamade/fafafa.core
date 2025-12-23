unit fafafa.core.sync.sem.base;

{$mode objfpc}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.sync.base;

type

  // RAII 守卫：析构时自动释放指定数量的许�?
  ISemGuard = interface(ILockGuard)
    ['{8B3E4A75-9C2D-4B6E-8C9F-0D1E2F3A4B5C}']
    function GetCount: Integer;  // 获取持有的许可数�?
    // 继承 ILockGuard.Release - 手动释放许可
  end;

  // 按照 spin 的范式：扩展 ITryLock，继承基础 Acquire/Release/TryAcquire 接口
  ISem = interface(ITryLock)
    ['{D7A8C4B5-6E5F-4C2D-9A8B-7E6D5C4B3A29}']
    // 计数信号量特有的扩展 API
    procedure Acquire(ACount: Integer); overload;
    procedure Release(ACount: Integer); overload;
    function TryAcquire(ACount: Integer): Boolean; overload;
    function TryAcquire(ACount: Integer; ATimeoutMs: Cardinal): Boolean; overload;
    function TryRelease: Boolean; overload;
    function TryRelease(ACount: Integer): Boolean; overload;
    function GetAvailableCount: Integer;
    function GetMaxCount: Integer;

    // RAII 友好获取：成功返回守卫，失败返回 nil（Try 系列�?
    function AcquireGuard: ISemGuard; overload;                     // 1 permit
    function AcquireGuard(ACount: Integer): ISemGuard; overload;    // ACount permits
    function TryAcquireGuard: ISemGuard; overload;                  // 0ms
    function TryAcquireGuard(ATimeoutMs: Cardinal): ISemGuard; overload; // 1 permit + timeout
    function TryAcquireGuard(ACount: Integer): ISemGuard; overload;
    function TryAcquireGuard(ACount: Integer; ATimeoutMs: Cardinal): ISemGuard; overload;
  end;

implementation

end.

