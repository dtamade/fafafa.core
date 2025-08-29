unit fafafa.core.sync.namedBarrier.base;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, fafafa.core.base, fafafa.core.sync.base, fafafa.core.result;

type
  // Forward declarations
  INamedBarrier = interface;
  INamedBarrierGuard = interface;
  INamedBarrierBuilder = interface;

  // Enhanced error type for namedBarrier operations
  TNamedBarrierError = (
    nbeNone,
    nbeInvalidArgument,
    nbeTimeout,
    nbeSystemError,
    nbeNotFound,
    nbeInvalidState,
    nbeResourceExhausted,    // 资源耗尽
    nbePermissionDenied,     // 权限拒绝
    nbeInterrupted,          // 操作被中断
    nbeUnknownError
  );

  // 详细的错误信息结构
  TNamedBarrierErrorInfo = record
    Code: TNamedBarrierError;
    Message: string;
    SystemCode: Integer;
    Context: string;
  end;



type
  // ===== 屏障信息结构（只读快照）=====
  TNamedBarrierInfo = record
    Name: string;
    ParticipantCount: Cardinal;
    CurrentWaitingCount: Cardinal;
    Generation: Cardinal;
    IsSignaled: Boolean;
    AutoReset: Boolean;
  end;

  // ===== 配置结构 =====
  TNamedBarrierConfig = record
    TimeoutMs: Cardinal;           // 默认超时时间（毫秒）
    RetryIntervalMs: Cardinal;     // 重试间隔（毫秒）
    MaxRetries: Integer;           // 最大重试次数
    UseGlobalNamespace: Boolean;   // 是否使用全局命名空间
    ParticipantCount: Cardinal;    // 参与者数量
    AutoReset: Boolean;            // 是否自动重置
  end;

// 配置辅助函数
function DefaultNamedBarrierConfig: TNamedBarrierConfig;
function NamedBarrierConfigWithTimeout(ATimeoutMs: Cardinal): TNamedBarrierConfig;
function NamedBarrierConfigWithParticipants(AParticipantCount: Cardinal): TNamedBarrierConfig;
function GlobalNamedBarrierConfig: TNamedBarrierConfig;

// Builder 模式工厂函数
function NewNamedBarrierBuilder(const AName: string): INamedBarrierBuilder;

type
  // ===== Builder 模式的配置接口 =====
  INamedBarrierBuilder = interface
    ['{A1B2C3D4-5E6F-7890-ABCD-EF1234567890}']
    function WithParticipants(ACount: Cardinal): INamedBarrierBuilder;
    function WithTimeout(ATimeoutMs: Cardinal): INamedBarrierBuilder;
    function WithAutoReset(AAutoReset: Boolean): INamedBarrierBuilder;
    function WithGlobalNamespace(AUseGlobal: Boolean): INamedBarrierBuilder;
    function WithRetryPolicy(AMaxRetries: Integer; AIntervalMs: Cardinal): INamedBarrierBuilder;
    function Build: INamedBarrier;
  end;

  // ===== 真正的 RAII 模式屏障守卫 =====
  INamedBarrierGuard = interface
    ['{B2C3D4E5-6F78-9012-CDEF-123456789ABC}']
    function IsLastParticipant: Boolean; // 是否为最后一个参与者
    function GetGeneration: Cardinal;   // 获取屏障代数
    function GetWaitTime: Cardinal;     // 获取等待时间（毫秒）
    // RAII: 析构时自动处理屏障状态变更，确保资源正确释放
    // 守卫不再提供查询功能，专注于生命周期管理
  end;

  // ===== 简化的现代化命名屏障接口 =====
  INamedBarrier = interface
    ['{C3D4E5F6-7890-1234-ABCD-EF123456789D}']
    // 核心屏障操作 - 返回 RAII 守卫
    function Wait: INamedBarrierGuard;                              // 阻塞等待
    function TryWait: INamedBarrierGuard;                          // 非阻塞尝试，立即返回
    function WaitFor(ATimeoutMs: Cardinal): INamedBarrierGuard;    // 带超时等待

    // 查询操作（线程安全的快照）- 职责分离
    function GetInfo: TNamedBarrierInfo;         // 获取完整的屏障信息快照

    // 控制操作（仅限管理用途）
    procedure Reset;                             // 重置屏障到初始状态
    procedure Signal;                            // 手动触发屏障（紧急情况）
  end;

implementation

type
  // Builder 模式的具体实现
  TNamedBarrierBuilder = class(TInterfacedObject, INamedBarrierBuilder)
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

// Builder 工厂函数实现
function NewNamedBarrierBuilder(const AName: string): INamedBarrierBuilder;
begin
  Result := TNamedBarrierBuilder.Create(AName);
end;

function DefaultNamedBarrierConfig: TNamedBarrierConfig;
begin
  Result.TimeoutMs := 30000;          // 30秒默认超时（屏障通常需要更长时间）
  Result.RetryIntervalMs := 10;       // 10毫秒重试间隔
  Result.MaxRetries := 100;           // 最多重试100次
  Result.UseGlobalNamespace := False; // 默认不使用全局命名空间
  Result.ParticipantCount := 2;       // 默认2个参与者
  Result.AutoReset := True;           // 默认自动重置
end;

function NamedBarrierConfigWithTimeout(ATimeoutMs: Cardinal): TNamedBarrierConfig;
begin
  Result := DefaultNamedBarrierConfig;
  Result.TimeoutMs := ATimeoutMs;
end;

function NamedBarrierConfigWithParticipants(AParticipantCount: Cardinal): TNamedBarrierConfig;
begin
  Result := DefaultNamedBarrierConfig;
  Result.ParticipantCount := AParticipantCount;
end;

function GlobalNamedBarrierConfig: TNamedBarrierConfig;
begin
  Result := DefaultNamedBarrierConfig;
  Result.UseGlobalNamespace := True;
end;

{ TNamedBarrierBuilder }

constructor TNamedBarrierBuilder.Create(const AName: string);
begin
  inherited Create;
  FName := AName;
  FConfig := DefaultNamedBarrierConfig;
end;

function TNamedBarrierBuilder.WithParticipants(ACount: Cardinal): INamedBarrierBuilder;
begin
  FConfig.ParticipantCount := ACount;
  Result := Self;
end;

function TNamedBarrierBuilder.WithTimeout(ATimeoutMs: Cardinal): INamedBarrierBuilder;
begin
  FConfig.TimeoutMs := ATimeoutMs;
  Result := Self;
end;

function TNamedBarrierBuilder.WithAutoReset(AAutoReset: Boolean): INamedBarrierBuilder;
begin
  FConfig.AutoReset := AAutoReset;
  Result := Self;
end;

function TNamedBarrierBuilder.WithGlobalNamespace(AUseGlobal: Boolean): INamedBarrierBuilder;
begin
  FConfig.UseGlobalNamespace := AUseGlobal;
  Result := Self;
end;

function TNamedBarrierBuilder.WithRetryPolicy(AMaxRetries: Integer; AIntervalMs: Cardinal): INamedBarrierBuilder;
begin
  FConfig.MaxRetries := AMaxRetries;
  FConfig.RetryIntervalMs := AIntervalMs;
  Result := Self;
end;

function TNamedBarrierBuilder.Build: INamedBarrier;
begin
  // 这里需要调用门面层的实现，避免循环引用
  raise Exception.Create('TNamedBarrierBuilder.Build must be implemented in facade layer');
end;

end.
