{
  Test_fafafa_core_id_record_wrappers - Record wrapper tests

  Tests for strong-typed record wrappers:
  - TXID (XID record wrapper)
  - TObjectID (ObjectId record wrapper)
  - TTimeflakeID (Timeflake record wrapper)
}

unit Test_fafafa_core_id_record_wrappers;

{$MODE OBJFPC}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  DateUtils,
  fpcunit,
  testregistry,
  fafafa.core.id.base,
  fafafa.core.id.xid,
  fafafa.core.id.xid.typed,
  fafafa.core.id.objectid,
  fafafa.core.id.objectid.typed,
  fafafa.core.id.timeflake,
  fafafa.core.id.timeflake.typed;

type
  { TTestTXID - TXID record wrapper tests }
  TTestTXID = class(TTestCase)
  published
    procedure Test_New_NotNil;
    procedure Test_ToString_20Chars;
    procedure Test_TryParse_Valid;
    procedure Test_TryParse_Invalid;
    procedure Test_Parse_Valid;
    procedure Test_Parse_Invalid_Raises;
    procedure Test_Roundtrip;
    procedure Test_Operators_Equal;
    procedure Test_Operators_NotEqual;
    procedure Test_Operators_LessThan;
    procedure Test_Operators_Comparison;
    procedure Test_Timestamp_Recent;
    procedure Test_Components_Extraction;
    procedure Test_NilValue;
    procedure Test_FromBytes_ToBytes;
  end;

  { TTestTObjectID - TObjectID record wrapper tests }
  TTestTObjectID = class(TTestCase)
  published
    procedure Test_New_NotNil;
    procedure Test_ToString_24Chars;
    procedure Test_TryParse_Valid;
    procedure Test_TryParse_Invalid;
    procedure Test_Parse_Valid;
    procedure Test_Parse_Invalid_Raises;
    procedure Test_Roundtrip;
    procedure Test_Operators_Equal;
    procedure Test_Operators_NotEqual;
    procedure Test_Operators_LessThan;
    procedure Test_Operators_Comparison;
    procedure Test_Timestamp_Recent;
    procedure Test_NilValue;
    procedure Test_FromBytes_ToBytes;
  end;

  { TTestTTimeflakeID - TTimeflakeID record wrapper tests }
  TTestTTimeflakeID = class(TTestCase)
  published
    procedure Test_New_NotNil;
    procedure Test_NewMonotonic_Ordered;
    procedure Test_ToString_22Chars;
    procedure Test_ToUuidString_36Chars;
    procedure Test_TryParse_Valid;
    procedure Test_TryParse_Invalid;
    procedure Test_Parse_Valid;
    procedure Test_Parse_Invalid_Raises;
    procedure Test_TryFromUuidString_Valid;
    procedure Test_TryFromUuidString_Invalid;
    procedure Test_FromUuidString_Valid;
    procedure Test_FromUuidString_Invalid_Raises;
    procedure Test_Roundtrip_Base62;
    procedure Test_Roundtrip_Uuid;
    procedure Test_Operators_Equal;
    procedure Test_Operators_NotEqual;
    procedure Test_Operators_LessThan;
    procedure Test_Operators_Comparison;
    procedure Test_Timestamp_Recent;
    procedure Test_NilValue;
    procedure Test_FromBytes_ToBytes;
  end;

implementation

{ TTestTXID }

procedure TTestTXID.Test_New_NotNil;
var
  Id: TXID;
begin
  Id := TXID.New;
  AssertFalse('New TXID should not be nil', Id.IsNil);
end;

procedure TTestTXID.Test_ToString_20Chars;
var
  Id: TXID;
  S: string;
begin
  Id := TXID.New;
  S := Id.ToString;
  AssertEquals('TXID string should be 20 chars', 20, Length(S));
end;

procedure TTestTXID.Test_TryParse_Valid;
var
  Id, Parsed: TXID;
  S: string;
begin
  Id := TXID.New;
  S := Id.ToString;
  AssertTrue('TryParse should succeed for valid string', TXID.TryParse(S, Parsed));
  AssertTrue('Parsed ID should equal original', Id = Parsed);
end;

procedure TTestTXID.Test_TryParse_Invalid;
var
  Parsed: TXID;
