unit fafafa.core.time.tick;

{
──────────────────────────────────────────────────────────────
📦 项目：fafafa.core.time.tick - Tick 模块门面

📖 概述：
  高精度时间测量模块的统一入口。
  重新导出基础定义和平台实现。

🔧 特性：
  • 跨平台时间测量
  • 自动选择最佳实现
  • 统一的对外接口
  • 与 TDuration/TInstant 集成

📜 声明：
  转发或用于个人/商业项目时，请保留本项目的版权声明。

👤 author  : fafafaStudio
📧 Email   : dtamade@gmail.com
💬 QQGroup : 685403987
💬 QQ      : 179033731
──────────────────────────────────────────────────────────────
}

{$MODE OBJFPC}{$H+}
{$modeswitch advancedrecords}

{$I fafafa.core.settings.inc}

interface

uses
  // 门面：重新导出基础定义和平台实现
  fafafa.core.time.tick.base
  {$IFDEF MSWINDOWS}
  , fafafa.core.time.tick.windows
  {$ELSE}
  , fafafa.core.time.tick.unix  // Unix 系统（Linux、macOS、FreeBSD 等）
  {$ENDIF}
  , fafafa.core.time.duration
  ;


type
  // 重新导出基础类型
  TTickType = fafafa.core.time.tick.base.TTickType;
  TTickTypeArray = fafafa.core.time.tick.base.TTickTypeArray;
  ITick = fafafa.core.time.tick.base.ITick;

  // 重新导出异常类型
  ETickError = fafafa.core.time.tick.base.ETickError;
  ETickNotAvailable = fafafa.core.time.tick.base.ETickNotAvailable;
  ETickInvalidArgument = fafafa.core.time.tick.base.ETickInvalidArgument;

// 重新导出工厂函数
function CreateTick(const AType: TTickType = ttBest): ITick;
function IsTickTypeAvailable(const AType: TTickType): Boolean;
function GetTickTypeName(const AType: TTickType): string;
function GetAvailableTickTypes: TTickTypeArray;

// 便捷的全局访问函数
function DefaultTick: ITick;
function HighPrecisionTick: ITick;
function SystemTick: ITick;

// 快速测量函数
type
  TProc = procedure;

function QuickMeasure(const AProc: TProc): TDuration;

implementation


// 重新导出工厂函数的实现
function CreateTick(const AType: TTickType): ITick;
begin
  {$IFDEF MSWINDOWS}
  Result := fafafa.core.time.tick.windows.CreateWindowsTick(AType);
  {$ELSE}
  Result := fafafa.core.time.tick.unix.CreateUnixTick(AType);
  {$ENDIF}
end;

function IsTickTypeAvailable(const AType: TTickType): Boolean;
begin
  {$IFDEF MSWINDOWS}
  Result := fafafa.core.time.tick.windows.IsWindowsTickTypeAvailable(AType);
  {$ELSE}
  Result := fafafa.core.time.tick.unix.IsUnixTickTypeAvailable(AType);
  {$ENDIF}
end;

function GetTickTypeName(const AType: TTickType): string;
begin
  Result := fafafa.core.time.tick.base.GetTickTypeName(AType);
end;

function GetAvailableTickTypes: TTickTypeArray;
var
  i: TTickType;
  list: array of TTickType;
  count: Integer;
begin
  SetLength(list, Ord(High(TTickType)) + 1);
  count := 0;

  for i := Low(TTickType) to High(TTickType) do
  begin
    if IsTickTypeAvailable(i) then
    begin
      list[count] := i;
      Inc(count);
    end;
  end;

  SetLength(list, count);
  Result := list;
end;

// 便捷的全局访问函数
function DefaultTick: ITick;
begin
  Result := CreateTick(ttBest);
end;

function HighPrecisionTick: ITick;
begin
  Result := CreateTick(ttHighPrecision);
end;

function SystemTick: ITick;
begin
  Result := CreateTick(ttSystem);
end;

// 快速测量函数
function QuickMeasure(const AProc: TTickProc): TDuration;
var
  tick: ITick;
  start: UInt64;
begin
  tick := DefaultTick;
  start := tick.GetCurrentTick;
  AProc();
  Result := tick.TicksToDuration(tick.GetElapsedTicks(start));
end;

end.