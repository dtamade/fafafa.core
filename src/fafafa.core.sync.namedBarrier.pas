unit fafafa.core.sync.namedBarrier;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.base, fafafa.core.sync.base, fafafa.core.sync.namedBarrier.base;

// ===== 类型别名 =====
type
  INamedBarrier = fafafa.core.sync.namedBarrier.base.INamedBarrier;
  INamedBarrierGuard = fafafa.core.sync.namedBarrier.base.INamedBarrierGuard;
  INamedBarrierBuilder = fafafa.core.sync.namedBarrier.base.INamedBarrierBuilder;
  TNamedBarrierConfig = fafafa.core.sync.namedBarrier.base.TNamedBarrierConfig;
  TNamedBarrierError = fafafa.core.sync.namedBarrier.base.TNamedBarrierError;
  TNamedBarrierErrorInfo = fafafa.core.sync.namedBarrier.base.TNamedBarrierErrorInfo;
  TNamedBarrierInfo = fafafa.core.sync.namedBarrier.base.TNamedBarrierInfo;

// ===== 现代化工厂函数 =====

{ 创建命名屏障 - 推荐使用的现代化接口 }
function MakeNamedBarrier(const AName: string; const AConfig: TNamedBarrierConfig): INamedBarrier; overload;
function MakeNamedBarrier(const AName: string): INamedBarrier; overload;
function MakeNamedBarrier(const AName: string; AParticipantCount: Cardinal): INamedBarrier; overload;

{ 尝试打开现有的命名屏障 }
function TryOpenNamedBarrier(const AName: string): INamedBarrier;

{ 创建全局命名屏障 }
function MakeGlobalNamedBarrier(const AName: string): INamedBarrier;
function MakeGlobalNamedBarrier(const AName: string; AParticipantCount: Cardinal): INamedBarrier; overload;

{ Builder 模式工厂函数 - 现代化推荐方式 }
function NewNamedBarrierBuilder(const AName: string): INamedBarrierBuilder;

// ===== 配置函数重新导出 =====
function DefaultNamedBarrierConfig: TNamedBarrierConfig;
function NamedBarrierConfigWithTimeout(ATimeoutMs: Cardinal): TNamedBarrierConfig;
function NamedBarrierConfigWithParticipants(AParticipantCount: Cardinal): TNamedBarrierConfig;
function GlobalNamedBarrierConfig: TNamedBarrierConfig;

implementation

uses
  SysUtils
  {$IFDEF UNIX}
  , fafafa.core.sync.namedBarrier.unix
  {$ENDIF}
  {$IFDEF WINDOWS}
  , fafafa.core.sync.namedBarrier.windows
  {$ENDIF};

type
  // 门面层的 Builder 实现，避免循环引用
  TFacadeNamedBarrierBuilder = class(TInterfacedObject, INamedBarrierBuilder)
  private
    FName: string;
    FConfig: TNamedBarrierConfig;
  public
    constructor Create(const AName: string);

    // INamedBarrierBuilder 接口
    function WithParticipants(ACount: Cardinal): INamedBarrierBuilder;
    function WithTimeout(ATimeoutMs: Cardinal): INamedBarrierBuilder;
    function WithAutoReset(AAutoReset: Boolean): INamedBarrierBuilder;
    function WithGlobalNamespace(AUseGlobal: Boolean): INamedBarrierBuilder;
    function WithRetryPolicy(AMaxRetries: Integer; AIntervalMs: Cardinal): INamedBarrierBuilder;
    function Build: INamedBarrier;
  end;

// ===== 现代化工厂函数实现 =====

function MakeNamedBarrier(const AName: string; const AConfig: TNamedBarrierConfig): INamedBarrier;
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
  // Unix 平台：命名屏障默认就是全局的，无需特殊处理
  {$ENDIF}

  // 创建平台特定实例（完全隐藏实现细节）
  {$IFDEF UNIX}
  Result := fafafa.core.sync.namedBarrier.unix.TNamedBarrier.Create(LActualName, AConfig);
  {$ENDIF}
  {$IFDEF WINDOWS}
  Result := fafafa.core.sync.namedBarrier.windows.TNamedBarrier.Create(LActualName, AConfig);
  {$ENDIF}
