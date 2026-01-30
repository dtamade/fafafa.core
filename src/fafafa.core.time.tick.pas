unit fafafa.core.time.tick;


{
┌──────────────────────────────────────────────────────────────────────────────┐
│                                                                              │
│          ______   ______     ______   ______     ______   ______             │
│         /\  ___\ /\  __ \   /\  ___\ /\  __ \   /\  ___\ /\  __ \            │
│         \ \  __\ \ \  __ \  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \           │
│          \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\          │
│           \/_/     \/_/\/_/   \/_/     \/_/\/_/   \/_/     \/_/\/_/          │
│                                                                              │
│                                   Studio                                     │
└──────────────────────────────────────────────────────────────────────────────┘

────────────────────────────────────────────────────────────────────────────────
📦 项目：fafafa.core.time.tick - 跨平台 Tick 实现
────────────────────────────────────────────────────────────────────────────────
📖 概述：
  聚合各平台 Tick（计时器）实现，统一导出 ITick 及相关工厂方法，
  支持标准、高精度、硬件计时器的自动选择与实例化。
────────────────────────────────────────────────────────────────────────────────
🔧 特性：
  • 自动适配主流平台（Windows/Darwin/Unix/硬件定时器等）
  • 统一 ITick 接口，便于跨平台替换与扩展
  • 支持多种 Tick 类型（标准/高精度/硬件）
────────────────────────────────────────────────────────────────────────────────
📜 声明：
  转发或用于个人/商业项目时，请保留本项目的版权声明。
────────────────────────────────────────────────────────────────────────────────
👤 author  : fafafaStudio
📧 Email   : dtamade@gmail.com
💬 QQGroup : 685403987
────────────────────────────────────────────────────────────────────────────────
}

{$mode objfpc}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.time.tick.base
  {$IFDEF WINDOWS}
  , fafafa.core.time.tick.windows
  {$ELSEIF DEFINED(DARWIN)}
  , fafafa.core.time.tick.darwin
  {$ELSEIF DEFINED(UNIX)}
  , fafafa.core.time.tick.unix
  {$ENDIF}
  , fafafa.core.time.tick.hardware
  ;

type
  // TTickType: 计时器类型枚举（标准/高精度/硬件）
  TTickType  = fafafa.core.time.tick.base.TTickType;
  // TTickTypes: 计时器类型集合
  TTickTypes = fafafa.core.time.tick.base.TTickTypes;
  // ITick: Tick 计时器接口
  ITick      = fafafa.core.time.tick.base.ITick;
  // TTick: Tick 计时器实现基类
  TTick      = fafafa.core.time.tick.base.TTick;

{**
 * GetTickTypeName
 *
 * @desc 获取指定计时器类型的名称字符串.
 *
 * @params
 *   aType 计时器类型
 *
 * @return 类型名称
 *}
function GetTickTypeName(const aType: TTickType): string; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}

{**
 * GetAvailableTickTypes
 *
 * @desc 获取当前平台可用的计时器类型集合.
 *
 * @return 可用计时器类型集合
 *}
function GetAvailableTickTypes: TTickTypes; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}

{**
 * HasHardwareTick
 *
 * @desc 判断当前平台是否支持硬件计时器.
 *
 * @return 是否支持硬件计时器
 *}
function HasHardwareTick: Boolean; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}

{**
 * MakeTick
 *
 * @desc 创建指定类型的计时器实例.
 *
 * @params
 *   aType 计时器类型
 *
 * @return ITick 实例
 *}
function MakeTick(aType: TTickType): ITick; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}

{**
 * MakeTick
 *
 * @desc 创建最佳可用的计时器实例（优先硬件/高精度）.
 *
 * @return ITick 实例
 *}
function MakeTick: ITick; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}

{**
 * MakeBestTick
 *
 * @desc 创建最佳可用的计时器实例（优先硬件/高精度）.
 *
 * @return ITick 实例
 *}
function MakeBestTick: ITick; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}

