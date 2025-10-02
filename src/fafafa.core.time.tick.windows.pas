unit fafafa.core.time.tick.windows;


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
📦 项目：fafafa.core.time.tick.windows - Windows Tick 实现
────────────────────────────────────────────────────────────────────────────────
📖 概述：
  提供 Windows 平台下高精度与标准计时器（Tick）实现，支持 QueryPerformanceCounter
  及 GetTickCount64，适用于高精度计时与通用时间测量场景。
────────────────────────────────────────────────────────────────────────────────
🔧 特性：
  • 支持 QueryPerformanceCounter（高精度，单调递增）
  • 支持 GetTickCount64（标准，毫秒级，单调递增）
  • 兼容 ITick 接口，便于跨平台替换
  • 线程安全，适合多线程环境
────────────────────────────────────────────────────────────────────────────────
📜 声明：
  转发或用于个人/商业项目时，请保留本项目的版权声明。
────────────────────────────────────────────────────────────────────────────────
👤 author  : fafafaStudio
📧 Email   : dtamade@gmail.com
💬 QQGroup : 685403987
────────────────────────────────────────────────────────────────────────────────
}

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
  fafafa.core.atomic,
  fafafa.core.time.cpu;

const

  Kernel32Dll = 'kernel32.dll';

function QueryPerformanceCounter(out lpPerformanceCount: UInt64): LongBool; stdcall; external Kernel32Dll;
function QueryPerformanceFrequency(out lpFrequency: UInt64): LongBool; stdcall; external Kernel32Dll;
function GetTickCount64: UInt64; stdcall; external Kernel32Dll;


function GetResolution: UInt64;
begin
  Result := MILLISECONDS_PER_SECOND;
end;

function GetTick: UInt64;
begin
  Result := GetTickCount64;
end;

function MakeTick: ITick;
begin
  Result := TStdTick.Create;
end;

var
  GQpcResolution:     UInt64 = 0;
  GQpcResolutionOnce: Int32  = 0; // 0=未开始,1=进行中,2=完成

function GetHDResolution: UInt64;
var
  LState, LExpected: Int32;
begin
  // 快路径：已初始化（对 state 用 acquire）
  LState := atomic_load(GQpcResolutionOnce, mo_acquire);
  if LState = 2 then
    Exit(GQpcResolution);

  LExpected := 0;
  if atomic_compare_exchange(GQpcResolutionOnce, LExpected, 1) then
  begin
    if not QueryPerformanceFrequency(GQpcResolution) then
      GQpcResolution := 0;

    atomic_store(GQpcResolutionOnce, 2, mo_release);
    Result := GQpcResolution;
  end
  else
  begin
    // 等待初始化线程完成
    while atomic_load(GQpcResolutionOnce, mo_acquire) <> 2 do
      CpuRelax;

    Result := GQpcResolution;
  end;
end;

function GetHDTick: UInt64;
begin
  if not QueryPerformanceCounter(Result) then
    Result := 0;
end;

function MakeHDTick: ITick;
begin
  Result := THDTick.Create;
end;




{ TStdTick }

procedure TStdTick.Initialize(out aResolution: UInt64; out aIsMonotonic: Boolean; out aTickType: TTickType);
begin
  aResolution  := MILLISECONDS_PER_SECOND;
  aIsMonotonic := True;
  aTickType    := ttStandard;
end;

function TStdTick.Tick: UInt64;
begin
  Result := GetTickCount64;
end;

{ THDTick }
procedure THDTick.Initialize(out aResolution: UInt64; out aIsMonotonic: Boolean; out aTickType: TTickType);
begin
  aResolution  := GetHDResolution;
  aIsMonotonic := True;
  aTickType    := ttHighPrecision;
end;

function THDTick.Tick: UInt64;
begin
  if (not QueryPerformanceCounter(Result)) then
    Result := 0;
end;

end.
