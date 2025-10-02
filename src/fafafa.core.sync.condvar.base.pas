unit fafafa.core.sync.condvar.base;

{$mode objfpc}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.sync.base, fafafa.core.sync.mutex.base; // for ILock, IMutex

type

  ICondVar = interface(ISynchronizable)
    ['{F9CAE7D8-8A7B-4E5F-9C8D-7B6A5E4D3C2B}']
    // 绛夊緟鏂规硶 - 鎺ュ彈浠讳綍 ILock 瀹炵幇锛堝寘�?IMutex�?
    procedure Wait(const ALock: ILock); overload;
    function Wait(const ALock: ILock; ATimeoutMs: Cardinal): Boolean; overload;
    // 閫氱�?
    procedure Signal;
    procedure Broadcast;
  end;

implementation

end.


