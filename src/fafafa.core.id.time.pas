{
  fafafa.core.id.time — Unified time helpers for ID modules

  - Provides NowUnixMs / NowUnixSeconds using the framework clock
  - Centralizes time source for UUID v7 / ULID / KSUID / Snowflake
  - Uses UTC to avoid DST-related clock rollback issues
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
  // Use UTC to avoid DST-related clock rollback issues
  // DateTimeToUnix expects UTC input
  D := DefaultSystemClock.NowUtc;
  Result := Int64(DateTimeToUnix(D, False)) * 1000 + MilliSecondOf(D);
end;

function NowUnixSeconds: Int64; inline;
var
  D: TDateTime;
begin
  // Use UTC for consistent Unix epoch timestamps
  D := DefaultSystemClock.NowUtc;
  Result := DateTimeToUnix(D, False);
end;

end.

