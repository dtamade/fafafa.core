unit fafafa.core.sync.namedConditionVariable.base;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.base, fafafa.core.sync.base, fafafa.core.sync.conditionVariable.base;

type
  // ===== 配置结构 =====
  TNamedConditionVariableConfig = record
    TimeoutMs: Cardinal;              // 默认超时时间（毫秒）
    UseGlobalNamespace: Boolean;      // 是否使用全局命名空间
    MaxWaiters: Cardinal;             // 最大等待者数量（用于资源预分配）
    EnableStats: Boolean;             // 是否启用统计信息
  end;

// 配置辅助函数
function DefaultNamedConditionVariableConfig: TNamedConditionVariableConfig;
function NamedConditionVariableConfigWithTimeout(ATimeoutMs: Cardinal): TNamedConditionVariableConfig;
function GlobalNamedConditionVariableConfig: TNamedConditionVariableConfig;

type
  // ===== 统计信息结构 =====
  TNamedConditionVariableStats = record
    WaitCount: QWord;                 // 总等待次数
    SignalCount: QWord;               // 总信号次数
    BroadcastCount: QWord;            // 总广播次数
    TimeoutCount: QWord;              // 超时次数
    CurrentWaiters: Integer;          // 当前等待者数量
    MaxWaiters: Integer;              // 历史最大等待者数量
    TotalWaitTimeUs: QWord;           // 总等待时间（微秒）
    MaxWaitTimeUs: QWord;             // 最大单次等待时间（微秒）
  end;

// 空统计信息常量
function EmptyNamedConditionVariableStats: TNamedConditionVariableStats;

type
  // ===== 命名条件变量接口 =====
  INamedConditionVariable = interface(IConditionVariable)
    ['{D4E5F6A7-8B9C-1DEF-2345-6789ABCDEF01}']

    // 继承自 IConditionVariable 的方法：
    // procedure Wait(const ALock: ILock); overload;
    // function Wait(const ALock: ILock; ATimeoutMs: Cardinal): Boolean; overload;
    // procedure Signal;
    // procedure Broadcast;
    // procedure Acquire; (来自 ILock，保护条件变量内部状态)
    // procedure Release;
    // function TryAcquire: Boolean; overload;
    // function TryAcquire(ATimeoutMs: Cardinal): Boolean; overload;
    // function GetLastError: TWaitError; (来自 ISynchronizable)

    // 命名条件变量特有的方法
    function GetName: string;                                                   // 获取条件变量名称
    function GetConfig: TNamedConditionVariableConfig;                          // 获取当前配置
    procedure UpdateConfig(const AConfig: TNamedConditionVariableConfig);       // 更新配置

    // 统计信息（如果启用）
    function GetStats: TNamedConditionVariableStats;                            // 获取统计信息
    procedure ResetStats;                                                       // 重置统计信息

    // 兼容性方法（向后兼容，但不推荐使用）
    function GetHandle: Pointer; deprecated 'Implementation detail';
    function IsCreator: Boolean; deprecated 'Implementation detail';
  end;

implementation

function DefaultNamedConditionVariableConfig: TNamedConditionVariableConfig;
begin
  Result.TimeoutMs := 30000;          // 30秒默认超时
  Result.UseGlobalNamespace := False; // 默认不使用全局命名空间
  Result.MaxWaiters := 64;            // 默认最大64个等待者
  Result.EnableStats := False;        // 默认不启用统计
end;

function NamedConditionVariableConfigWithTimeout(ATimeoutMs: Cardinal): TNamedConditionVariableConfig;
begin
  Result := DefaultNamedConditionVariableConfig;
  Result.TimeoutMs := ATimeoutMs;
end;

function GlobalNamedConditionVariableConfig: TNamedConditionVariableConfig;
begin
  Result := DefaultNamedConditionVariableConfig;
  Result.UseGlobalNamespace := True;
end;

function EmptyNamedConditionVariableStats: TNamedConditionVariableStats;
begin
  FillChar(Result, SizeOf(Result), 0);
end;

end.
