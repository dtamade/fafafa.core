unit fafafa.core.test.clock.tick;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  fafafa.core.test.core,   // IClock
  fafafa.core.time.tick;   // ITick / CreateDefaultTick (new namespace)

// High-resolution clock adapter that wraps fafafa.core.tick as IClock.
// NowUTC uses SysUtils.Now (same as TSystemClock); NowMonotonicMs uses ITick.

type
  TTickClock = class(TInterfacedObject, IClock)
  private
    FTick: ITick;
  public
    constructor Create(const ATick: ITick);
    function NowUTC: TDateTime;
    function NowMonotonicMs: QWord;
  end;

// Convenience factory: create a high-resolution clock using default provider
function CreateHighResClock: IClock;

implementation

constructor TTickClock.Create(const ATick: ITick);
begin
  inherited Create;
  if ATick = nil then
    FTick := CreateDefaultTick
  else
    FTick := ATick;
end;

function TTickClock.NowUTC: TDateTime;
begin
  Result := Now;
end;

function TTickClock.NowMonotonicMs: QWord;
var
  t: UInt64;
begin
  t := FTick.GetCurrentTick;
  // convert to milliseconds using the tick's resolution
  Result := Round(FTick.TicksToMilliSeconds(t));
end;

function CreateHighResClock: IClock;
begin
  Result := TTickClock.Create(CreateDefaultTick);
end;

end.

