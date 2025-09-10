unit fafafa.core.tick;

{$MODE OBJFPC}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  fafafa.core.time.tick,
  fafafa.core.time.duration;

type
  // 统一到记录式 API（TTick）
  TTickType = fafafa.core.time.tick.TTickType;
  TTickTypeArray = fafafa.core.time.tick.TTickTypeArray;
  TTick = fafafa.core.time.tick.TTick;
  TDuration = fafafa.core.time.duration.TDuration;
  TProc = fafafa.core.time.tick.TProc;

// 记录式 TTick 的便捷导出
function BestTick: TTick; inline;
function TickFrom(const AType: TTickType): TTick; inline;
function GetAvailableTickTypes: TTickTypeArray; inline;
function GetTickTypeName(const AType: TTickType): string; inline;
function IsTickTypeAvailable(const AType: TTickType): Boolean; inline;

function QuickMeasure(const AProc: TProc): TDuration; inline;
function QuickMeasureClock(const AProc: TProc; const Clock: TTick): TDuration; inline;

implementation

function BestTick: TTick; inline;
begin
  Result := fafafa.core.time.tick.BestTick;
end;

function TickFrom(const AType: TTickType): TTick; inline;
begin
  Result := fafafa.core.time.tick.TickFrom(AType);
end;

function GetAvailableTickTypes: TTickTypeArray; inline;
begin
  Result := fafafa.core.time.tick.GetAvailableTickTypes;
end;

function GetTickTypeName(const AType: TTickType): string; inline;
begin
  Result := fafafa.core.time.tick.GetTickTypeName(AType);
end;

function IsTickTypeAvailable(const AType: TTickType): Boolean; inline;
begin
  Result := fafafa.core.time.tick.IsTickTypeAvailable(AType);
end;

function QuickMeasure(const AProc: TProc): TDuration; inline;
begin
  Result := fafafa.core.time.tick.QuickMeasure(AProc);
end;

function QuickMeasureClock(const AProc: TProc; const Clock: TTick): TDuration; inline;
begin
  Result := fafafa.core.time.tick.QuickMeasureClock(AProc, Clock);
end;

end.
