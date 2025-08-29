unit fafafa.core.sync.namedEvent;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.sync.base, fafafa.core.sync.namedEvent.base
  {$IFDEF WINDOWS}, fafafa.core.sync.namedEvent.windows{$ENDIF}
  {$IFDEF UNIX},    fafafa.core.sync.namedEvent.unix{$ENDIF};

type
  // 公开接口类型 - 完全隐藏平台差异
  INamedEventGuard = fafafa.core.sync.namedEvent.base.INamedEventGuard;
  INamedEvent = fafafa.core.sync.namedEvent.base.INamedEvent;
  TNamedEventConfig = fafafa.core.sync.namedEvent.base.TNamedEventConfig;

  // 注意：TNamedEvent 具体类型不再公开导出
  // 用户应该只使用 INamedEvent 接口和工厂函数

// ===== 简化的工厂函数（遵循主流框架设计原则） =====

{ 创建命名事件 - 主要工厂函数 }
function CreateNamedEvent(const AName: string; AManualReset: Boolean = False; AInitialState: Boolean = False): INamedEvent;

{ 创建全局命名事件（跨会话共享） }
function CreateGlobalNamedEvent(const AName: string; AManualReset: Boolean = False; AInitialState: Boolean = False): INamedEvent;

{ 创建命名事件 - 高级配置版本 }
function CreateNamedEventWithConfig(const AName: string; const AConfig: TNamedEventConfig): INamedEvent;



// ===== 配置辅助函数（重新导出） =====
function DefaultNamedEventConfig: TNamedEventConfig;
function NamedEventConfigWithTimeout(ATimeoutMs: Cardinal): TNamedEventConfig;
function GlobalNamedEventConfig: TNamedEventConfig;
function ManualResetNamedEventConfig: TNamedEventConfig;
function AutoResetNamedEventConfig: TNamedEventConfig;

implementation

function CreateNamedEventWithConfig(const AName: string; const AConfig: TNamedEventConfig): INamedEvent;
var
  LActualName: string;
begin
  // 处理全局命名空间（平台特定逻辑内部化）
  LActualName := AName;
  {$IFDEF WINDOWS}
  if AConfig.UseGlobalNamespace and (Pos('Global\', AName) <> 1) then
    LActualName := 'Global\' + AName;
  {$ENDIF}
  {$IFDEF UNIX}
  // Unix 平台：命名事件默认就是全局的，无需特殊处理
  {$ENDIF}

  // 创建平台特定实例（完全隐藏实现细节）
  {$IFDEF UNIX}
  Result := fafafa.core.sync.namedEvent.unix.TNamedEvent.Create(LActualName, AConfig);
  {$ENDIF}
  {$IFDEF WINDOWS}
  Result := fafafa.core.sync.namedEvent.windows.TNamedEvent.Create(LActualName, AConfig);
  {$ENDIF}
end;

function CreateNamedEvent(const AName: string; AManualReset: Boolean; AInitialState: Boolean): INamedEvent;
var
  LConfig: TNamedEventConfig;
begin
  LConfig := DefaultNamedEventConfig;
  LConfig.ManualReset := AManualReset;
  LConfig.InitialState := AInitialState;
  Result := CreateNamedEventWithConfig(AName, LConfig);
end;

function CreateGlobalNamedEvent(const AName: string; AManualReset: Boolean; AInitialState: Boolean): INamedEvent;
var
  LConfig: TNamedEventConfig;
begin
  LConfig := GlobalNamedEventConfig;
  LConfig.ManualReset := AManualReset;
  LConfig.InitialState := AInitialState;
  Result := CreateNamedEventWithConfig(AName, LConfig);
end;



// 配置辅助函数（重新导出）
function DefaultNamedEventConfig: TNamedEventConfig;
begin
  Result := fafafa.core.sync.namedEvent.base.DefaultNamedEventConfig;
end;

function NamedEventConfigWithTimeout(ATimeoutMs: Cardinal): TNamedEventConfig;
begin
  Result := fafafa.core.sync.namedEvent.base.NamedEventConfigWithTimeout(ATimeoutMs);
end;

function GlobalNamedEventConfig: TNamedEventConfig;
begin
  Result := fafafa.core.sync.namedEvent.base.GlobalNamedEventConfig;
end;

function ManualResetNamedEventConfig: TNamedEventConfig;
begin
  Result := fafafa.core.sync.namedEvent.base.ManualResetNamedEventConfig;
end;

function AutoResetNamedEventConfig: TNamedEventConfig;
begin
  Result := fafafa.core.sync.namedEvent.base.AutoResetNamedEventConfig;
end;

end.
