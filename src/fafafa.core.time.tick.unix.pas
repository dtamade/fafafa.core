unit fafafa.core.time.tick.unix;


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
📦 项目：fafafa.core.time.tick.unix - Unix Tick 实现
────────────────────────────────────────────────────────────────────────────────
📖 概述：
  提供 Unix/Linux 平台下高精度与标准计时器（Tick）实现，支持 CLOCK_MONOTONIC
  及 gettimeofday，适用于高精度计时与通用时间测量场景。
────────────────────────────────────────────────────────────────────────────────
🔧 特性：
  • 支持 CLOCK_MONOTONIC（高精度，纳秒级，单调递增）
  • 支持 gettimeofday（微秒级，非单调）
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

{$mode objfpc}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.time.tick.base;

type

  TStdTick = class(TTick)
  protected
    procedure Initialize(out aResolution: UInt64; out aIsMonotonic: Boolean; out aTickType: TTickType); override;
  public
    function Tick: UInt64; override;
  end;

  THDTick = class(TTick)
  protected
    procedure Initialize(out aResolution: UInt64; out aIsMonotonic: Boolean; out aTickType: TTickType); override;
  public
    function Tick: UInt64; override;
  end;

  function GetResolution: UInt64; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}
  function GetTick: UInt64; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}
  function MakeTick: ITick; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}
  
  function GetHDResolution: UInt64; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}
  function GetHDTick: UInt64; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}
  function MakeHDTick: ITick; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}

implementation

uses
  BaseUnix, Unix
  {$IFDEF LINUX},Linux{$ENDIF}
  ;

function GetResolution: UInt64;
begin
  Result := MICROSECONDS_PER_SECOND;
end;

function GetTick: UInt64;
var
  LTV: TTimeVal;
begin
  fpgettimeofday(@LTV, nil);
  Result := UInt64(LTV.tv_sec) * GetResolution + UInt64(LTV.tv_usec);
end;

function MakeTick: ITick;
begin
  Result := TStdTick.Create;
end;


function GetHDResolution: UInt64;
begin
  Result := NANOSECONDS_PER_SECOND;
end;

function GetHDTick: UInt64;
var
  LTS: TTimeSpec;
  LTV: TTimeVal;
begin
  if clock_gettime(CLOCK_MONOTONIC, @LTS) = 0 then
    Result := UInt64(LTS.tv_sec) * GetHDResolution + UInt64(LTS.tv_nsec)
  else
  begin
    // 回退到 gettimeofday
    fpgettimeofday(@LTV, nil);
    // gettimeofday 返回微秒，需要转换为纳秒
    Result := UInt64(LTV.tv_sec) * GetHDResolution + UInt64(LTV.tv_usec) * 1000;
  end;
end;

function MakeHDTick: ITick;
begin
  Result := THDTick.Create;
end;


{ THDTick }

procedure THDTick.Initialize(out aResolution: UInt64; out aIsMonotonic: Boolean; out aTickType: TTickType);
begin
  aResolution  := NANOSECONDS_PER_SECOND;
  aIsMonotonic := True;
  aTickType    := ttHighPrecision;
end;

function THDTick.Tick: UInt64;
var
  LTS: TTimeSpec;
  LTV: TTimeVal;
begin
  if clock_gettime(CLOCK_MONOTONIC, @LTS) = 0 then
    Result := UInt64(LTS.tv_sec) * GetHDResolution + UInt64(LTS.tv_nsec)
  else
  begin
    // 回退到 gettimeofday
    fpgettimeofday(@LTV, nil);
    // gettimeofday 返回微秒，需要转换为纳秒
    Result := UInt64(LTV.tv_sec) * GetHDResolution + UInt64(LTV.tv_usec) * 1000;
  end;
end;

{ TStdTick }

procedure TStdTick.Initialize(out aResolution: UInt64; out aIsMonotonic: Boolean; out aTickType: TTickType);
begin
  aResolution  := MICROSECONDS_PER_SECOND;
  aIsMonotonic := False;
  aTickType    := ttStandard;
end;

function TStdTick.Tick: UInt64;
var
  LTV: TTimeVal;
begin
  fpgettimeofday(@LTV, nil);
  Result := UInt64(LTV.tv_sec) * GetResolution + UInt64(LTV.tv_usec);
end;


end.