{**
 * MakeStdTick
 *
 * @desc 创建标准计时器实例.
 *
 * @return ITick 实例
 *}
function MakeStdTick: ITick; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}

{**
 * MakeHDTick
 *
 * @desc 创建高精度计时器实例.
 *
 * @return ITick 实例
 *}
function MakeHDTick: ITick; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}

{**
 * MakeHWTick
 *
 * @desc 创建硬件计时器实例.
 *
 * @return ITick 实例
 *}
function MakeHWTick: ITick; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}

implementation

function GetTickTypeName(const aType: TTickType): string;
begin
  Result := fafafa.core.time.tick.base.GetTickTypeName(aType);
end;

function GetAvailableTickTypes: TTickTypes;
begin
  Result := [];
  {$IF DEFINED(WINDOWS) OR DEFINED(DARWIN) OR DEFINED(UNIX)}
  Result := [ttStandard, ttHighPrecision];
  {$ENDIF}

  {$IF DEFINED(CPUX86_64) OR DEFINED(CPUI386) OR (DEFINED(CPUAARCH64) AND DEFINED(FAFAFA_USE_ARCH_TIMER))
     OR (DEFINED(CPUARM) AND DEFINED(ARMV7A) AND DEFINED(FAFAFA_USE_ARCH_TIMER))
     OR (DEFINED(CPURISCV32) AND (DEFINED(FAFAFA_CORE_USE_RISCV_TIME_CSR) OR DEFINED(FAFAFA_CORE_USE_RISCV_CYCLE_CSR)))
     OR (DEFINED(CPURISCV64) AND (DEFINED(FAFAFA_CORE_USE_RISCV_TIME_CSR) OR DEFINED(FAFAFA_CORE_USE_RISCV_CYCLE_CSR))) }
  Result := Result + [ttHardware];
  {$ENDIF}
end;

function HasHardwareTick: Boolean;
begin
  Result := ttHardware in GetAvailableTickTypes;
end;

function MakeTick(aType: TTickType): ITick;
begin
  case aType of
    ttStandard:      Result := MakeStdTick();
    ttHighPrecision: Result := MakeHDTick();
    ttHardware:      Result := MakeHWTick();
  end;
end;

function MakeTick: ITick;
begin
  Result := MakeBestTick();
end;

function MakeBestTick: ITick;
var
  LTypes: TTickTypes;
begin
  LTypes := GetAvailableTickTypes;

  if ttHardware in LTypes then
    Result := MakeHWTick()
  else if ttHighPrecision in LTypes then
    Result := MakeHDTick()
  else if ttStandard in LTypes then
    Result := MakeStdTick()
  else
    raise ETickNotAvailable.Create('No available tick types');
end;

function MakeStdTick: ITick;
begin
  {$IFDEF WINDOWS}
  Result := fafafa.core.time.tick.windows.MakeTick();
  {$ELSEIF DEFINED(DARWIN)}
  Result := fafafa.core.time.tick.darwin.MakeTick();
  {$ELSEIF DEFINED(UNIX)}
  Result := fafafa.core.time.tick.unix.MakeTick();
  {$ELSE}
    {$ERROR 'Unsupported platform for fafafa.core.time.tick.MakeStandardTick'}
  {$ENDIF}
end;

function MakeHDTick: ITick;
begin
  {$IFDEF WINDOWS}
  Result := fafafa.core.time.tick.windows.MakeHDTick();
  {$ELSEIF DEFINED(DARWIN)}
  Result := fafafa.core.time.tick.darwin.MakeHDTick();
  {$ELSEIF DEFINED(UNIX)}
  Result := fafafa.core.time.tick.unix.MakeHDTick();
  {$ELSE}
    {$ERROR 'Unsupported platform for fafafa.core.time.tick.MakeHDTick'}
  {$ENDIF}
end;

function MakeHWTick: ITick;
begin
  Result := fafafa.core.time.tick.hardware.MakeTick();
end;

end.
