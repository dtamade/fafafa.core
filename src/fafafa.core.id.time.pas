{
  fafafa.core.id.time — Unified time helpers for ID modules

  - Provides NowUnixMs / NowUnixSeconds using the framework clock
  - Centralizes time source for UUID v7 / ULID / KSUID / Snowflake
}

unit fafafa.core.id.time;

{$MODE OBJFPC}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, DateUtils, fafafa.core.time; // use DefaultSystemClock

function NowUnixMs: Int64; inline;
function NowUnixSeconds: Int64; inline;

implementation

function NowUnixMs: Int64; inline;
var
  D: TDateTime;
begin
  // Use local wall-clock via DefaultSystemClock, DateTimeToUnix handles TZ
  D := DefaultSystemClock.NowLocal;
  Result := Int64(DateTimeToUnix(D)) * 1000 + MilliSecondOf(D);
end;

function NowUnixSeconds: Int64; inline;
var
  D: TDateTime;
begin
  D := DefaultSystemClock.NowLocal;
  Result := DateTimeToUnix(D);
end;

end.

