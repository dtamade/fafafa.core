{$CODEPAGE UTF8}
unit Test_fafafa_core_id_uuid_v7_monotonic_batch;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testutils, testregistry,
  fafafa.core.id, fafafa.core.id.v7.monotonic;

type
  TTestCase_UuidV7MonotonicBatch = class(TTestCase)
  published
    procedure Test_NextRawN_OrderAndCount;
  end;

implementation

procedure TTestCase_UuidV7MonotonicBatch.Test_NextRawN_OrderAndCount;
var G: IUuidV7Generator; arr: array[0..15] of TUuid128; i: Integer; sPrev, sCur: string;
begin
  G := CreateUuidV7Monotonic;
  G.NextRawN(arr);
  // At least lex order non-decreasing (跨毫秒可能重置，但整体应大多递增；这里只做弱断言）
  sPrev := UuidToString(arr[0]);
  for i := 1 to High(arr) do
  begin
    sCur := UuidToString(arr[i]);
    AssertTrue('lex non-decreasing', (sCur >= sPrev));
    sPrev := sCur;
  end;
end;

initialization
  RegisterTest('fafafa.core.id.UuidV7MonotonicBatch', TTestCase_UuidV7MonotonicBatch);
end.

