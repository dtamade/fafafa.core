unit fafafa.core.sync.semaphore.base;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.base, fafafa.core.sync.base;

type

  // RAII 守卫：析构时自动释放指定数量的许可
  ISemaphoreGuard = interface
    ['{8B3E4A75-9C2D-4B6E-8C9F-0D1E2F3A4B5C}']
    function GetCount: Integer;
  end;

  ISemaphore = interface(ILock)
    ['{D7A8C4B5-6E5F-4C2D-9A8B-7E6D5C4B3A29}']
    // 现有 API
    procedure Acquire(ACount: Integer); overload;
    procedure Release(ACount: Integer); overload;
    function TryAcquire(ATimeoutMs: Cardinal): Boolean; overload;
    function TryAcquire(ACount: Integer): Boolean; overload;
    function TryAcquire(ACount: Integer; ATimeoutMs: Cardinal): Boolean; overload;
    function GetAvailableCount: Integer;
    function GetMaxCount: Integer;

    // RAII 友好获取：成功返回守卫，失败返回 nil（Try 系列）
    function AcquireGuard: ISemaphoreGuard; overload;
    function AcquireGuard(ACount: Integer): ISemaphoreGuard; overload;
    function TryAcquireGuard: ISemaphoreGuard; overload;
    function TryAcquireGuard(ATimeoutMs: Cardinal): ISemaphoreGuard; overload;
    function TryAcquireGuard(ACount: Integer): ISemaphoreGuard; overload;
    function TryAcquireGuard(ACount: Integer; ATimeoutMs: Cardinal): ISemaphoreGuard; overload;
  end;

implementation

end.

