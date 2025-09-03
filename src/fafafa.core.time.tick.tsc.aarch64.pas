unit fafafa.core.time.tick.tsc.aarch64;

{
──────────────────────────────────────────────────────────────
📦 项目：fafafa.core.time.tick.tsc.aarch64 - ARM64 TSC 实现

📖 概述：
  ARM64 平台的 TSC (Time Stamp Counter) 硬件计时器实现。
  使用 CNTVCT_EL0 系统寄存器提供高精度时间测量。

🔧 特性：
  • CNTVCT_EL0 系统寄存器访问
  • CNTFRQ_EL0 频率寄存器读取
  • 稳定的单调时钟
  • 无需频率校准

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

{$IFDEF CPUAARCH64}

uses
  fafafa.core.time.tick.tsc.base;

type
  // ARM64 TSC 实现
  TAARCH64TSCTick = class(TTSCTickBase)
  protected
    // 实现平台特定方法
    function DoDetectTSCSupport: Boolean; override;
    function DoCalibrateTSCFrequency: UInt64; override;
    function DoReadTSC: UInt64; override;
  end;

// ARM64 平台检测函数
function IsAARCH64TSCAvailable: Boolean;
function GetAARCH64TSCFrequency: UInt64;

{$ENDIF} // CPUAARCH64

implementation

{$IFDEF CPUAARCH64}

uses
  SysUtils;

// ARM64 汇编函数

// 读取 CNTVCT_EL0 寄存器
function ReadCNTVCT_EL0: UInt64; assembler; nostackframe;
asm
  mrs x0, cntvct_el0
end;

// 读取 CNTFRQ_EL0 寄存器
function ReadCNTFRQ_EL0: UInt64; assembler; nostackframe;
asm
  mrs x0, cntfrq_el0
end;

// 全局缓存变量
var
  GAARCH64TSCAvailable: Boolean = False;
  GAARCH64TSCFrequency: UInt64 = 0;
  GAARCH64TSCInitialized: Boolean = False;

// 内部检测函数
function InternalDetectAARCH64TSCSupport: Boolean;
begin
  // ARM64 计数器总是稳定的
  Result := True;
end;

function InternalCalibrateAARCH64TSCFrequency: UInt64;
begin
  try
    Result := ReadCNTFRQ_EL0;
  except
    Result := 0;
  end;
end;

// 初始化 ARM64 TSC 信息（只执行一次）
procedure InitializeAARCH64TSCInfo;
begin
  if GAARCH64TSCInitialized then Exit;

  GAARCH64TSCAvailable := InternalDetectAARCH64TSCSupport;
  if GAARCH64TSCAvailable then
  begin
    GAARCH64TSCFrequency := InternalCalibrateAARCH64TSCFrequency;
    GAARCH64TSCAvailable := GAARCH64TSCFrequency > 0;
  end;

  GAARCH64TSCInitialized := True;
end;

{ TAARCH64TSCTick }

function TAARCH64TSCTick.DoDetectTSCSupport: Boolean;
begin
  InitializeAARCH64TSCInfo;
  Result := GAARCH64TSCAvailable;
end;

function TAARCH64TSCTick.DoCalibrateTSCFrequency: UInt64;
begin
  InitializeAARCH64TSCInfo;
  Result := GAARCH64TSCFrequency;
end;

function TAARCH64TSCTick.DoReadTSC: UInt64;
begin
  Result := ReadCNTVCT_EL0;
end;

// 公共接口函数
function IsAARCH64TSCAvailable: Boolean;
begin
  InitializeAARCH64TSCInfo;
  Result := GAARCH64TSCAvailable;
end;

function GetAARCH64TSCFrequency: UInt64;
begin
  InitializeAARCH64TSCInfo;
  Result := GAARCH64TSCFrequency;
end;

initialization
  // 全局变量初始化
  GAARCH64TSCAvailable := False;
  GAARCH64TSCFrequency := 0;
  GAARCH64TSCInitialized := False;

{$ENDIF} // CPUAARCH64

end.