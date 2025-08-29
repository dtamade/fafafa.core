unit fafafa.core.sync.namedConditionVariable;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.sync.base, fafafa.core.sync.conditionVariable.base, 
  fafafa.core.sync.namedConditionVariable.base
  {$IFDEF WINDOWS}, fafafa.core.sync.namedConditionVariable.windows{$ENDIF}
  {$IFDEF UNIX},    fafafa.core.sync.namedConditionVariable.unix{$ENDIF};

type
  // 公开接口类型 - 完全隐藏平台差异
  INamedConditionVariable = fafafa.core.sync.namedConditionVariable.base.INamedConditionVariable;
  TNamedConditionVariableConfig = fafafa.core.sync.namedConditionVariable.base.TNamedConditionVariableConfig;
  TNamedConditionVariableStats = fafafa.core.sync.namedConditionVariable.base.TNamedConditionVariableStats;

  // 注意：TNamedConditionVariable 具体类型不再公开导出
  // 用户应该只使用 INamedConditionVariable 接口和工厂函数

// ===== 工厂函数（仅使用 MakeXXX 模式） =====

// 主要工厂函数
function MakeNamedConditionVariable(const AName: string): INamedConditionVariable; overload;
function MakeNamedConditionVariable(const AName: string; const AConfig: TNamedConditionVariableConfig): INamedConditionVariable; overload;

// 便利工厂函数
function MakeGlobalNamedConditionVariable(const AName: string): INamedConditionVariable;
function MakeNamedConditionVariableWithTimeout(const AName: string; ATimeoutMs: Cardinal): INamedConditionVariable;
function MakeNamedConditionVariableWithStats(const AName: string): INamedConditionVariable;

// 尝试打开现有的命名条件变量
function TryOpenNamedConditionVariable(const AName: string): INamedConditionVariable;

// ===== 配置辅助函数（重新导出） =====
function DefaultNamedConditionVariableConfig: TNamedConditionVariableConfig;
function NamedConditionVariableConfigWithTimeout(ATimeoutMs: Cardinal): TNamedConditionVariableConfig;
function GlobalNamedConditionVariableConfig: TNamedConditionVariableConfig;
function EmptyNamedConditionVariableStats: TNamedConditionVariableStats;

implementation

// ===== 工厂函数实现 =====

function MakeNamedConditionVariable(const AName: string): INamedConditionVariable;
begin
  Result := MakeNamedConditionVariable(AName, DefaultNamedConditionVariableConfig);
end;

function MakeNamedConditionVariable(const AName: string; const AConfig: TNamedConditionVariableConfig): INamedConditionVariable;
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
  // Unix 平台：命名条件变量默认就是全局的，无需特殊处理
  {$ENDIF}

  // 创建平台特定实例（完全隐藏实现细节）
  {$IFDEF UNIX}
  Result := fafafa.core.sync.namedConditionVariable.unix.TNamedConditionVariable.Create(LActualName, AConfig);
  {$ENDIF}
  {$IFDEF WINDOWS}
  Result := fafafa.core.sync.namedConditionVariable.windows.TNamedConditionVariable.Create(LActualName, AConfig);
  {$ENDIF}
end;

function MakeGlobalNamedConditionVariable(const AName: string): INamedConditionVariable;
begin
  Result := MakeNamedConditionVariable(AName, GlobalNamedConditionVariableConfig);
end;

function MakeNamedConditionVariableWithTimeout(const AName: string; ATimeoutMs: Cardinal): INamedConditionVariable;
begin
  Result := MakeNamedConditionVariable(AName, NamedConditionVariableConfigWithTimeout(ATimeoutMs));
end;

function MakeNamedConditionVariableWithStats(const AName: string): INamedConditionVariable;
var
  LConfig: TNamedConditionVariableConfig;
begin
  LConfig := DefaultNamedConditionVariableConfig;
  LConfig.EnableStats := True;
  Result := MakeNamedConditionVariable(AName, LConfig);
end;

function TryOpenNamedConditionVariable(const AName: string): INamedConditionVariable;
begin
  // 尝试打开现有的命名条件变量
  // 实际上与 MakeNamedConditionVariable 相同，因为底层实现会自动处理创建/打开逻辑
  Result := MakeNamedConditionVariable(AName);
end;

// ===== 配置辅助函数（重新导出） =====

function DefaultNamedConditionVariableConfig: TNamedConditionVariableConfig;
begin
  Result := fafafa.core.sync.namedConditionVariable.base.DefaultNamedConditionVariableConfig;
end;

function NamedConditionVariableConfigWithTimeout(ATimeoutMs: Cardinal): TNamedConditionVariableConfig;
begin
  Result := fafafa.core.sync.namedConditionVariable.base.NamedConditionVariableConfigWithTimeout(ATimeoutMs);
end;

function GlobalNamedConditionVariableConfig: TNamedConditionVariableConfig;
begin
  Result := fafafa.core.sync.namedConditionVariable.base.GlobalNamedConditionVariableConfig;
end;

function EmptyNamedConditionVariableStats: TNamedConditionVariableStats;
begin
  Result := fafafa.core.sync.namedConditionVariable.base.EmptyNamedConditionVariableStats;
end;

end.
