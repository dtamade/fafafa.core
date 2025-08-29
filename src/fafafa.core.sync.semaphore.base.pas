unit fafafa.core.sync.semaphore.base;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.base, fafafa.core.sync.base;

type

  ISemaphore = interface(ILock)
    ['{D7A8C4B5-6E5F-4C2D-9A8B-7E6D5C4B3A29}']
    procedure Acquire(ACount: Integer); overload;
    procedure Release(ACount: Integer); overload;
    function TryAcquire(ATimeoutMs: Cardinal): Boolean; overload;
    function TryAcquire(ACount: Integer): Boolean; overload;
    function TryAcquire(ACount: Integer; ATimeoutMs: Cardinal): Boolean; overload;
    function GetAvailableCount: Integer;
    function GetMaxCount: Integer;
  end;

implementation

end.

