unit fafafa.core.test.clock.tick;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  fafafa.core.test.core,   // IClock
  fafafa.core.time.tick;   // ITick / CreateDefaultTick (new namespace)

// High-resolution clock adapter that wraps record-based TTick as IClock.
// NowUTC uses SysUtils.Now (same as TSystemClock); NowMonotonicMs uses TTick.

type
  TTickClock = class(TInterfacedObject, IClock)
  private
    FTick: TTick; // record-based clock
  public
    constructor Create; reintroduce;
    function NowUTC: TDateTime;
    function NowMonotonicMs: QWord;
  end;

// Convenience factory: create a high-resolution clock using BestTick
function CreateHighResClock: IClock;

implementation

constructor TTickClock.Create;
begin
  inherited Create;
  FTick := BestTick;
end;

function TTickClock.NowUTC: TDateTime;
begin
  Result := Now;
end;

function TTickClock.NowMonotonicMs: QWord;
var
  t0, dt: UInt64;
begin
  t0 := FTick.Now;
  dt := FTick.Elapsed(t0);
  Result := FTick.TicksToDuration(dt).AsMs;
end;

function CreateHighResClock: IClock;
begin
  Result := TTickClock.Create;
end;

end.

