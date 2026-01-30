{$CODEPAGE UTF8}
unit Test_fafafa_core_id_ulid_monotonic;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testutils, testregistry,
  fafafa.core.id.ulid, fafafa.core.id.ulid.monotonic;

type
  TTestCase_UlidMonotonic = class(TTestCase)
  published
    procedure Test_Next_SameMs_LexOrder;
    procedure Test_NextRaw_Compose; // raw structure sanity
  end;

implementation

procedure TTestCase_UlidMonotonic.Test_Next_SameMs_LexOrder;
var G: IUlidGenerator; a,b: string;
begin
  G := CreateUlidMonotonic;
  a := G.Next;
  b := G.Next;
  AssertTrue('lex order', a < b);
end;

procedure TTestCase_UlidMonotonic.Test_NextRaw_Compose;
var G: IUlidGenerator; R: TUlid128; S: string;
begin
  G := CreateUlidMonotonic;
  R := G.NextRaw;
  S := UlidToString(R);
  AssertEquals('len=26', 26, Length(S));
end;

initialization
  RegisterTest('fafafa.core.id.UlidMonotonic', TTestCase_UlidMonotonic);
end.