begin
  AssertFalse('TryParse should fail for empty string', TXID.TryParse('', Parsed));
  AssertFalse('TryParse should fail for short string', TXID.TryParse('abc', Parsed));
  AssertFalse('TryParse should fail for wrong length', TXID.TryParse('12345678901234567890123', Parsed));
end;

procedure TTestTXID.Test_Parse_Valid;
var
  Id, Parsed: TXID;
  S: string;
begin
  Id := TXID.New;
  S := Id.ToString;
  Parsed := TXID.Parse(S);
  AssertTrue('Parse should return equal ID', Id = Parsed);
end;

procedure TTestTXID.Test_Parse_Invalid_Raises;
var
  Raised: Boolean;
begin
  Raised := False;
  try
    TXID.Parse('invalid');
  except
    on E: EInvalidXid do
      Raised := True;
  end;
  AssertTrue('Parse should raise EInvalidXid for invalid string', Raised);
end;

procedure TTestTXID.Test_Roundtrip;
var
  Id1, Id2: TXID;
  S: string;
begin
  Id1 := TXID.New;
  S := Id1.ToString;
  Id2 := TXID.Parse(S);
  AssertTrue('Roundtrip should preserve ID', Id1 = Id2);
end;

procedure TTestTXID.Test_Operators_Equal;
var
  Id: TXID;
  Raw: TXid96;
begin
  Id := TXID.New;
  Raw := Id.ToBytes;
  AssertTrue('Same ID should be equal', Id = TXID.FromBytes(Raw));
end;

procedure TTestTXID.Test_Operators_NotEqual;
var
  Id1, Id2: TXID;
begin
  Id1 := TXID.New;
  Id2 := TXID.New;
  AssertTrue('Different IDs should not be equal', Id1 <> Id2);
end;

procedure TTestTXID.Test_Operators_LessThan;
var
  Id1, Id2: TXID;
begin
  Id1 := TXID.New;
  Sleep(10);
  Id2 := TXID.New;
  AssertTrue('Earlier ID should be less than later ID', Id1 < Id2);
  AssertFalse('Later ID should not be less than earlier ID', Id2 < Id1);
end;

procedure TTestTXID.Test_Operators_Comparison;
var
  Id1, Id2: TXID;
begin
  Id1 := TXID.New;
  Sleep(10);
  Id2 := TXID.New;

  AssertTrue('Id1 <= Id2', Id1 <= Id2);
  AssertTrue('Id2 > Id1', Id2 > Id1);
  AssertTrue('Id2 >= Id1', Id2 >= Id1);
  AssertTrue('Id1 <= Id1', Id1 <= Id1);
  AssertTrue('Id1 >= Id1', Id1 >= Id1);
end;

procedure TTestTXID.Test_Timestamp_Recent;
var
  Id: TXID;
  IdUnix, NowUnix: Int64;
begin
  Id := TXID.New;
  IdUnix := Id.UnixTime;
  NowUnix := DateTimeToUnix(LocalTimeToUniversal(Now), False);
  AssertTrue('Timestamp should be within 2 seconds of now', Abs(IdUnix - NowUnix) <= 2);
end;

procedure TTestTXID.Test_Components_Extraction;
var
  Id: TXID;
begin
  Id := TXID.New;
  AssertTrue('MachineId should be non-zero (usually)', Id.MachineId > 0);
  // ProcessId can be any value including 0
  // Counter can be any value
end;

procedure TTestTXID.Test_NilValue;
var
  Id: TXID;
begin
  Id := TXID.NilValue;
  AssertTrue('NilValue should be nil', Id.IsNil);
  AssertEquals('Nil string', '00000000000000000000', Id.ToString);
end;

procedure TTestTXID.Test_FromBytes_ToBytes;
var
  Id1, Id2: TXID;
  Raw: TXid96;
begin
  Id1 := TXID.New;
  Raw := Id1.ToBytes;
  Id2 := TXID.FromBytes(Raw);
  AssertTrue('FromBytes/ToBytes roundtrip', Id1 = Id2);
end;

{ TTestTObjectID }

procedure TTestTObjectID.Test_New_NotNil;
var
  Id: TObjectID;
begin
  Id := TObjectID.New;
  AssertFalse('New TObjectID should not be nil', Id.IsNil);
end;

procedure TTestTObjectID.Test_ToString_24Chars;
var
  Id: TObjectID;
  S: string;
