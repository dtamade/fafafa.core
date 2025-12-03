unit fafafa.core.sync.namedCondvar;

{$mode objfpc}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.sync.base, fafafa.core.sync.condvar.base, 
  fafafa.core.sync.namedCondvar.base
  {$IFDEF WINDOWS}, fafafa.core.sync.namedCondvar.windows{$ENDIF}
  {$IFDEF UNIX},    fafafa.core.sync.namedCondvar.unix{$ENDIF};

type
  // 公开接口类型 - 完全隐藏平台差异
  INamedCondVar = fafafa.core.sync.namedCondvar.base.INamedCondVar;
  TNamedCondVarConfig = fafafa.core.sync.namedCondvar.base.TNamedCondVarConfig;
  TNamedCondVarStats = fafafa.core.sync.namedCondvar.base.TNamedCondVarStats;

  // 注意：TNamedCondVar 具体类型不再公开导出
  // 用户应该只使�?INamedCondVar 接口和工厂函�?

// ===== 工厂函数（仅使用 MakeXXX 模式�?=====

// 主要工厂函数
function MakeNamedCondVar(const AName: string): INamedCondVar; overload;
function MakeNamedCondVar(const AName: string; const AConfig: TNamedCondVarConfig): INamedCondVar; overload;

// 便利工厂函数
function MakeGlobalNamedCondVar(const AName: string): INamedCondVar;
function MakeNamedCondVarWithTimeout(const AName: string; ATimeoutMs: Cardinal): INamedCondVar;
function MakeNamedCondVarWithStats(const AName: string): INamedCondVar;

// 尝试打开现有的命名条件变�?
function TryOpenNamedCondVar(const AName: string): INamedCondVar;

// ===== 配置辅助函数（重新导出） =====
function DefaultNamedCondVarConfig: TNamedCondVarConfig;
function NamedCondVarConfigWithTimeout(ATimeoutMs: Cardinal): TNamedCondVarConfig;
function GlobalNamedCondVarConfig: TNamedCondVarConfig;
function EmptyNamedCondVarStats: TNamedCondVarStats;

implementation

// ===== 工厂函数实现 =====

function MakeNamedCondVar(const AName: string): INamedCondVar;
begin
  Result := MakeNamedCondVar(AName, DefaultNamedCondVarConfig);
end;

function MakeNamedCondVar(const AName: string; const AConfig: TNamedCondVarConfig): INamedCondVar;
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
  Result := fafafa.core.sync.namedCondvar.unix.TNamedCondVar.Create(LActualName);
  if AConfig.EnableStats then
    Result.UpdateConfig(AConfig);
  {$ENDIF}
  {$IFDEF WINDOWS}
  Result := fafafa.core.sync.namedCondvar.windows.TNamedCondVar.Create(LActualName);
  if AConfig.EnableStats then
    Result.UpdateConfig(AConfig);
  {$ENDIF}
end;

function MakeGlobalNamedCondVar(const AName: string): INamedCondVar;
begin
  Result := MakeNamedCondVar(AName, GlobalNamedCondVarConfig);
end;

function MakeNamedCondVarWithTimeout(const AName: string; ATimeoutMs: Cardinal): INamedCondVar;
begin
  Result := MakeNamedCondVar(AName, NamedCondVarConfigWithTimeout(ATimeoutMs));
end;

function MakeNamedCondVarWithStats(const AName: string): INamedCondVar;
var
  LConfig: TNamedCondVarConfig;
begin
  LConfig := DefaultNamedCondVarConfig;
  LConfig.EnableStats := True;
  Result := MakeNamedCondVar(AName, LConfig);
end;

function TryOpenNamedCondVar(const AName: string): INamedCondVar;
begin
  // 尝试打开现有的命名条件变�?
  // 实际上与 MakeNamedCondVar 相同，因为底层实现会自动处理创建/打开逻辑
  Result := MakeNamedCondVar(AName);
end;

// ===== 配置辅助函数（重新导出） =====

function DefaultNamedCondVarConfig: TNamedCondVarConfig;
begin
  Result := fafafa.core.sync.namedCondvar.base.DefaultNamedCondVarConfig;
end;

function NamedCondVarConfigWithTimeout(ATimeoutMs: Cardinal): TNamedCondVarConfig;
begin
  Result := fafafa.core.sync.namedCondvar.base.NamedCondVarConfigWithTimeout(ATimeoutMs);
end;

function GlobalNamedCondVarConfig: TNamedCondVarConfig;
begin
  Result := fafafa.core.sync.namedCondvar.base.GlobalNamedCondVarConfig;
end;

function EmptyNamedCondVarStats: TNamedCondVarStats;
begin
  Result := fafafa.core.sync.namedCondvar.base.EmptyNamedCondVarStats;
end;

end.
