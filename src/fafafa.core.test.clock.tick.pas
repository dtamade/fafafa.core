unit fafafa.core.test.clock.tick;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  fafafa.core.test.core,   // IClock
  fafafa.core.time.tick;   // ITick / MakeBestTick

// High-resolution clock adapter that wraps ITick as IClock.
// NowUTC uses SysUtils.Now (same as TSystemClock); NowMonotonicMs uses ITick.

type
  TTickClock = class(TInterfacedObject, IClock)
  private
    FTick: ITick;
    class function TickToMs(const ATicks, AResolution: UInt64): QWord;
  public
    constructor Create(const ATick: ITick); reintroduce; overload;
    constructor Create; reintroduce; overload;
    function NowUTC: TDateTime;
    function NowMonotonicMs: QWord;
  end;

// Convenience factory: create a high-resolution clock using MakeBestTick
function CreateHighResClock: IClock;

implementation

class function TTickClock.TickToMs(const ATicks, AResolution: UInt64): QWord;
var
  secs, rem: UInt64;
begin
  if (AResolution = 0) then Exit(0);

  // Convert "ticks" (with Resolution ticks/second) to milliseconds without overflow.
  secs := ATicks div AResolution;
  rem  := ATicks mod AResolution;
  Result := QWord(secs) * 1000 + (QWord(rem) * 1000) div AResolution;
end;

constructor TTickClock.Create(const ATick: ITick);
begin
  inherited Create;

  if ATick <> nil then
    FTick := ATick
  else
    FTick := MakeBestTick;
end;

constructor TTickClock.Create;
begin
  Create(nil);
end;

function TTickClock.NowUTC: TDateTime;
begin
  Result := Now;
end;

function TTickClock.NowMonotonicMs: QWord;
var
  t: UInt64;
  res: UInt64;
begin
  if FTick = nil then Exit(0);
  t := FTick.Tick;
  res := FTick.Resolution;
  Result := TickToMs(t, res);
end;

function CreateHighResClock: IClock;
begin
  Result := TTickClock.Create(nil);
end;

end.