end;

function MakeNamedBarrier(const AName: string): INamedBarrier;
begin
  Result := MakeNamedBarrier(AName, DefaultNamedBarrierConfig);
end;

function MakeNamedBarrier(const AName: string; AParticipantCount: Cardinal): INamedBarrier;
var
  LConfig: TNamedBarrierConfig;
begin
  LConfig := DefaultNamedBarrierConfig;
  LConfig.ParticipantCount := AParticipantCount;
  Result := MakeNamedBarrier(AName, LConfig);
end;

function TryOpenNamedBarrier(const AName: string): INamedBarrier;
begin
  try
    // 尝试创建/打开屏障，如果失败返回 nil
    Result := MakeNamedBarrier(AName);
  except
    Result := nil;
  end;
end;



function MakeGlobalNamedBarrier(const AName: string): INamedBarrier;
var
  LConfig: TNamedBarrierConfig;
begin
  LConfig := GlobalNamedBarrierConfig;
  Result := MakeNamedBarrier(AName, LConfig);
end;

function MakeGlobalNamedBarrier(const AName: string; AParticipantCount: Cardinal): INamedBarrier;
var
  LConfig: TNamedBarrierConfig;
begin
  LConfig := GlobalNamedBarrierConfig;
  LConfig.ParticipantCount := AParticipantCount;
  Result := MakeNamedBarrier(AName, LConfig);
end;

// ===== 配置函数重新导出 =====

function DefaultNamedBarrierConfig: TNamedBarrierConfig;
begin
  Result := fafafa.core.sync.namedBarrier.base.DefaultNamedBarrierConfig;
end;

function NamedBarrierConfigWithTimeout(ATimeoutMs: Cardinal): TNamedBarrierConfig;
begin
  Result := fafafa.core.sync.namedBarrier.base.NamedBarrierConfigWithTimeout(ATimeoutMs);
end;

function NamedBarrierConfigWithParticipants(AParticipantCount: Cardinal): TNamedBarrierConfig;
begin
  Result := fafafa.core.sync.namedBarrier.base.NamedBarrierConfigWithParticipants(AParticipantCount);
end;

function GlobalNamedBarrierConfig: TNamedBarrierConfig;
begin
  Result := fafafa.core.sync.namedBarrier.base.GlobalNamedBarrierConfig;
end;

// ===== Builder 模式工厂函数实现 =====

function NewNamedBarrierBuilder(const AName: string): INamedBarrierBuilder;
begin
  Result := TFacadeNamedBarrierBuilder.Create(AName);
end;

{ TFacadeNamedBarrierBuilder }

constructor TFacadeNamedBarrierBuilder.Create(const AName: string);
begin
  inherited Create;
  FName := AName;
  FConfig := DefaultNamedBarrierConfig;
end;

function TFacadeNamedBarrierBuilder.WithParticipants(ACount: Cardinal): INamedBarrierBuilder;
begin
  FConfig.ParticipantCount := ACount;
  Result := Self;
end;

function TFacadeNamedBarrierBuilder.WithTimeout(ATimeoutMs: Cardinal): INamedBarrierBuilder;
begin
  FConfig.TimeoutMs := ATimeoutMs;
  Result := Self;
end;

function TFacadeNamedBarrierBuilder.WithAutoReset(AAutoReset: Boolean): INamedBarrierBuilder;
begin
  FConfig.AutoReset := AAutoReset;
  Result := Self;
end;

function TFacadeNamedBarrierBuilder.WithGlobalNamespace(AUseGlobal: Boolean): INamedBarrierBuilder;
begin
  FConfig.UseGlobalNamespace := AUseGlobal;
  Result := Self;
end;

function TFacadeNamedBarrierBuilder.WithRetryPolicy(AMaxRetries: Integer; AIntervalMs: Cardinal): INamedBarrierBuilder;
begin
  FConfig.MaxRetries := AMaxRetries;
  FConfig.RetryIntervalMs := AIntervalMs;
  Result := Self;
end;

function TFacadeNamedBarrierBuilder.Build: INamedBarrier;
begin
  Result := MakeNamedBarrier(FName, FConfig);
end;

end.
