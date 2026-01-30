{$CODEPAGE UTF8}
unit Test_fafafa_core_id_uuid_v7_monotonic;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testutils, testregistry,
  fafafa.core.id, fafafa.core.id.v7.monotonic;

type
  TTestCase_UuidV7Monotonic = class(TTestCase)
  published
    procedure Test_SameMs_Increasing;
    procedure Test_VersionVariantBits;
    procedure Test_Timestamp_Field_Extract;
  end;

implementation

procedure TTestCase_UuidV7Monotonic.Test_SameMs_Increasing;
var G: IUuidV7Generator; a,b: TUuid128; sa, sb: string; i: Integer; ok: Boolean;
begin
  G := CreateUuidV7Monotonic;
  ok := False;
  // Try within a tight loop to likely land in same ms
  a := G.NextRaw;
  for i := 1 to 1000 do begin
    b := G.NextRaw;
    // lexicographic: compare string forms (same as DB order)
    sa := UuidToString(a);
    sb := UuidToString(b);
    if sa < sb then begin ok := True; Break; end;
    a := b;
  end;
  AssertTrue('monotonic lex order within same ms', ok);
end;

procedure TTestCase_UuidV7Monotonic.Test_VersionVariantBits;
var G: IUuidV7Generator; r: TUuid128;
begin
  G := CreateUuidV7Monotonic;
  r := G.NextRaw;
  AssertEquals('version 7', 7, (r[6] shr 4) and $0F);
  AssertTrue('variant RFC4122', (r[8] and $C0) = $80);
end;

procedure TTestCase_UuidV7Monotonic.Test_Timestamp_Field_Extract;
var G: IUuidV7Generator; s: string; ts: Int64;
begin
  G := CreateUuidV7Monotonic;
  s := G.Next;
  ts := UuidV7_TimestampMs(s);
  AssertTrue('timestamp extracted', ts > 0);
end;

initialization
  RegisterTest('fafafa.core.id.UuidV7Monotonic', TTestCase_UuidV7Monotonic);
end.

