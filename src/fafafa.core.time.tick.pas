unit fafafa.core.time.tick;

{$MODE OBJFPC}{$H+}
{$modeswitch advancedrecords}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  fafafa.core.time.tick.base
  {$IFDEF WINDOWS}
  , fafafa.core.time.tick.windows
  {$ELSEIF DARWIN}
  , fafafa.core.time.tick.darwin
  {$ELSEIF UNIX}
  , fafafa.core.time.tick.unix
  {$ENDIF}
  , fafafa.core.time.tick.hardware
  ;

type
  TTickType  = fafafa.core.time.tick.base.TTickType;
  TTickTypes = fafafa.core.time.tick.base.TTickTypes;
  ITick      = fafafa.core.time.tick.base.ITick;
  TTick      = fafafa.core.time.tick.base.TTick;

function GetTickTypeName(const aType: TTickType): string; {$IFDEF FAFAFA_CORE_INLINING}inline;{$ENDIF}
function GetAvailableTickTypes: TTickTypes; {$IFDEF FAFAFA_CORE_INLINING}inline;{$ENDIF}

function HasHardwareTick: Boolean; {$IFDEF FAFAFA_CORE_INLINING}inline;{$ENDIF}

function MakeTick(aType: TTickType): ITick; {$IFDEF FAFAFA_CORE_INLINING}inline;{$ENDIF}
function MakeTick: ITick; {$IFDEF FAFAFA_CORE_INLINING}inline;{$ENDIF}
function MakeBestTick: ITick; {$IFDEF FAFAFA_CORE_INLINING}inline;{$ENDIF}
function MakeStdTick: ITick; {$IFDEF FAFAFA_CORE_INLINING}inline;{$ENDIF}
function MakeHDTick: ITick; {$IFDEF FAFAFA_CORE_INLINING}inline;{$ENDIF}
function MakeHWTick: ITick; {$IFDEF FAFAFA_CORE_INLINING}inline;{$ENDIF}

implementation

function GetTickTypeName(const aType: TTickType): string;
begin
  Result := fafafa.core.time.tick.GetTickTypeName(aType);
end;

function GetAvailableTickTypes: TTickTypes;
begin
  {$IFDEF WINDOWS}
  Result := [ttStandard, ttHighPrecision, ttHardware];
  {$ELSEIF DARWIN}
  Result := [ttStandard, ttHighPrecision, ttHardware];
  {$ELSEIF UNIX}
  Result := [ttStandard, ttHighPrecision, ttHardware];
  {$ENDIF}

  {$IF DEFINED(CPUX86_64) OR DEFINED(CPUI386) OR DEFINED(CPUAARCH64) OR (DEFINED(CPUARM) AND DEFINED(ARMV7A) AND DEFINED(USE_ARCH_TIMER))}
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
    ttStandard:      Result := MakeStandardTick();
    ttHighPrecision: Result := MakeHighPrecisionTick;
    ttHardware:      Result := MakeHardwareTick;
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
  {$ELSEIF DARWIN}
  Result := fafafa.core.time.tick.darwin.MakeTick();
  {$ELSEIF UNIX}
  Result := fafafa.core.time.tick.unix.MakeTick();
  {$ELSE}
    {$ERROR 'Unsupported platform for fafafa.core.time.tick.MakeStandardTick'}
  {$ENDIF}
end;

function MakeHDTick: ITick;
begin
  {$IFDEF WINDOWS}
  Result := fafafa.core.time.tick.windows.MakeQPCTick();
  {$ELSEIF DARWIN}
  Result := fafafa.core.time.tick.darwin.MakeTick();
  {$ELSEIF UNIX}
  Result := fafafa.core.time.tick.unix.MakeTick();
  {$ELSE}
    {$ERROR 'Unsupported platform for fafafa.core.time.tick.MakeHDTick'}
  {$ENDIF}
end;

function MakeHWTick: ITick;
begin
  Result := fafafa.core.time.tick.hardware.MakeTick();
end;

end.
