{$CODEPAGE UTF8}
program example_id;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  SysUtils, DateUtils,
  fafafa.core.id, fafafa.core.id.ulid, fafafa.core.id.ulid.monotonic, fafafa.core.id.v7.monotonic, fafafa.core.id.ksuid, fafafa.core.id.snowflake, fafafa.core.id.codec;

procedure PrintLine(const S: string);
begin
  WriteLn(S);
end;

procedure PrintUUIDs;
var i: Integer; s: string;
begin
  PrintLine('UUID v7:');
  for i := 1 to 5 do begin s := UuidV7; PrintLine('  ' + s + '  ts=' + IntToStr(UuidV7_TimestampMs(s))); end;
  PrintLine('UUID v4:');
  for i := 1 to 5 do begin s := UuidV4; PrintLine('  ' + s); end;
end;

procedure PrintUuidV7Monotonic;
var G: IUuidV7Generator; s1, s2: string; sameMs: Boolean;
begin
  WriteLn('UUID v7 (monotonic, same-ms):');
  G := CreateUuidV7Monotonic;
  s1 := G.Next; s2 := G.Next;
  sameMs := UuidV7_TimestampMs(s1) = UuidV7_TimestampMs(s2);
  WriteLn('  ', s1);
  WriteLn('  ', s2, '  (lex>', BoolToStr(s2 > s1, True), ', sameMs=', BoolToStr(sameMs, True), ')');
end;

procedure PrintULIDs;
var i: Integer; s: string; G: IUlidGenerator; s2: string;
begin
  PrintLine('ULID:');
  for i := 1 to 5 do begin s := Ulid; PrintLine('  ' + s + '  ts=' + IntToStr(Ulid_TimestampMs(s))); end;
  PrintLine('ULID (monotonic same-ms):');
  G := CreateUlidMonotonic;
  s := G.Next; s2 := G.Next;
  PrintLine('  ' + s);
  PrintLine('  ' + s2 + '  (lex>' + BoolToStr(s2 > s, True) + ', sameMs=' + BoolToStr(Ulid_TimestampMs(s2)=Ulid_TimestampMs(s), True) + ')');
end;

procedure PrintKsuids;
var i: Integer; s: string;
begin
  PrintLine('KSUID:');
  for i := 1 to 5 do begin s := Ksuid; PrintLine('  ' + s + '  ts=' + IntToStr(Ksuid_TimestampUnixSeconds(s))); end;
end;

procedure PrintSnowflakes;
var i: Integer; g: ISnowflake; id: TSnowflakeID; ep: Int64; cfg: TSnowflakeConfig; g2: ISnowflake; id2: TSnowflakeID;
begin
  g := CreateSnowflake(1);
  ep := g.EpochMs;
  PrintLine('Snowflake:');
  for i := 1 to 5 do begin id := g.NextID; PrintLine('  ' + IntToStr(id) + '  ts=' + IntToStr(Snowflake_TimestampMs(id, ep)) + '  wid=' + IntToStr(Snowflake_WorkerId(id)) + '  seq=' + IntToStr(Snowflake_Sequence(id))); end;
  // Show CreateSnowflakeEx with sbThrow policy
  cfg.EpochMs := ep; cfg.WorkerId := 2; cfg.BackwardPolicy := sbThrow;
  g2 := CreateSnowflakeEx(cfg);
  id2 := g2.NextID;
  PrintLine('SnowflakeEx: ' + IntToStr(id2) + '  ts=' + IntToStr(Snowflake_TimestampMs(id2, cfg.EpochMs)) + '  wid=' + IntToStr(Snowflake_WorkerId(id2)) + '  seq=' + IntToStr(Snowflake_Sequence(id2)));
end;


procedure PrintEncodings;
var
  R: TUuid128; U: TUlid128; K: TKsuid160; s1,s2,s3: string;
begin
  WriteLn('Encodings:');
  R := UuidV4_Raw; U := Ulid_Raw(1730000000123); K := Ksuid_Raw(1730000000);
  s1 := UuidToBase64Url(R);
  s2 := UlidToBase58(U);
  s3 := KsuidToBase58(K);
  WriteLn('  UUID(Base64URL,22)  ', s1);
  WriteLn('  ULID(Base58)        ', s2);
  WriteLn('  KSUID(Base58)       ', s3);
end;

procedure PrintUuidBatch;
var arr: TUuid128Array; i: Integer; sFirst, sLast: string;
begin
  WriteLn('UUID v7 batch (small demo):');
  SetLength(arr, 10);
  UuidV7_FillRawN(arr);
  sFirst := UuidToString(arr[0]);
  sLast := UuidToString(arr[High(arr)]);
  for i := 0 to High(arr) do
    if i < 3 then WriteLn('  ', UuidToString(arr[i]));
  WriteLn('  ...');
  WriteLn('  ', sLast);
  WriteLn('  first<last=', BoolToStr(sFirst < sLast, True));
end;


begin
  PrintUUIDs;
  PrintULIDs;
  PrintUuidV7Monotonic;
  PrintKsuids;
  PrintSnowflakes;
  PrintUuidBatch;
  // Extra: encoding samples
  PrintEncodings;
end.