begin
  Id := TObjectID.New;
  S := Id.ToString;
  AssertEquals('TObjectID string should be 24 chars', 24, Length(S));
end;

procedure TTestTObjectID.Test_TryParse_Valid;
var
  Id, Parsed: TObjectID;
  S: string;
begin
  Id := TObjectID.New;
  S := Id.ToString;
  AssertTrue('TryParse should succeed for valid string', TObjectID.TryParse(S, Parsed));
  AssertTrue('Parsed ID should equal original', Id = Parsed);
end;

procedure TTestTObjectID.Test_TryParse_Invalid;
var
  Parsed: TObjectID;
begin
  AssertFalse('TryParse should fail for empty string', TObjectID.TryParse('', Parsed));
  AssertFalse('TryParse should fail for short string', TObjectID.TryParse('abc', Parsed));
  AssertFalse('TryParse should fail for non-hex', TObjectID.TryParse('zzzzzzzzzzzzzzzzzzzzzzzz', Parsed));
end;

procedure TTestTObjectID.Test_Parse_Valid;
var
  Id, Parsed: TObjectID;
  S: string;
begin
  Id := TObjectID.New;
  S := Id.ToString;
  Parsed := TObjectID.Parse(S);
  AssertTrue('Parse should return equal ID', Id = Parsed);
end;

procedure TTestTObjectID.Test_Parse_Invalid_Raises;
var
  Raised: Boolean;
begin
  Raised := False;
  try
    TObjectID.Parse('invalid');
  except
    on E: EInvalidObjectId do
      Raised := True;
  end;
  AssertTrue('Parse should raise EInvalidObjectId for invalid string', Raised);
end;

procedure TTestTObjectID.Test_Roundtrip;
var
  Id1, Id2: TObjectID;
  S: string;
begin
  Id1 := TObjectID.New;
  S := Id1.ToString;
  Id2 := TObjectID.Parse(S);
  AssertTrue('Roundtrip should preserve ID', Id1 = Id2);
end;

procedure TTestTObjectID.Test_Operators_Equal;
var
  Id: TObjectID;
  Raw: TObjectId96;
begin
  Id := TObjectID.New;
  Raw := Id.ToBytes;
  AssertTrue('Same ID should be equal', Id = TObjectID.FromBytes(Raw));
end;

procedure TTestTObjectID.Test_Operators_NotEqual;
var
  Id1, Id2: TObjectID;
begin
  Id1 := TObjectID.New;
  Id2 := TObjectID.New;
  AssertTrue('Different IDs should not be equal', Id1 <> Id2);
end;

procedure TTestTObjectID.Test_Operators_LessThan;
var
  Id1, Id2: TObjectID;
begin
  Id1 := TObjectID.New;
  Sleep(10);
  Id2 := TObjectID.New;
  AssertTrue('Earlier ID should be less than later ID', Id1 < Id2);
  AssertFalse('Later ID should not be less than earlier ID', Id2 < Id1);
end;

procedure TTestTObjectID.Test_Operators_Comparison;
var
  Id1, Id2: TObjectID;
begin
  Id1 := TObjectID.New;
  Sleep(10);
  Id2 := TObjectID.New;

  AssertTrue('Id1 <= Id2', Id1 <= Id2);
  AssertTrue('Id2 > Id1', Id2 > Id1);
  AssertTrue('Id2 >= Id1', Id2 >= Id1);
  AssertTrue('Id1 <= Id1', Id1 <= Id1);
  AssertTrue('Id1 >= Id1', Id1 >= Id1);
end;

procedure TTestTObjectID.Test_Timestamp_Recent;
var
  Id: TObjectID;
  IdUnix, NowUnix: Int64;
begin
  Id := TObjectID.New;
  IdUnix := Id.UnixTimestamp;
  NowUnix := DateTimeToUnix(LocalTimeToUniversal(Now), False);
  AssertTrue('Timestamp should be within 2 seconds of now', Abs(IdUnix - NowUnix) <= 2);
end;

procedure TTestTObjectID.Test_NilValue;
var
  Id: TObjectID;
begin
  Id := TObjectID.NilValue;
  AssertTrue('NilValue should be nil', Id.IsNil);
  AssertEquals('Nil string', '000000000000000000000000', Id.ToString);
end;

procedure TTestTObjectID.Test_FromBytes_ToBytes;
var
  Id1, Id2: TObjectID;
  Raw: TObjectId96;
