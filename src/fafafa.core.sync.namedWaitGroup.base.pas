unit fafafa.core.sync.namedWaitGroup.base;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.sync.base;

type
  // ===== WaitGroup 配置 =====
  TNamedWaitGroupConfig = record
    TimeoutMs: Cardinal;           // 等待超时时间（毫秒）
    UseGlobalNamespace: Boolean;   // 是否使用全局命名空间
  end;

  // ===== 跨进程 WaitGroup 接口 =====
  INamedWaitGroup = interface(ISynchronizable)
    ['{F3A4B5C6-D7E8-9F0A-1B2C-3D4E5F6A7B8C}']
    // 增加计数
    procedure Add(ACount: Cardinal = 1);

    // 减少计数（完成一个任务）
    procedure Done;

    // 等待计数归零
    function Wait(ATimeoutMs: Cardinal = High(Cardinal)): Boolean;

    // 状态查询
    function GetCount: Cardinal;
    function IsZero: Boolean;
    function GetName: string;
  end;

// 配置辅助函数
function DefaultNamedWaitGroupConfig: TNamedWaitGroupConfig; inline;
function NamedWaitGroupConfigWithTimeout(ATimeoutMs: Cardinal): TNamedWaitGroupConfig; inline;
function GlobalNamedWaitGroupConfig: TNamedWaitGroupConfig; inline;

implementation

function DefaultNamedWaitGroupConfig: TNamedWaitGroupConfig;
begin
  Result.TimeoutMs := 30000;          // 30秒默认超时
  Result.UseGlobalNamespace := False;
end;

function NamedWaitGroupConfigWithTimeout(ATimeoutMs: Cardinal): TNamedWaitGroupConfig;
begin
  Result := DefaultNamedWaitGroupConfig;
  Result.TimeoutMs := ATimeoutMs;
end;

function GlobalNamedWaitGroupConfig: TNamedWaitGroupConfig;
begin
  Result := DefaultNamedWaitGroupConfig;
  Result.UseGlobalNamespace := True;
end;

end.
