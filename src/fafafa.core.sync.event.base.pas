unit fafafa.core.sync.event.base;

{$mode objfpc}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.sync.base;

type
  // ===== Event Interface =====
  IEvent = interface(ISynchronizable)
    ['{7B8C9D0E-1F2A-3B4C-5D6E-7A8B9C0D1E2F}']
    
    // Set the event to signaled state
    procedure SetEvent;
    
    // Reset the event to non-signaled state (for manual reset events)
    procedure ResetEvent;
    
    // Alias for SetEvent - cross-platform naming convention
    procedure Signal;
    
    // Alias for ResetEvent - cross-platform naming convention  
    procedure Clear;
    
    // Wait for the event to become signaled
    function Wait: TWaitResult; overload;
    function WaitFor: TWaitResult; overload;
    function WaitFor(ATimeoutMs: Cardinal): TWaitResult; overload;
    
    // Non-blocking check with zero timeout
    function TryWait: Boolean;
    
    // Check if the event is currently signaled
    function IsSignaled: Boolean;
    
    // Get event properties
    function IsManualReset: Boolean;
  end;

implementation

end.
