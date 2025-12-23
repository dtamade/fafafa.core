unit fafafa.core.sync.namedCondvar.base;

{$mode objfpc}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.sync.condvar.base;

type
  // ===== Configuration Structure =====
  TNamedCondVarConfig = record
    TimeoutMs: Cardinal;              // Default timeout in milliseconds
    UseGlobalNamespace: Boolean;      // Whether to use global namespace
    MaxWaiters: Cardinal;             // Maximum number of waiters (for resource preallocation)
    EnableStats: Boolean;             // Whether to enable statistics
  end;

// Configuration helper functions
function DefaultNamedCondVarConfig: TNamedCondVarConfig;
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
    TotalWaitTimeUs: QWord;           // Total wait time (microseconds)
    MaxWaitTimeUs: QWord;             // Maximum single wait time (microseconds)
  end;

// Empty statistics constant
function EmptyNamedCondVarStats: TNamedCondVarStats;

type
  {**
   * INamedCondVar - 跨进程条件变量接口
   *
   * @experimental
   *   此 API 为实验性状态。Windows 平台的 Broadcast 语义
   *   在极端竞争场景下有理论风险。生产环境建议优先考虑
   *   INamedMutex + INamedEvent 组合实现类似功能。
   *}
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
  end;

implementation

function DefaultNamedCondVarConfig: TNamedCondVarConfig;
begin
  Result.TimeoutMs := 30000;          // 30 second default timeout
  Result.UseGlobalNamespace := False; // Don't use global namespace by default
  Result.MaxWaiters := 64;            // Default max 64 waiters
  Result.EnableStats := False;        // Don't enable statistics by default
end;

function NamedCondVarConfigWithTimeout(ATimeoutMs: Cardinal): TNamedCondVarConfig;
begin
  Result := DefaultNamedCondVarConfig;
  Result.TimeoutMs := ATimeoutMs;
end;

function GlobalNamedCondVarConfig: TNamedCondVarConfig;
begin
  Result := DefaultNamedCondVarConfig;
  Result.UseGlobalNamespace := True;
end;

function EmptyNamedCondVarStats: TNamedCondVarStats;
begin
  Result := Default(TNamedCondVarStats);
end;

end.
