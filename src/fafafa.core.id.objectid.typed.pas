{
  fafafa.core.id.objectid.record — Strong typed ObjectId record API

  - Wraps TObjectId with typed methods for parse/format/compare
  - Delegates to fafafa.core.id.objectid implementation to avoid duplication
  - 24-character hex string encoding
  - Extract timestamp from ID
}

unit fafafa.core.id.objectid.typed;

{$MODE OBJFPC}{$H+}
{$I fafafa.core.settings.inc}
{$modeswitch advancedrecords}

interface

uses
  SysUtils,
  fafafa.core.id.base,
  fafafa.core.id.objectid;

type
  TObjectID = record
  private
    F: TObjectId96;
  public
    // Construction
    class function FromBytes(const A: TObjectId96): TObjectID; static; inline;
    function ToBytes: TObjectId96; inline;

    // Parse & Format
    class function TryParse(const S: string; out R: TObjectID): Boolean; static;
    class function Parse(const S: string): TObjectID; static; // raises on error
    function ToString: string; inline;

    // Properties
    function Timestamp: TDateTime; inline;
    function UnixTimestamp: UInt32; inline;
    function IsNil: Boolean; inline;
    function Equals(const B: TObjectID): Boolean; inline;

    // Ordering (bytewise lex, suitable for DB ordering)
    function CompareTo(const B: TObjectID): Integer; inline;
    function LessThan(const B: TObjectID): Boolean; inline;

    // Operator overloads
    class operator = (const A, B: TObjectID): Boolean; inline;
    class operator <> (const A, B: TObjectID): Boolean; inline;
    class operator < (const A, B: TObjectID): Boolean; inline;
    class operator <= (const A, B: TObjectID): Boolean; inline;
    class operator > (const A, B: TObjectID): Boolean; inline;
    class operator >= (const A, B: TObjectID): Boolean; inline;

    // Generators
    class function New: TObjectID; static; inline;

    // Constants
    class function NilValue: TObjectID; static; inline;
  end;

implementation

{ TObjectID }

class function TObjectID.FromBytes(const A: TObjectId96): TObjectID;
begin
  Result.F := A;
end;

function TObjectID.ToBytes: TObjectId96;
begin
  Result := F;
end;

class function TObjectID.TryParse(const S: string; out R: TObjectID): Boolean;
var A: TObjectId96;
begin
  Result := fafafa.core.id.objectid.TryParseObjectId(S, A);
  if Result then R.F := A;
end;

class function TObjectID.Parse(const S: string): TObjectID;
begin
  Result.F := fafafa.core.id.objectid.ParseObjectId(S);  // raises EInvalidObjectId on error
end;

function TObjectID.ToString: string;
begin
  Result := fafafa.core.id.objectid.ObjectIdToString(F);
end;

function TObjectID.Timestamp: TDateTime;
begin
  Result := fafafa.core.id.objectid.ObjectIdTimestamp(F);
end;

function TObjectID.UnixTimestamp: UInt32;
begin
  Result := fafafa.core.id.objectid.ObjectIdUnixTimestamp(F);
end;

function TObjectID.IsNil: Boolean;
begin
  Result := fafafa.core.id.objectid.ObjectIdIsNil(F);
end;

function TObjectID.Equals(const B: TObjectID): Boolean;
begin
  Result := fafafa.core.id.objectid.ObjectIdEquals(F, B.F);
end;

function TObjectID.CompareTo(const B: TObjectID): Integer;
begin
  Result := fafafa.core.id.objectid.ObjectIdCompare(F, B.F);
end;

function TObjectID.LessThan(const B: TObjectID): Boolean;
begin
  Result := CompareTo(B) < 0;
end;

class operator TObjectID.= (const A, B: TObjectID): Boolean;
begin
  Result := A.Equals(B);
end;

class operator TObjectID.<> (const A, B: TObjectID): Boolean;
begin
  Result := not A.Equals(B);
end;

class operator TObjectID.< (const A, B: TObjectID): Boolean;
begin
  Result := A.LessThan(B);
end;

class operator TObjectID.<= (const A, B: TObjectID): Boolean;
begin
  Result := A.CompareTo(B) <= 0;
end;

class operator TObjectID.> (const A, B: TObjectID): Boolean;
begin
  Result := A.CompareTo(B) > 0;
end;

class operator TObjectID.>= (const A, B: TObjectID): Boolean;
begin
  Result := A.CompareTo(B) >= 0;
end;

class function TObjectID.New: TObjectID;
begin
  Result.F := fafafa.core.id.objectid.ObjectId;
end;

class function TObjectID.NilValue: TObjectID;
begin
  Result.F := fafafa.core.id.objectid.ObjectIdNil;
end;

end.
