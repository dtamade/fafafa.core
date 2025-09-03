unit fafafa.core.time.tick.base;

{
──────────────────────────────────────────────────────────────
   ______   ______     ______   ______     ______   ______
  /\  ___\ /\  __ \   /\  ___\ /\  __ \   /\  ___\ /\  __ \
  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \
   \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\
    \/_/     \/_/\/_/   \/_/     \/_/\/_/   \/_/     \/_/\/_/
                          Studio
──────────────────────────────────────────────────────────────
📦 项目：fafafa.core.time.tick.base - Tick 基础定义

📖 概述：
  高精度时间测量的基础接口、类型和常量定义。
  所有平台实现都基于这些定义。

🔧 特性：
  • 跨平台接口定义
  • 类型安全的时间测量
  • 与 TDuration/TInstant 集成
  • 简洁的核心 API

📜 声明：
  转发或用于个人/商业项目时，请保留本项目的版权声明。

👤 author  : fafafaStudio
📧 Email   : dtamade@gmail.com
💬 QQGroup : 685403987
💬 QQ      : 179033731
──────────────────────────────────────────────────────────────
}

{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes,
  fafafa.core.base,
  fafafa.core.time.duration;

type
  // Tick 类型（简化）
  TTickType = (
    ttBest,           // 自动选择最佳
    ttStandard,       // 标准精度
    ttHighPrecision,  // 高精度
    ttTSC,            // TSC 硬件计时器
    ttSystem          // 系统时钟
  );
  TTickTypeArray = array of TTickType;

  // 高精度时间测量接口（精简版本）
  ITick = interface
    ['{B8F5A2E1-4C3D-4F2A-9B1E-8D7C6A5F4E3D}']

    // === 基础 Tick 操作 ===
    function GetCurrentTick: UInt64;
    function GetResolution: UInt64; // 每秒 ticks 数
    function GetElapsedTicks(const AStartTick: UInt64): UInt64;

    // === 与新时间架构集成 ===
    function TicksToDuration(const ATicks: UInt64): TDuration;
    function DurationToTicks(const D: TDuration): UInt64;
    function GetInstant: TInstant;
    function GetDurationResolution: TDuration;

    // === 时钟特性查询 ===
    function IsMonotonic: Boolean;
    function IsHighResolution: Boolean;
    function GetMinimumInterval: TDuration;
    function GetMaximumInterval: TDuration;
  end;

  // 异常类型
  ETickError = class(ECore) end;
  ETickNotAvailable = class(ETickError) end;
  ETickInvalidArgument = class(ETickError) end;

  // Tick 基类 - 提供通用实现，减少平台特定代码的重复
  TTick = class(TInterfacedObject, ITick)
  protected
    // 子类必须实现的抽象方法
    function DoGetCurrentTick: UInt64; virtual; abstract;
    function DoGetResolution: UInt64; virtual; abstract;
    function DoTicksToDuration(const ATicks: UInt64): TDuration; virtual; abstract;
    function DoDurationToTicks(const D: TDuration): UInt64; virtual; abstract;
    function DoIsMonotonic: Boolean; virtual; abstract;
    function DoIsHighResolution: Boolean; virtual; abstract;

    // 子类可以重写的虚方法（提供默认实现）
    function DoGetMinimumInterval: TDuration; virtual;
    function DoGetMaximumInterval: TDuration; virtual;
    function DoGetInstant: TInstant; virtual;
  public
    // ITick 接口实现（调用受保护的虚方法）
    function GetCurrentTick: UInt64;
    function GetResolution: UInt64;
    function GetElapsedTicks(const AStartTick: UInt64): UInt64;
    function TicksToDuration(const ATicks: UInt64): TDuration;
    function DurationToTicks(const D: TDuration): UInt64;
    function GetInstant: TInstant;
    function GetDurationResolution: TDuration;
    function IsMonotonic: Boolean;
    function IsHighResolution: Boolean;
    function GetMinimumInterval: TDuration;
    function GetMaximumInterval: TDuration;
  end;

const
  // Tick 类型名称常量
  TICK_TYPE_BEST_NAME = 'Best Available Timer';
  TICK_TYPE_STANDARD_NAME = 'Standard Precision Timer';
  TICK_TYPE_HIGHPRECISION_NAME = 'High Precision Timer';
  TICK_TYPE_TSC_NAME = 'TSC Hardware Timer';
  TICK_TYPE_SYSTEM_NAME = 'System Clock Timer';

// 工厂函数声明（由平台实现提供）
function CreateTick(const AType: TTickType = ttBest): ITick;
function IsTickTypeAvailable(const AType: TTickType): Boolean;
function GetTickTypeName(const AType: TTickType): string;
function GetAvailableTickTypes: TTickTypeArray;

implementation

{ TTick }

// 受保护的虚方法默认实现
function TTick.DoGetMinimumInterval: TDuration;
begin
  Result := DoTicksToDuration(1);
end;

function TTick.DoGetMaximumInterval: TDuration;
begin
  Result := TDuration.Max;
end;

function TTick.DoGetInstant: TInstant;
begin
  Result := TInstant.Now;
end;

// ITick 接口实现
function TTick.GetCurrentTick: UInt64;
begin
  Result := DoGetCurrentTick;
end;

function TTick.GetResolution: UInt64;
begin
  Result := DoGetResolution;
end;

function TTick.GetElapsedTicks(const AStartTick: UInt64): UInt64;
begin
  Result := GetCurrentTick - AStartTick;
end;

function TTick.TicksToDuration(const ATicks: UInt64): TDuration;
begin
  Result := DoTicksToDuration(ATicks);
end;

function TTick.DurationToTicks(const D: TDuration): UInt64;
begin
  Result := DoDurationToTicks(D);
end;

function TTick.GetInstant: TInstant;
begin
  Result := DoGetInstant;
end;

function TTick.GetDurationResolution: TDuration;
begin
  Result := DoGetMinimumInterval;
end;

function TTick.IsMonotonic: Boolean;
begin
  Result := DoIsMonotonic;
end;

function TTick.IsHighResolution: Boolean;
begin
  Result := DoIsHighResolution;
end;

function TTick.GetMinimumInterval: TDuration;
begin
  Result := DoGetMinimumInterval;
end;

function TTick.GetMaximumInterval: TDuration;
begin
  Result := DoGetMaximumInterval;
end;

// 工厂函数的实现将由平台特定模块提供
// 这里只提供基础的名称查询功能

function GetTickTypeName(const AType: TTickType): string;
begin
  case AType of
    ttBest: Result := TICK_TYPE_BEST_NAME;
    ttStandard: Result := TICK_TYPE_STANDARD_NAME;
    ttHighPrecision: Result := TICK_TYPE_HIGHPRECISION_NAME;
    ttTSC: Result := TICK_TYPE_TSC_NAME;
    ttSystem: Result := TICK_TYPE_SYSTEM_NAME;
  else
    Result := 'Unknown Timer Type';
  end;
end;

// 基础实现 - 这些函数应该由平台特定模块重写
function CreateTick(const AType: TTickType): ITick;
begin
  // 基础实现，返回 nil，应该由平台特定模块提供实际实现
  Result := nil;
  raise Exception.Create('CreateTick not implemented for this platform');
end;

function IsTickTypeAvailable(const AType: TTickType): Boolean;
begin
  // 基础实现，默认只有系统时钟可用
  Result := (AType = ttSystem) or (AType = ttStandard);
end;

function GetAvailableTickTypes: TTickTypeArray;
begin
  // 基础实现，返回基本可用的类型
  SetLength(Result, 2);
  Result[0] := ttSystem;
  Result[1] := ttStandard;
end;

end.