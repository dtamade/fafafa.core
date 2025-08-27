unit fafafa.core.sync.event.base;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.sync.base;

type
  // 事件接口（独立定义于 event.base），并继承 ILock
  IEvent = interface(ILock)
    ['{E8B9D5C6-7F6A-4D3E-8B9C-6A5D4E3F2B18}']
    procedure SetEvent;
    procedure ResetEvent;
    function WaitFor: TWaitResult; overload;
    function WaitFor(ATimeoutMs: Cardinal): TWaitResult; overload;
    function IsSignaled: Boolean;
  end;

implementation

end.
