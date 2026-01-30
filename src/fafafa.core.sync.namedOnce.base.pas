unit fafafa.core.sync.namedOnce.base;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.sync.base;

type
  // ===== Once 状态枚举 =====
  TNamedOnceState = (
    nosNotStarted = 0,   // 未开始
    nosInProgress = 1,   // 执行中
    nosCompleted = 2,    // 已完成
    nosPoisoned = 3      // 异常中毒
  );

  // ===== 配置结构 =====
  TNamedOnceConfig = record
    TimeoutMs: Cardinal;           // 等待超时时间（毫秒）
    UseGlobalNamespace: Boolean;   // 是否使用全局命名空间
    EnablePoisoning: Boolean;      // 是否启用中毒检测
  end;

  // ===== 执行回调类型 =====
  TOnceCallback = procedure;
  TOnceCallbackMethod = procedure of object;
  TOnceCallbackNested = procedure is nested;

  // ===== 跨进程 Once 接口 =====
  INamedOnce = interface(ISynchronizable)
    ['{D1E2F3A4-B5C6-7D8E-9F0A-1B2C3D4E5F6A}']
    // 执行一次性初始化
    procedure Execute(ACallback: TOnceCallback);
    procedure ExecuteMethod(ACallback: TOnceCallbackMethod);

    // 强制重新执行（即使已完成或中毒）
    procedure ExecuteForce(ACallback: TOnceCallback);

    // 等待执行完成
    function Wait(ATimeoutMs: Cardinal = High(Cardinal)): Boolean;

    // 状态查询
    function GetState: TNamedOnceState;
    function IsDone: Boolean;
    function IsPoisoned: Boolean;
    function GetName: string;

    // 重置（仅限创建者）
    procedure Reset;
  end;

// 配置辅助函数
function DefaultNamedOnceConfig: TNamedOnceConfig; inline;
function NamedOnceConfigWithTimeout(ATimeoutMs: Cardinal): TNamedOnceConfig; inline;
function GlobalNamedOnceConfig: TNamedOnceConfig; inline;

implementation

function DefaultNamedOnceConfig: TNamedOnceConfig;
begin
  Result.TimeoutMs := 30000;          // 30秒默认超时
  Result.UseGlobalNamespace := False;
  Result.EnablePoisoning := True;     // 默认启用中毒检测
end;

function NamedOnceConfigWithTimeout(ATimeoutMs: Cardinal): TNamedOnceConfig;
begin
  Result := DefaultNamedOnceConfig;
  Result.TimeoutMs := ATimeoutMs;
end;

function GlobalNamedOnceConfig: TNamedOnceConfig;
begin
  Result := DefaultNamedOnceConfig;
  Result.UseGlobalNamespace := True;
end;

end.
