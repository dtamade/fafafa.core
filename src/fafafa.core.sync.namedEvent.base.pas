unit fafafa.core.sync.namedEvent.base;

{$mode objfpc}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.sync.base;

type
  // ===== 配置结构 =====
  TNamedEventConfig = record
    TimeoutMs: Cardinal;           // 默认超时时间（毫秒）
    RetryIntervalMs: Cardinal;     // 重试间隔（毫秒）
    MaxRetries: Integer;           // 最大重试次�?
    UseGlobalNamespace: Boolean;   // 是否使用全局命名空间
    ManualReset: Boolean;          // 是否手动重置（true=手动，false=自动�?
    InitialState: Boolean;         // 初始状态（true=已触发，false=未触发）
  end;

// 配置辅助函数
function DefaultNamedEventConfig: TNamedEventConfig;
function NamedEventConfigWithTimeout(ATimeoutMs: Cardinal): TNamedEventConfig;
function GlobalNamedEventConfig: TNamedEventConfig;
function ManualResetNamedEventConfig: TNamedEventConfig;
function AutoResetNamedEventConfig: TNamedEventConfig;

type
  // ===== RAII 模式的事件等待守�?=====
  INamedEventGuard = interface
    ['{B3C4D5E6-7F8A-9B0C-1D2E-3F4A5B6C7D8E}']
    function GetName: string;           // 获取事件名称
    function IsSignaled: Boolean;       // 检查是否已触发
    // 析构时自动清理资源，无需手动调用
  end;

  // ===== 现代化的命名事件接口（简化版�?=====
  INamedEvent = interface
    ['{C5D6E7F8-9A0B-1C2D-3E4F-5A6B7C8D9E0F}']
    // 核心事件操作 - 返回 RAII 守卫
    function Wait: INamedEventGuard;                              // 阻塞等待
    function TryWait: INamedEventGuard;                          // 非阻塞尝�?
    function TryWaitFor(ATimeoutMs: Cardinal): INamedEventGuard; // 带超时等�?

    // 事件控制操作
    procedure Signal;                   // 触发事件（更直观的命名）
    procedure Reset;                    // 重置事件（仅手动重置事件有效�?
    procedure Pulse;                    // 脉冲事件（触发后立即重置�?

    // 查询操作
    function GetName: string;           // 获取事件名称
    function IsManualReset: Boolean;    // 是否手动重置事件
    function IsSignaled: Boolean;       // 当前是否已触�?

    // 错误状态查�?
    function GetLastError: TWaitError;  // 获取最后的错误状�?
  end;

implementation

function DefaultNamedEventConfig: TNamedEventConfig;
begin
  Result.TimeoutMs := 5000;           // 5秒默认超�?
  Result.RetryIntervalMs := 10;       // 10毫秒重试间隔
  Result.MaxRetries := 100;           // 最多重�?00�?
  Result.UseGlobalNamespace := False; // 默认不使用全局命名空间
  Result.ManualReset := False;        // 默认自动重置
  Result.InitialState := False;       // 默认未触发状�?
end;

function NamedEventConfigWithTimeout(ATimeoutMs: Cardinal): TNamedEventConfig;
begin
  Result := DefaultNamedEventConfig;
  Result.TimeoutMs := ATimeoutMs;
end;

function GlobalNamedEventConfig: TNamedEventConfig;
begin
  Result := DefaultNamedEventConfig;
  Result.UseGlobalNamespace := True;
end;

function ManualResetNamedEventConfig: TNamedEventConfig;
begin
  Result := DefaultNamedEventConfig;
  Result.ManualReset := True;
end;

function AutoResetNamedEventConfig: TNamedEventConfig;
begin
  Result := DefaultNamedEventConfig;
  Result.ManualReset := False;
end;

end.
