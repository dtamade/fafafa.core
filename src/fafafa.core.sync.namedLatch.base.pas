unit fafafa.core.sync.namedLatch.base;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.sync.base;

type
  // ===== Latch 配置 =====
  TNamedLatchConfig = record
    TimeoutMs: Cardinal;           // 等待超时时间（毫秒）
    UseGlobalNamespace: Boolean;   // 是否使用全局命名空间
  end;

  // ===== 跨进程 Latch 接口 =====
  INamedLatch = interface(ISynchronizable)
    ['{E2F3A4B5-C6D7-8E9F-0A1B-2C3D4E5F6A7B}']
    // 减少计数
    procedure CountDown;
    procedure CountDownBy(ACount: Cardinal);

    // 等待计数归零
    function Wait(ATimeoutMs: Cardinal = High(Cardinal)): Boolean;
    function TryWait: Boolean;

    // 状态查询
    function GetCount: Cardinal;
    function IsOpen: Boolean;
    function GetName: string;
  end;

// 配置辅助函数
function DefaultNamedLatchConfig: TNamedLatchConfig; inline;
function NamedLatchConfigWithTimeout(ATimeoutMs: Cardinal): TNamedLatchConfig; inline;
function GlobalNamedLatchConfig: TNamedLatchConfig; inline;

implementation

function DefaultNamedLatchConfig: TNamedLatchConfig;
begin
  Result.TimeoutMs := 30000;          // 30秒默认超时
  Result.UseGlobalNamespace := False;
end;

function NamedLatchConfigWithTimeout(ATimeoutMs: Cardinal): TNamedLatchConfig;
begin
  Result := DefaultNamedLatchConfig;
  Result.TimeoutMs := ATimeoutMs;
end;

function GlobalNamedLatchConfig: TNamedLatchConfig;
begin
  Result := DefaultNamedLatchConfig;
  Result.UseGlobalNamespace := True;
end;

end.
