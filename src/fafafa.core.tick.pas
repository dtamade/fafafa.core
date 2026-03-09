unit fafafa.core.tick;

{$MODE OBJFPC}{$H+}
{$I fafafa.core.settings.inc}

{
  fafafa.core.tick - 简化的 Tick 门面单元

  本单元是 fafafa.core.time.tick 的简化门面，提供常用的计时器功能。
  对于完整功能，请直接使用 fafafa.core.time.tick。
}

interface

uses
  SysUtils,
  fafafa.core.time.tick,
  fafafa.core.time.tick.base,
  fafafa.core.time.duration;

type
  // 类型别名导出
  TTickType  = fafafa.core.time.tick.TTickType;
  TTickTypes = fafafa.core.time.tick.TTickTypes;
  ITick      = fafafa.core.time.tick.base.ITick;
  TTick      = fafafa.core.time.tick.TTick;
  TDuration  = fafafa.core.time.duration.TDuration;

const
  // 枚举值导出
  ttStandard      = fafafa.core.time.tick.base.ttStandard;
  ttHighPrecision = fafafa.core.time.tick.base.ttHighPrecision;
  ttHardware      = fafafa.core.time.tick.base.ttHardware;

// 便捷函数导出
function GetTickTypeName(const AType: TTickType): string; inline;
function GetAvailableTickTypes: TTickTypes; inline;
function HasHardwareTick: Boolean; inline;
function IsTickTypeAvailable(const AType: TTickType): Boolean; inline;

// 工厂函数
function MakeTick(AType: TTickType): ITick; inline;
function MakeTick: ITick; inline;
function MakeBestTick: ITick; inline;
function MakeStdTick: ITick; inline;
function MakeHDTick: ITick; inline;
function MakeHWTick: ITick; inline;

implementation

function GetTickTypeName(const AType: TTickType): string; inline;
begin
  Result := fafafa.core.time.tick.GetTickTypeName(AType);
end;

function GetAvailableTickTypes: TTickTypes; inline;
begin
  Result := fafafa.core.time.tick.GetAvailableTickTypes;
end;

function HasHardwareTick: Boolean; inline;
begin
  Result := fafafa.core.time.tick.HasHardwareTick;
end;

function IsTickTypeAvailable(const AType: TTickType): Boolean; inline;
begin
  Result := AType in fafafa.core.time.tick.GetAvailableTickTypes;
end;

function MakeTick(AType: TTickType): ITick; inline;
begin
  Result := fafafa.core.time.tick.MakeTick(AType);
end;

function MakeTick: ITick; inline;
begin
  Result := fafafa.core.time.tick.MakeTick;
end;

function MakeBestTick: ITick; inline;
begin
  Result := fafafa.core.time.tick.MakeBestTick;
end;

function MakeStdTick: ITick; inline;
begin
  Result := fafafa.core.time.tick.MakeStdTick;
end;

function MakeHDTick: ITick; inline;
begin
  Result := fafafa.core.time.tick.MakeHDTick;
end;

function MakeHWTick: ITick; inline;
begin
  Result := fafafa.core.time.tick.MakeHWTick;
end;

end.
