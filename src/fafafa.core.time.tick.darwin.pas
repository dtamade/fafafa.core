unit fafafa.core.time.tick.darwin;

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
📦 项目：fafafa.core.time.tick.darwin - macOS Tick 实现
────────────────────────────────────────────────────────────────────────────────
📖 概述：
  提供 macOS (Darwin) 平台下基于 mach_absolute_time 的高精度计时器（Tick）实现，
  支持纳秒级别的单调递增计时，适用于高精度与通用时间测量场景。
────────────────────────────────────────────────────────────────────────────────
🔧 特性：
  • 基于 mach_absolute_time，纳秒级高精度，单调递增
  • 自动适配 timebase，保证跨设备一致性
  • 兼容 ITick 接口，便于跨平台替换
  • 线程安全，适合多线程环境
────────────────────────────────────────────────────────────────────────────────
📜 声明：
  转发或用于个人/商业项目时，请保留本项目的版权声明。
────────────────────────────────────────────────────────────────────────────────
👤 author  : fafafaStudio
📧 Email   : dtamade@gmail.com
💬 QQGroup : 685403987
💬 QQ      : 179033731
────────────────────────────────────────────────────────────────────────────────
}

{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.time.tick.base;

type
  mach_timebase_info_data_t = record
    numer: UInt32;
    denom: UInt32;
  end;
  pmach_timebase_info_data_t = ^mach_timebase_info_data_t;

const
  LibSystemDll = 'libSystem.dylib';

function mach_absolute_time: UInt64; cdecl; external LibSystemDll;
function mach_timebase_info(info: pmach_timebase_info_data_t): Integer; cdecl; external LibSystemDll;

type
  TDarwinTick = class(TTick)
  protected
    procedure Initialize(out aResolution: UInt64; out aIsMonotonic: Boolean; out aTickType: TTickType); override;
  private
    FNumer, FDenom: UInt64; // timebase: ns = ticks * numer / denom
  public
    function Tick: UInt64; override;
  end;

function MakeTick: ITick;

implementation

function MakeTick: ITick;
begin
  Result := TDarwinTick.Create;
end;

{ TDarwinTick }

procedure TDarwinTick.Initialize(out aResolution: UInt64; out aIsMonotonic: Boolean; out aTickType: TTickType);
var
  info: mach_timebase_info_data_t;
begin
  aIsMonotonic := True;
  aTickType := ttHighPrecision;

  // Apple 文档：返回 0 表示成功
  if (mach_timebase_info(@info) <> 0) or (info.denom = 0) or (info.numer = 0) then
    aResolution := 0
  else
    aResolution := (NANOSECONDS_PER_SECOND * info.denom) div info.numer;
end;

function TDarwinTick.Tick: UInt64;
begin
  Result := mach_absolute_time();
end;


end.
