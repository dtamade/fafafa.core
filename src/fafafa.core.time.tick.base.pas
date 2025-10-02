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

{$mode objfpc}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  fafafa.core.time.consts;

const
  NANOSECONDS_PER_SECOND  = fafafa.core.time.consts.NANOSECONDS_PER_SECOND;
  MICROSECONDS_PER_SECOND = fafafa.core.time.consts.MICROSECONDS_PER_SECOND;
  MILLISECONDS_PER_SECOND = fafafa.core.time.consts.MILLISECONDS_PER_SECOND;

type

  ETickError        = class(Exception);
  ETickNotAvailable = class(ETickError);

  // Tick 类型（简化）
  TTickType = (
    ttStandard,      // 标准精度
    ttHighPrecision, // 高精度
    ttHardware       // 硬件计时器
  );

  TTickTypes = set of TTickType;

  ITick = interface
    ['{B8F5A2E1-4C3D-4F2A-9B1E-8D7C6A5F4E3D}']
    function GetResolution: UInt64;
    function GetIsMonotonic: Boolean;
    function GetTickType: TTickType;

    function Tick: UInt64;
    
    property Resolution:  UInt64    read GetResolution;
    property IsMonotonic: Boolean   read GetIsMonotonic;
    property TickType:    TTickType read GetTickType;
  end;

  { TTick }

  TTick = class(TInterfacedObject, ITick)
  private
    FResolution: UInt64;
    FIsMonotonic: Boolean;
    FTickType: TTickType;
  protected
    procedure Initialize(out aResolution: UInt64; out aIsMonotonic: Boolean; out aTickType: TTickType); virtual; abstract;
  public
    constructor Create; virtual;
    function GetResolution: UInt64; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}
    function GetIsMonotonic: Boolean; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}
    function GetTickType: TTickType; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}
    function Tick: UInt64; virtual; abstract;

    property Resolution:  UInt64    read GetResolution;
    property IsMonotonic: Boolean   read GetIsMonotonic;
    property TickType:    TTickType read GetTickType;
  end;


function GetTickTypeName(const aType: TTickType): string; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}

implementation

const
  TICK_TYPE_STANDARD_NAME      = 'Standard Precision Timer';
  TICK_TYPE_HIGHPRECISION_NAME = 'High Precision Timer';
  TICK_TYPE_HARDWARE_NAME      = 'Hardware Timer';

function GetTickTypeName(const aType: TTickType): string;
begin
  case aType of
    ttStandard:      Result := TICK_TYPE_STANDARD_NAME;
    ttHighPrecision: Result := TICK_TYPE_HIGHPRECISION_NAME;
    ttHardware:      Result := TICK_TYPE_HARDWARE_NAME;
  end;
end;

{ TTick }

constructor TTick.Create;
begin
  inherited Create;
  Initialize(FResolution, FIsMonotonic, FTickType);

  if (FResolution = 0) then
    raise ETickError.Create('Tick resolution is 0');
end;

function TTick.GetResolution: UInt64;
begin
  Result := FResolution;
end;

function TTick.GetIsMonotonic: Boolean;
begin
  Result := FIsMonotonic;
end;

function TTick.GetTickType: TTickType;
begin
  Result := FTickType;
end;

end.
