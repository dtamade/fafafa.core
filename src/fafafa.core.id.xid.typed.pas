{
  fafafa.core.id.xid.record — Strong typed XID record API

  - Wraps TXid96 with typed methods for parse/format/compare
  - Delegates to fafafa.core.id.xid implementation to avoid duplication
  - Base32 (Crockford variant) encoding (20 chars)
  - Extract timestamp, machine ID, process ID, counter
}

unit fafafa.core.id.xid.typed;

{$MODE OBJFPC}{$H+}
{$I fafafa.core.settings.inc}
{$modeswitch advancedrecords}

interface

uses
  SysUtils,
  fafafa.core.id.base,
  fafafa.core.id.xid;

type
  TXID = record
  private
    F: TXid96;
  public
    // Construction
    class function FromBytes(const A: TXid96): TXID; static; inline;
    function ToBytes: TXid96; inline;

    // Parse & Format
    class function TryParse(const S: string; out R: TXID): Boolean; static;
    class function Parse(const S: string): TXID; static; // raises on error
    function ToString: string; inline;

    // Properties
    function Timestamp: TDateTime; inline;
    function UnixTime: Int64; inline;
    function MachineId: UInt32; inline;
    function ProcessId: Word; inline;
    function Counter: UInt32; inline;
    function IsNil: Boolean; inline;
    function Equals(const B: TXID): Boolean; inline;

    // Ordering (bytewise lex, suitable for DB ordering)
    function CompareTo(const B: TXID): Integer; inline;
    function LessThan(const B: TXID): Boolean; inline;

    // Operator overloads
    class operator = (const A, B: TXID): Boolean; inline;
    class operator <> (const A, B: TXID): Boolean; inline;
    class operator < (const A, B: TXID): Boolean; inline;
    class operator <= (const A, B: TXID): Boolean; inline;
    class operator > (const A, B: TXID): Boolean; inline;
    class operator >= (const A, B: TXID): Boolean; inline;

    // Generators
    class function New: TXID; static; inline;
    class function NewAt(const ATime: TDateTime): TXID; static; inline;
    class function NewAtUnix(const UnixSec: Int64): TXID; static; inline;

    // Constants
    class function NilValue: TXID; static; inline;
  end;

implementation

{ TXID }

class function TXID.FromBytes(const A: TXid96): TXID;
begin
  Result.F := A;
end;

function TXID.ToBytes: TXid96;
begin
  Result := F;
end;

class function TXID.TryParse(const S: string; out R: TXID): Boolean;
var A: TXid96;
begin
  Result := fafafa.core.id.xid.TryParseXid(S, A);
  if Result then R.F := A;
end;

class function TXID.Parse(const S: string): TXID;
begin
  Result.F := fafafa.core.id.xid.XidFromString(S);  // raises EInvalidXid on error
end;

function TXID.ToString: string;
begin
  Result := fafafa.core.id.xid.XidToString(F);
end;

function TXID.Timestamp: TDateTime;
begin
  Result := fafafa.core.id.xid.XidTimestamp(F);
end;

function TXID.UnixTime: Int64;
begin
  Result := fafafa.core.id.xid.XidUnixTime(F);
end;

function TXID.MachineId: UInt32;
begin
  Result := fafafa.core.id.xid.XidMachineId(F);
end;

function TXID.ProcessId: Word;
begin
  Result := fafafa.core.id.xid.XidProcessId(F);
end;

function TXID.Counter: UInt32;
begin
  Result := fafafa.core.id.xid.XidCounter(F);
end;

function TXID.IsNil: Boolean;
begin
  Result := fafafa.core.id.xid.XidIsNil(F);
end;

function TXID.Equals(const B: TXID): Boolean;
begin
  Result := fafafa.core.id.xid.XidEquals(F, B.F);
end;

function TXID.CompareTo(const B: TXID): Integer;
begin
  Result := fafafa.core.id.xid.XidCompare(F, B.F);
end;

function TXID.LessThan(const B: TXID): Boolean;
begin
  Result := CompareTo(B) < 0;
end;

class operator TXID.= (const A, B: TXID): Boolean;
begin
  Result := A.Equals(B);
end;

class operator TXID.<> (const A, B: TXID): Boolean;
begin
  Result := not A.Equals(B);
end;

class operator TXID.< (const A, B: TXID): Boolean;
begin
  Result := A.LessThan(B);
end;

class operator TXID.<= (const A, B: TXID): Boolean;
begin
  Result := A.CompareTo(B) <= 0;
end;

class operator TXID.> (const A, B: TXID): Boolean;
begin
  Result := A.CompareTo(B) > 0;
end;

class operator TXID.>= (const A, B: TXID): Boolean;
begin
  Result := A.CompareTo(B) >= 0;
end;

class function TXID.New: TXID;
begin
  Result.F := fafafa.core.id.xid.Xid;
end;

class function TXID.NewAt(const ATime: TDateTime): TXID;
begin
  Result.F := fafafa.core.id.xid.XidFromTime(ATime);
end;

class function TXID.NewAtUnix(const UnixSec: Int64): TXID;
begin
  Result.F := fafafa.core.id.xid.XidFromUnix(UnixSec);
end;

class function TXID.NilValue: TXID;
begin
  Result.F := fafafa.core.id.xid.XidNil;
end;

end.
