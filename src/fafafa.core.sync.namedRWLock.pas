unit fafafa.core.sync.namedRWLock;

{$mode objfpc}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.sync.base, fafafa.core.sync.namedRWLock.base
  {$IFDEF WINDOWS}, fafafa.core.sync.namedRWLock.windows{$ENDIF}
  {$IFDEF UNIX},    fafafa.core.sync.namedRWLock.unix{$ENDIF};

type
  // 公开接口类型 - 完全隐藏平台差异
  INamedRWLockReadGuard = fafafa.core.sync.namedRWLock.base.INamedRWLockReadGuard;
  INamedRWLockWriteGuard = fafafa.core.sync.namedRWLock.base.INamedRWLockWriteGuard;
  INamedRWLock = fafafa.core.sync.namedRWLock.base.INamedRWLock;
  TNamedRWLockConfig = fafafa.core.sync.namedRWLock.base.TNamedRWLockConfig;

  // 注意：TNamedRWLock 具体类型不再公开导出
  // 用户应该只使�?INamedRWLock 接口和工厂函�?

// ===== 工厂函数 =====

{ 创建命名读写�?- 推荐的现代化 API }
function MakeNamedRWLock(const AName: string; const AConfig: TNamedRWLockConfig): INamedRWLock; overload;
function MakeNamedRWLock(const AName: string): INamedRWLock; overload;

{ 便利函数 - 简化常用场�?}
function MakeNamedRWLock(const AName: string; AInitialOwner: Boolean): INamedRWLock; overload;
function MakeGlobalNamedRWLock(const AName: string): INamedRWLock;
function TryOpenNamedRWLock(const AName: string): INamedRWLock;

{ 配置辅助函数 - 重新导出 }
function DefaultNamedRWLockConfig: TNamedRWLockConfig; inline;
function NamedRWLockConfigWithTimeout(ATimeoutMs: Cardinal): TNamedRWLockConfig; inline;
function GlobalNamedRWLockConfig: TNamedRWLockConfig; inline;

implementation

function MakeNamedRWLock(const AName: string; const AConfig: TNamedRWLockConfig): INamedRWLock;
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
  // Unix 平台：命名读写锁默认就是全局的，无需特殊处理
  {$ENDIF}

  // 创建平台特定实例（完全隐藏实现细节）
  {$IFDEF UNIX}
  Result := fafafa.core.sync.namedRWLock.unix.TNamedRWLock.Create(LActualName, AConfig.InitialOwner);
  {$ENDIF}
  {$IFDEF WINDOWS}
  Result := fafafa.core.sync.namedRWLock.windows.TNamedRWLock.Create(LActualName, AConfig.InitialOwner);
  {$ENDIF}
end;

function MakeNamedRWLock(const AName: string): INamedRWLock;
begin
  Result := MakeNamedRWLock(AName, DefaultNamedRWLockConfig);
end;

function MakeNamedRWLock(const AName: string; AInitialOwner: Boolean): INamedRWLock;
var
  LConfig: TNamedRWLockConfig;
begin
  LConfig := DefaultNamedRWLockConfig;
  LConfig.InitialOwner := AInitialOwner;
  Result := MakeNamedRWLock(AName, LConfig);
end;

function MakeGlobalNamedRWLock(const AName: string): INamedRWLock;
begin
  Result := MakeNamedRWLock(AName, GlobalNamedRWLockConfig);
end;

function TryOpenNamedRWLock(const AName: string): INamedRWLock;
begin
  // 语义：尝试打开（实际上是“打开或创建”）命名读写锁，但不再吞掉所有异常
  // - 参数错误（空名称、非法字符等）应直接向上传播
  // - 资源或系统错误同样不应伪装成“打开失败”
  Result := MakeNamedRWLock(AName);
end;

function DefaultNamedRWLockConfig: TNamedRWLockConfig;
begin
  Result := fafafa.core.sync.namedRWLock.base.DefaultNamedRWLockConfig;
end;

function NamedRWLockConfigWithTimeout(ATimeoutMs: Cardinal): TNamedRWLockConfig;
begin
  Result := fafafa.core.sync.namedRWLock.base.NamedRWLockConfigWithTimeout(ATimeoutMs);
end;

function GlobalNamedRWLockConfig: TNamedRWLockConfig;
begin
  Result := fafafa.core.sync.namedRWLock.base.GlobalNamedRWLockConfig;
end;

end.
