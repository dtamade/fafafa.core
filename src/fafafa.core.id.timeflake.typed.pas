{
  fafafa.core.id.timeflake.record — Strong typed Timeflake record API

  - Wraps TTimeflake with typed methods for parse/format/compare
  - Delegates to fafafa.core.id.timeflake implementation to avoid duplication
  - Base62 encoding (22 chars)
  - UUID format encoding (36 chars with dashes)
  - Extract timestamp from ID
}

unit fafafa.core.id.timeflake.typed;

{$MODE OBJFPC}{$H+}
{$I fafafa.core.settings.inc}
{$modeswitch advancedrecords}

interface

uses
  SysUtils,
  fafafa.core.id.base,
  fafafa.core.id.timeflake;

type
  TTimeflakeID = record
  private
    F: TTimeflake;
  public
    // Construction
    class function FromBytes(const A: TTimeflake): TTimeflakeID; static; inline;
    function ToBytes: TTimeflake; inline;

    // Parse & Format (Base62)
    class function TryParse(const S: string; out R: TTimeflakeID): Boolean; static;
    class function Parse(const S: string): TTimeflakeID; static; // raises on error
    function ToString: string; inline;

    // UUID format (36 chars with dashes)
    function ToUuidString: string; inline;
    class function TryFromUuidString(const S: string; out R: TTimeflakeID): Boolean; static;
    class function FromUuidString(const S: string): TTimeflakeID; static;

    // Properties
    function Timestamp: TDateTime; inline;
    function UnixMs: Int64; inline;
    function IsNil: Boolean; inline;
    function Equals(const B: TTimeflakeID): Boolean; inline;

    // Ordering (bytewise lex, suitable for DB ordering)
    function CompareTo(const B: TTimeflakeID): Integer; inline;
    function LessThan(const B: TTimeflakeID): Boolean; inline;

    // Operator overloads
    class operator = (const A, B: TTimeflakeID): Boolean; inline;
    class operator <> (const A, B: TTimeflakeID): Boolean; inline;
    class operator < (const A, B: TTimeflakeID): Boolean; inline;
    class operator <= (const A, B: TTimeflakeID): Boolean; inline;
    class operator > (const A, B: TTimeflakeID): Boolean; inline;
    class operator >= (const A, B: TTimeflakeID): Boolean; inline;

    // Generators
    class function New: TTimeflakeID; static; inline;
    class function NewMonotonic: TTimeflakeID; static; inline;

    // Constants
    class function NilValue: TTimeflakeID; static; inline;
  end;

implementation

{ TTimeflakeID }

class function TTimeflakeID.FromBytes(const A: TTimeflake): TTimeflakeID;
begin
  Result.F := A;
end;

function TTimeflakeID.ToBytes: TTimeflake;
begin
  Result := F;
end;

class function TTimeflakeID.TryParse(const S: string; out R: TTimeflakeID): Boolean;
var A: TTimeflake;
begin
  Result := fafafa.core.id.timeflake.TryParseTimeflake(S, A);
  if Result then R.F := A;
end;

class function TTimeflakeID.Parse(const S: string): TTimeflakeID;
begin
  Result.F := fafafa.core.id.timeflake.ParseTimeflake(S);  // raises EInvalidTimeflake on error
end;

function TTimeflakeID.ToString: string;
begin
  Result := fafafa.core.id.timeflake.TimeflakeToString(F);
end;

function TTimeflakeID.ToUuidString: string;
begin
  Result := fafafa.core.id.timeflake.TimeflakeToUuidString(F);
end;

class function TTimeflakeID.TryFromUuidString(const S: string; out R: TTimeflakeID): Boolean;
var A: TTimeflake;
begin
  // Validate format: 36 chars, correct dash positions
  if Length(S) <> 36 then Exit(False);
  if (S[9] <> '-') or (S[14] <> '-') or (S[19] <> '-') or (S[24] <> '-') then Exit(False);
  A := fafafa.core.id.timeflake.TimeflakeFromUuidString(S);
  // Check if it parsed correctly (not all zeros for non-zero input)
  if fafafa.core.id.timeflake.TimeflakeIsNil(A) then
  begin
    // Could be valid nil value - check if input was all zeros
    if S = '00000000-0000-0000-0000-000000000000' then
    begin
      R.F := A;
      Exit(True);
    end;
    Exit(False);
  end;
  R.F := A;
  Result := True;
end;

class function TTimeflakeID.FromUuidString(const S: string): TTimeflakeID;
begin
  if not TryFromUuidString(S, Result) then
    raise EInvalidTimeflake.CreateFmt('Invalid Timeflake UUID string: "%s"', [S]);
end;

function TTimeflakeID.Timestamp: TDateTime;
begin
  Result := fafafa.core.id.timeflake.TimeflakeTimestamp(F);
end;

function TTimeflakeID.UnixMs: Int64;
begin
  Result := fafafa.core.id.timeflake.TimeflakeUnixMs(F);
end;

function TTimeflakeID.IsNil: Boolean;
begin
  Result := fafafa.core.id.timeflake.TimeflakeIsNil(F);
end;

function TTimeflakeID.Equals(const B: TTimeflakeID): Boolean;
begin
  Result := fafafa.core.id.timeflake.TimeflakeEquals(F, B.F);
end;

function TTimeflakeID.CompareTo(const B: TTimeflakeID): Integer;
begin
  Result := fafafa.core.id.timeflake.TimeflakeCompare(F, B.F);
end;

function TTimeflakeID.LessThan(const B: TTimeflakeID): Boolean;
begin
  Result := CompareTo(B) < 0;
end;

class operator TTimeflakeID.= (const A, B: TTimeflakeID): Boolean;
begin
  Result := A.Equals(B);
end;

class operator TTimeflakeID.<> (const A, B: TTimeflakeID): Boolean;
begin
  Result := not A.Equals(B);
end;

class operator TTimeflakeID.< (const A, B: TTimeflakeID): Boolean;
begin
  Result := A.LessThan(B);
end;

class operator TTimeflakeID.<= (const A, B: TTimeflakeID): Boolean;
begin
  Result := A.CompareTo(B) <= 0;
end;

class operator TTimeflakeID.> (const A, B: TTimeflakeID): Boolean;
begin
  Result := A.CompareTo(B) > 0;
end;

class operator TTimeflakeID.>= (const A, B: TTimeflakeID): Boolean;
begin
  Result := A.CompareTo(B) >= 0;
end;

class function TTimeflakeID.New: TTimeflakeID;
begin
  Result.F := fafafa.core.id.timeflake.Timeflake;
end;

class function TTimeflakeID.NewMonotonic: TTimeflakeID;
begin
  Result.F := fafafa.core.id.timeflake.TimeflakeMonotonic;
end;

class function TTimeflakeID.NilValue: TTimeflakeID;
begin
  Result.F := fafafa.core.id.timeflake.TimeflakeNil;
end;

end.
