unit fafafa.core.sync.namedCondvar;

{
  ============================================================================
  ⚠️  EXPERIMENTAL / 实验性 API
  ============================================================================
  
  INamedCondVar 是跨进程条件变量实现。当前状态:
  - Unix/Linux: 基于 POSIX shm + pthread_cond，功能完善
  - Windows: Broadcast 语义在极端竞争场景下有理论风险
  
  生产使用建议:
  - Unix 平台: 可用于生产环境
  - Windows 平台: 建议仅用于开发/测试，或评估风险后使用
  
  替代方案:
  - 跨进程同步推荐使用 INamedMutex + INamedEvent 组合
  ============================================================================
}

{$mode objfpc}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.sync.namedCondvar.base
  {$IFDEF WINDOWS}, fafafa.core.sync.namedCondvar.windows{$ENDIF}
  {$IFDEF UNIX},    fafafa.core.sync.namedCondvar.unix{$ENDIF};

type
  // 公开接口类型 - 完全隐藏平台差异
  INamedCondVar = fafafa.core.sync.namedCondvar.base.INamedCondVar;
  TNamedCondVarConfig = fafafa.core.sync.namedCondvar.base.TNamedCondVarConfig;
  TNamedCondVarStats = fafafa.core.sync.namedCondvar.base.TNamedCondVarStats;

  // 注意：TNamedCondVar 具体类型不再公开导出
  // 用户应该只使用 INamedCondVar 接口和工厂函数

// ===== 工厂函数（仅使用 MakeXXX 模式）=====

// 主要工厂函数
function MakeNamedCondVar(const AName: string): INamedCondVar; overload;
function MakeNamedCondVar(const AName: string; const AConfig: TNamedCondVarConfig): INamedCondVar; overload;

// 便利工厂函数
function MakeGlobalNamedCondVar(const AName: string): INamedCondVar;
function MakeNamedCondVarWithTimeout(const AName: string; ATimeoutMs: Cardinal): INamedCondVar;
function MakeNamedCondVarWithStats(const AName: string): INamedCondVar;

// 尝试打开现有的命名条件变量
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
  // Handle global namespace (platform-specific logic internalized)
  LActualName := AName;
  {$IFDEF WINDOWS}
  if AConfig.UseGlobalNamespace and (Pos('Global\', AName) <> 1) then
    LActualName := 'Global\' + AName;
  {$ENDIF}
  {$IFDEF UNIX}
  // Unix platform: named condition variables are global by default, no special handling needed
  {$ENDIF}

  // Create platform-specific instance (completely hiding implementation details)
  {$IFDEF UNIX}
  Result := fafafa.core.sync.namedCondvar.unix.TNamedCondVar.Create(LActualName);
  // Always apply config to ensure timeout and other settings take effect
  Result.UpdateConfig(AConfig);
  {$ENDIF}
  {$IFDEF WINDOWS}
  Result := fafafa.core.sync.namedCondvar.windows.TNamedCondVar.Create(LActualName);
  // Always apply config to ensure timeout and other settings take effect
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
  // 尝试打开现有的命名条件变量
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
