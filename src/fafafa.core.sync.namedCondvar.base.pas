unit fafafa.core.sync.namedCondvar.base;

{$mode objfpc}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.base, fafafa.core.sync.base, fafafa.core.sync.condvar.base;

type
  // ===== Configuration Structure =====
  TNamedCondVarConfig = record
    TimeoutMs: Cardinal;              // Default timeout in milliseconds
    UseGlobalNamespace: Boolean;      // Whether to use global namespace
    MaxWaiters: Cardinal;             // Maximum number of waiters (for resource preallocation)
    EnableStats: Boolean;             // Whether to enable statistics
  end;

// Configuration helper functions
function DefaulTNamedCondVarConfig: TNamedCondVarConfig;
function NamedCondVarConfigWithTimeout(ATimeoutMs: Cardinal): TNamedCondVarConfig;
function GlobalNamedCondVarConfig: TNamedCondVarConfig;

type
  // ===== Statistics Structure =====
  TNamedCondVarStats = record
    WaitCount: QWord;                 // Total wait count
    SignalCount: QWord;               // Total signal count
    BroadcastCount: QWord;            // Total broadcast count
    TimeoutCount: QWord;              // Timeout count
    SuccessfulWaits: QWord;           // Successful wait count
    WakeupCount: QWord;               // Wake up count
    CurrentWaiters: Integer;          // Current number of waiters
    MaxWaiters: Integer;              // Historical maximum waiters
    TotalWaitTime: QWord;             // Total wait time (milliseconds)
    MaxWaitTimeUs: QWord;             // Maximum single wait time (microseconds)
  end;

// Empty statistics constant
function EmptyNamedCondVarStats: TNamedCondVarStats;

type
  // ===== Named Condition Variable Interface =====
  INamedCondVar = interface(ICondVar)
    ['{D4E5F6A7-8B9C-1DEF-2345-6789ABCDEF01}']

    // Inherited from ICondVar:
    // procedure Wait(const ALock: ILock); overload;
    // function Wait(const ALock: ILock; ATimeoutMs: Cardinal): Boolean; overload;
    // procedure Signal;
    // procedure Broadcast;
    // procedure Lock; (from ILock, protects condition variable internal state)
    // procedure Unlock;
    // function TryLock: Boolean; overload;
    // function TryLockFor(ATimeoutMs: Cardinal): Boolean; overload;
    // function GetLastError: TWaitError; (from ISynchronizable)

    // Named condition variable specific methods
    function GetName: string;                                         // Get condition variable name
    function GetConfig: TNamedCondVarConfig;                          // Get current configuration
    procedure UpdateConfig(const AConfig: TNamedCondVarConfig);       // Update configuration

    // Statistics (if enabled)
    function GetStats: TNamedCondVarStats;                            // Get statistics
    procedure ResetStats;                                             // Reset statistics

    // Compatibility methods (backward compatible, but deprecated)
    function GetHandle: Pointer; deprecated 'Implementation detail';
    function IsCreator: Boolean; deprecated 'Implementation detail';
  end;

implementation

function DefaulTNamedCondVarConfig: TNamedCondVarConfig;
begin
  Result.TimeoutMs := 30000;          // 30 second default timeout
  Result.UseGlobalNamespace := False; // Don't use global namespace by default
  Result.MaxWaiters := 64;            // Default max 64 waiters
  Result.EnableStats := False;        // Don't enable statistics by default
end;

function NamedCondVarConfigWithTimeout(ATimeoutMs: Cardinal): TNamedCondVarConfig;
begin
  Result := DefaulTNamedCondVarConfig;
  Result.TimeoutMs := ATimeoutMs;
end;

function GlobalNamedCondVarConfig: TNamedCondVarConfig;
begin
  Result := DefaulTNamedCondVarConfig;
  Result.UseGlobalNamespace := True;
end;

function EmptyNamedCondVarStats: TNamedCondVarStats;
begin
  FillChar(Result, SizeOf(Result), 0);
end;

end.