begin
  Id1 := TObjectID.New;
  Raw := Id1.ToBytes;
  Id2 := TObjectID.FromBytes(Raw);
  AssertTrue('FromBytes/ToBytes roundtrip', Id1 = Id2);
end;

{ TTestTTimeflakeID }

procedure TTestTTimeflakeID.Test_New_NotNil;
var
  Id: TTimeflakeID;
begin
  Id := TTimeflakeID.New;
  AssertFalse('New TTimeflakeID should not be nil', Id.IsNil);
end;

procedure TTestTTimeflakeID.Test_NewMonotonic_Ordered;
var
  Ids: array[0..9] of TTimeflakeID;
  I: Integer;
begin
  for I := 0 to 9 do
    Ids[I] := TTimeflakeID.NewMonotonic;

  for I := 0 to 8 do
    AssertTrue('Monotonic IDs should be ordered', Ids[I] < Ids[I + 1]);
end;

procedure TTestTTimeflakeID.Test_ToString_22Chars;
var
  Id: TTimeflakeID;
  S: string;
begin
  Id := TTimeflakeID.New;
  S := Id.ToString;
  AssertEquals('TTimeflakeID string should be 22 chars', 22, Length(S));
end;

procedure TTestTTimeflakeID.Test_ToUuidString_36Chars;
var
  Id: TTimeflakeID;
  S: string;
begin
  Id := TTimeflakeID.New;
  S := Id.ToUuidString;
  AssertEquals('UUID string should be 36 chars', 36, Length(S));
  AssertEquals('Dash at position 9', '-', S[9]);
  AssertEquals('Dash at position 14', '-', S[14]);
  AssertEquals('Dash at position 19', '-', S[19]);
  AssertEquals('Dash at position 24', '-', S[24]);
end;

procedure TTestTTimeflakeID.Test_TryParse_Valid;
var
  Id, Parsed: TTimeflakeID;
  S: string;
begin
  Id := TTimeflakeID.New;
  S := Id.ToString;
  AssertTrue('TryParse should succeed for valid string', TTimeflakeID.TryParse(S, Parsed));
  AssertTrue('Parsed ID should equal original', Id = Parsed);
end;

procedure TTestTTimeflakeID.Test_TryParse_Invalid;
var
  Parsed: TTimeflakeID;
begin
  AssertFalse('TryParse should fail for empty string', TTimeflakeID.TryParse('', Parsed));
  AssertFalse('TryParse should fail for short string', TTimeflakeID.TryParse('abc', Parsed));
end;

procedure TTestTTimeflakeID.Test_Parse_Valid;
var
  Id, Parsed: TTimeflakeID;
  S: string;
begin
  Id := TTimeflakeID.New;
  S := Id.ToString;
  Parsed := TTimeflakeID.Parse(S);
  AssertTrue('Parse should return equal ID', Id = Parsed);
end;

procedure TTestTTimeflakeID.Test_Parse_Invalid_Raises;
var
  Raised: Boolean;
begin
  Raised := False;
  try
    TTimeflakeID.Parse('invalid');
  except
    on E: EInvalidTimeflake do
      Raised := True;
  end;
  AssertTrue('Parse should raise EInvalidTimeflake for invalid string', Raised);
end;

procedure TTestTTimeflakeID.Test_TryFromUuidString_Valid;
var
  Id, Parsed: TTimeflakeID;
  S: string;
begin
  Id := TTimeflakeID.New;
  S := Id.ToUuidString;
  AssertTrue('TryFromUuidString should succeed', TTimeflakeID.TryFromUuidString(S, Parsed));
  AssertTrue('Parsed ID should equal original', Id = Parsed);
end;

procedure TTestTTimeflakeID.Test_TryFromUuidString_Invalid;
var
  Parsed: TTimeflakeID;
begin
  AssertFalse('TryFromUuidString should fail for wrong length',
    TTimeflakeID.TryFromUuidString('12345678-1234-1234-1234-12345678901', Parsed));
  AssertFalse('TryFromUuidString should fail for missing dashes',
    TTimeflakeID.TryFromUuidString('12345678123412341234123456789012', Parsed));
end;

procedure TTestTTimeflakeID.Test_FromUuidString_Valid;
var
  Id, Parsed: TTimeflakeID;
  S: string;
