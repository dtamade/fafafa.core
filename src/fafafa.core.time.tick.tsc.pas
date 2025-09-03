unit fafafa.core.time.tick.tsc;

{
──────────────────────────────────────────────────────────────
📦 项目：fafafa.core.time.tick.tsc - TSC 模块门面

📖 概述：
  TSC (Time Stamp Counter) 硬件计时器模块的统一入口。
  重新导出各平台实现的公共接口。

🔧 特性：
  • 跨平台 TSC 硬件计时器
  • 自动选择平台实现
  • 统一的对外接口
  • 模块化架构设计

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
  // 门面：重新导出基础定义和平台实现
  fafafa.core.time.tick.tsc.base
  {$IF DEFINED(CPUX86_64) OR DEFINED(CPUI386)}
  , fafafa.core.time.tick.tsc.x86
  {$ENDIF}
  {$IFDEF CPUAARCH64}
  , fafafa.core.time.tick.tsc.aarch64
  {$ENDIF}
  ;

type
  // 重新导出基础类型
  TTSCTickBase = fafafa.core.time.tick.tsc.base.TTSCTickBase;

  // 平台特定的 TSC 实现类型别名
  {$IF DEFINED(CPUX86_64) OR DEFINED(CPUI386)}
  TTSCTick = fafafa.core.time.tick.tsc.x86.TX86TSCTick;
  {$ELSE}
    {$IFDEF CPUAARCH64}
    TTSCTick = fafafa.core.time.tick.tsc.aarch64.TAARCH64TSCTick;
    {$ELSE}
    TTSCTick = TTSCTickBase; // 不支持的架构使用基类
    {$ENDIF}
  {$ENDIF}

// 重新导出检测函数
function IsTSCAvailable: Boolean; inline;
function GetTSCFrequency: UInt64; inline;

// 工厂函数
function CreateTSCTick: TTSCTick;

implementation

// 重新导出检测函数的实现
function IsTSCAvailable: Boolean;
begin
  {$IF DEFINED(CPUX86_64) OR DEFINED(CPUI386)}
  Result := fafafa.core.time.tick.tsc.x86.IsX86TSCAvailable;
  {$ELSE}
  {$IFDEF CPUAARCH64}
  Result := fafafa.core.time.tick.tsc.aarch64.IsAARCH64TSCAvailable;
  {$ELSE}
  Result := False; // 不支持的架构
  {$ENDIF}
  {$ENDIF}
end;

function GetTSCFrequency: UInt64;
begin
  {$IF DEFINED(CPUX86_64) OR DEFINED(CPUI386)}
  Result := fafafa.core.time.tick.tsc.x86.GetX86TSCFrequency;
  {$ELSE}
  {$IFDEF CPUAARCH64}
  Result := fafafa.core.time.tick.tsc.aarch64.GetAARCH64TSCFrequency;
  {$ELSE}
  Result := 0; // 不支持的架构
  {$ENDIF}
  {$ENDIF}
end;

// 工厂函数实现
function CreateTSCTick: TTSCTick;
begin
  {$IF DEFINED(CPUX86_64) OR DEFINED(CPUI386)}
  Result := fafafa.core.time.tick.tsc.x86.TX86TSCTick.Create;
  {$ELSE}
  {$IFDEF CPUAARCH64}
  Result := fafafa.core.time.tick.tsc.aarch64.TAARCH64TSCTick.Create;
  {$ELSE}
  raise ETickNotAvailable.Create('TSC is not supported on this architecture');
  {$ENDIF}
  {$ENDIF}
end;

end.