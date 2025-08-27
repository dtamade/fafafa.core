unit test_oa_record_key_strict;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.lockfree, fafafa.core.lockfree.hashmap.openAddressing;

type
  TKey = record
    A: Integer;
    B: Integer;
  end;

  { TTestOARecordKeyStrict }
  TTestOARecordKeyStrict = class(TTestCase)
  published
    procedure Strict_RecordKey_HashEq_Works;
  end;

implementation

function HashKey(const K: TKey): Cardinal; inline;
begin
  // 简单：对整个记录按字节做 SimpleHash（无指针/托管字段）
  Result := fafafa.core.lockfree.SimpleHash(K, SizeOf(TKey));
  // 可选：掺合更多熵：Result := Result xor ((K.A * 16777619) + (K.B shl 1));
end;

function EqKey(const L, R: TKey): Boolean; inline;
begin
  Result := (L.A = R.A) and (L.B = R.B);
end;

type
  TRecIntOA = specialize TLockFreeHashMap<TKey, Integer>;

procedure TTestOARecordKeyStrict.Strict_RecordKey_HashEq_Works;
var
  Map: TRecIntOA;
  V: Integer;
  K: TKey;
begin
  Map := TRecIntOA.NewStrict(128, @HashKey, @EqKey);
  try
    K.A := 10; K.B := 20;
    AssertTrue(Map.Put(K, 123));

    K.B := 21; // 不相等
    AssertFalse(Map.Get(K, V));

    K.B := 20; // 相等
    AssertTrue(Map.Get(K, V));
    AssertEquals(123, V);
  finally
    Map := nil;
  end;
end;

initialization
  RegisterTest(TTestOARecordKeyStrict);
end.