begin
  Id := TTimeflakeID.New;
  S := Id.ToUuidString;
  Parsed := TTimeflakeID.FromUuidString(S);
  AssertTrue('FromUuidString should return equal ID', Id = Parsed);
end;

procedure TTestTTimeflakeID.Test_FromUuidString_Invalid_Raises;
var
  Raised: Boolean;
begin
  Raised := False;
  try
    TTimeflakeID.FromUuidString('invalid-uuid');
  except
    on E: EInvalidTimeflake do
      Raised := True;
  end;
  AssertTrue('FromUuidString should raise EInvalidTimeflake for invalid string', Raised);
end;

procedure TTestTTimeflakeID.Test_Roundtrip_Base62;
var
  Id1, Id2: TTimeflakeID;
  S: string;
begin
  Id1 := TTimeflakeID.New;
  S := Id1.ToString;
  Id2 := TTimeflakeID.Parse(S);
  AssertTrue('Base62 roundtrip should preserve ID', Id1 = Id2);
end;

procedure TTestTTimeflakeID.Test_Roundtrip_Uuid;
var
  Id1, Id2: TTimeflakeID;
  S: string;
begin
  Id1 := TTimeflakeID.New;
  S := Id1.ToUuidString;
  Id2 := TTimeflakeID.FromUuidString(S);
  AssertTrue('UUID roundtrip should preserve ID', Id1 = Id2);
end;

procedure TTestTTimeflakeID.Test_Operators_Equal;
var
  Id: TTimeflakeID;
  Raw: TTimeflake;
begin
  Id := TTimeflakeID.New;
  Raw := Id.ToBytes;
  AssertTrue('Same ID should be equal', Id = TTimeflakeID.FromBytes(Raw));
end;

procedure TTestTTimeflakeID.Test_Operators_NotEqual;
var
  Id1, Id2: TTimeflakeID;
begin
  Id1 := TTimeflakeID.New;
  Id2 := TTimeflakeID.New;
  AssertTrue('Different IDs should not be equal', Id1 <> Id2);
end;

procedure TTestTTimeflakeID.Test_Operators_LessThan;
var
  Id1, Id2: TTimeflakeID;
begin
  Id1 := TTimeflakeID.NewMonotonic;
  Id2 := TTimeflakeID.NewMonotonic;
  AssertTrue('Earlier ID should be less than later ID', Id1 < Id2);
  AssertFalse('Later ID should not be less than earlier ID', Id2 < Id1);
end;

procedure TTestTTimeflakeID.Test_Operators_Comparison;
var
  Id1, Id2: TTimeflakeID;
begin
  Id1 := TTimeflakeID.NewMonotonic;
  Id2 := TTimeflakeID.NewMonotonic;

  AssertTrue('Id1 <= Id2', Id1 <= Id2);
  AssertTrue('Id2 > Id1', Id2 > Id1);
  AssertTrue('Id2 >= Id1', Id2 >= Id1);
  AssertTrue('Id1 <= Id1', Id1 <= Id1);
  AssertTrue('Id1 >= Id1', Id1 >= Id1);
end;

procedure TTestTTimeflakeID.Test_Timestamp_Recent;
var
  Id: TTimeflakeID;
  IdMs, NowMs: Int64;
begin
  Id := TTimeflakeID.New;
  IdMs := Id.UnixMs;
  NowMs := DateTimeToUnix(LocalTimeToUniversal(Now), False) * 1000 +
           MilliSecondOf(Now);
  AssertTrue('Timestamp should be within 200ms of now', Abs(IdMs - NowMs) <= 200);
end;

procedure TTestTTimeflakeID.Test_NilValue;
var
  Id: TTimeflakeID;
begin
  Id := TTimeflakeID.NilValue;
  AssertTrue('NilValue should be nil', Id.IsNil);
end;

procedure TTestTTimeflakeID.Test_FromBytes_ToBytes;
var
  Id1, Id2: TTimeflakeID;
  Raw: TTimeflake;
begin
  Id1 := TTimeflakeID.New;
  Raw := Id1.ToBytes;
  Id2 := TTimeflakeID.FromBytes(Raw);
  AssertTrue('FromBytes/ToBytes roundtrip', Id1 = Id2);
end;

initialization
  RegisterTest(TTestTXID);
  RegisterTest(TTestTObjectID);
  RegisterTest(TTestTTimeflakeID);

end.
